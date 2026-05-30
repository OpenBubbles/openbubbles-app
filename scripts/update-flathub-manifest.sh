#!/usr/bin/env bash
# Patch a Flathub app.openbubbles.OpenBubbles.yml tarball source after building
# bluebubbles-linux-x86_64.tar (see linux/build.sh or .github/workflows/linux-flatpak-release.yml).
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <flathub-yml> <bluebubbles-linux-x86_64.tar> [release-url]" >&2
  exit 1
fi

YML="$1"
TAR="$2"
URL="${3:-https://github.com/aasper03/openbubbles-app/releases/download/v1.15.0%2B227/bluebubbles-linux-x86_64.tar}"
SHA256="$(sha256sum "$TAR" | awk '{print $1}')"

python3 - "$YML" "$URL" "$SHA256" <<'PY'
import re, sys
path, url, sha = sys.argv[1:4]
text = open(path, encoding="utf-8").read()
text = re.sub(
    r"(url: )https://github.com/[^/]+/openbubbles-app/releases/download/[^\n]+\n(\s+sha256: )[0-9a-f]+",
    rf"\1{url}\n\2{sha}",
    text,
    count=1,
)
open(path, "w", encoding="utf-8").write(text)
print(f"updated {path}")
print(f"  url: {url}")
print(f"  sha256: {sha}")
PY
