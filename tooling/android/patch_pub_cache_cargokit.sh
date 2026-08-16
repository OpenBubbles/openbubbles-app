#!/usr/bin/env bash
#
# Teach the CargoKit copies vendored inside pub packages how to work with
# Flutter 3.44.8's Gradle plugin.
#
# irondash_engine_context and super_native_extensions ship their own CargoKit.
# Those copies live in the pub cache, are refetched by `flutter pub get`, and
# cannot be fixed by a committed edit, so they are patched before Android
# builds.
#
# CargoKit first needs to recognise Flutter's Kotlin Gradle plugin. That alone
# is not sufficient: the Kotlin rewrite made the plugin project private and
# moved getTargetPlatforms() to FlutterPluginUtils. This patch resolves the
# Flutter Project directly and reads -Ptarget-platform instead.
#
# Idempotent. Safe to run repeatedly and on already-patched files.
set -euo pipefail

patched=0
skipped=0
scanned=0

patch_file() {
    local file="$1"
    scanned=$((scanned + 1))

    if grep -q "_findFlutterProject" "$file"; then
        skipped=$((skipped + 1))
        return 0
    fi

    if ! grep -q "_findFlutterPlugin" "$file"; then
        echo "  ?? $file does not look like CargoKit's plugin.gradle; leaving it alone" >&2
        return 0
    fi

    # Rename the search so it yields the Project rather than the Plugin. The
    # recursive call is rewritten as its own block first so the remaining bare
    # `return plugin;` is unambiguously the one inside the plugin loop.
    perl -0777 -pi -e '
        s/private Plugin findFlutterPlugin\(/private Project findFlutterProject\(/;
        s/private Plugin _findFlutterPlugin\(/private Project _findFlutterProject\(/;
        s/_findFlutterPlugin\(rootProject\.childProjects\)/_findFlutterProject(rootProject.childProjects)/;
        s/def plugin = _findFlutterPlugin\(project\.value\.childProjects\);\s*\n(\s*)if \(plugin != null\) \{\s*\n\s*return plugin;\s*\n\s*\}/def found = _findFlutterProject(project.value.childProjects);\n$1if (found != null) {\n$1    return found;\n$1}/;
        s/if \(plugin\.class\.name == "FlutterPlugin"\) \{\s*\n(\s*)return plugin;/if (plugin.class.name == "FlutterPlugin" ||\n$1        plugin.class.name.endsWith(".FlutterPlugin")) {\n$1    return project.value;/;
        s/return plugin;/return project.value;/;
        s/def plugin = findFlutterPlugin\(project\.rootProject\);/def flutterProject = findFlutterProject(project.rootProject);/;
        s/if \(plugin == null\) \{/if (flutterProject == null) {/;
        s/\bprint\("Flutter plugin not found/println("Flutter plugin not found/;
        s/plugin\.getTargetPlatforms\(\)/flutterTargetPlatforms(flutterProject)/g;
        s/\bplugin\.project\b/flutterProject/g;
    ' "$file"

    # getTargetPlatforms moved into FlutterPluginUtils, which is Kotlin-internal
    # and unreachable from Groovy. Flutter passes -Ptarget-platform; the
    # fallback list matches the Flutter plugin's own default.
    perl -0777 -pi -e '
        s/(\n    \@Override\n    void apply\(Project project\) \{)/\n    private static List<String> flutterTargetPlatforms(Project flutterProject) {\n        if (flutterProject.hasProperty("target-platform")) {\n            return flutterProject\n                    .property("target-platform")\n                    .toString()\n                    .split(",")\n                    .collect { it.trim() }\n                    .findAll { !it.isEmpty() }\n        }\n        return ["android-arm", "android-arm64", "android-x64"]\n    }\n$1/;
    ' "$file"

    if ! grep -q "flutterTargetPlatforms" "$file"; then
        echo "  !! $file: helper was not inserted; the file shape is unexpected" >&2
        return 1
    fi

    echo "  patched $file"
    patched=$((patched + 1))
}

roots=()
if [ "$#" -gt 0 ]; then
    roots=("$@")
else
    # Default pub cache locations, Windows first since that is the dev host.
    for candidate in \
        "${PUB_CACHE:-}" \
        "$HOME/AppData/Local/Pub/Cache" \
        "$HOME/.pub-cache"
    do
        [ -n "$candidate" ] && [ -d "$candidate" ] && roots+=("$candidate")
    done
fi

if [ "${#roots[@]}" -eq 0 ]; then
    echo "no pub cache found; nothing to patch" >&2
    exit 0
fi

for root in "${roots[@]}"; do
    while IFS= read -r file; do
        patch_file "$file"
    done < <(find "$root" -path "*cargokit/gradle/plugin.gradle" -type f 2>/dev/null)
done

echo "cargokit pub-cache patch: ${patched} patched, ${skipped} already current, ${scanned} scanned"

if [ "$scanned" -eq 0 ]; then
    echo "warning: no vendored CargoKit copies were found." >&2
    echo "If irondash_engine_context or super_native_extensions are still" >&2
    echo "dependencies, the Android build will produce an APK that hangs on" >&2
    echo "startup. Check that pub get has run." >&2
fi
