[CmdletBinding()]
param(
    [ValidateSet('profile', 'debug')]
    [string]$Mode = 'profile',
    [string]$FlutterCommand = 'flutter',
    [string]$AndroidSdkRoot = $env:ANDROID_SDK_ROOT,
    [string]$CargoHome = $env:CARGO_HOME,
    [string]$RustupHome = $env:RUSTUP_HOME,
    [string]$ProtocPath = $env:PROTOC,
    [string]$PerlExecutable,
    [string]$PerlModuleRoot,
    [string]$MakeExecutable
)

$ErrorActionPreference = 'Stop'

function Resolve-Tool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [Parameter(Mandatory = $true)]
        [string]$DisplayName
    )

    if (Test-Path -LiteralPath $Value -PathType Leaf) {
        return (Resolve-Path -LiteralPath $Value).Path
    }

    $command = Get-Command $Value -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw "$DisplayName was not found: $Value"
    }

    return $command.Source
}

function Add-ToolDirectoryToPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable
    )

    $directory = Split-Path -Parent $Executable
    if (($env:Path -split ';') -notcontains $directory) {
        $env:Path = "$directory;$env:Path"
    }
}

function Convert-ToPosixUncPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WindowsPath
    )

    $resolved = (Resolve-Path -LiteralPath $WindowsPath).Path
    if ($resolved -match '^([A-Za-z]):\\(.*)$') {
        $drive = $Matches[1].ToUpperInvariant()
        $remainder = $Matches[2].Replace('\', '/')
        return "//localhost/$drive`$/$remainder"
    }

    return $resolved.Replace('\', '/')
}

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$flutter = Resolve-Tool -Value $FlutterCommand -DisplayName 'Flutter'
$apk = Join-Path $repositoryRoot "build\app\outputs\flutter-apk\app-alpha-$Mode.apk"

if ([string]::IsNullOrWhiteSpace($AndroidSdkRoot)) {
    $AndroidSdkRoot = $env:ANDROID_HOME
}
if (
    [string]::IsNullOrWhiteSpace($AndroidSdkRoot) -and
    -not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)
) {
    $AndroidSdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
}
if (
    [string]::IsNullOrWhiteSpace($AndroidSdkRoot) -or
    -not (Test-Path -LiteralPath $AndroidSdkRoot -PathType Container)
) {
    throw "Android SDK was not found at $AndroidSdkRoot"
}
$AndroidSdkRoot = (Resolve-Path -LiteralPath $AndroidSdkRoot).Path

# Never allow Flutter to leave a previous APK looking like a successful build.
if (Test-Path -LiteralPath $apk -PathType Leaf) {
    Remove-Item -LiteralPath $apk -Force
}

$env:ANDROID_HOME = $AndroidSdkRoot
$env:ANDROID_SDK_ROOT = $AndroidSdkRoot
if (-not [string]::IsNullOrWhiteSpace($CargoHome)) {
    $env:CARGO_HOME = (Resolve-Path -LiteralPath $CargoHome).Path
    Add-ToolDirectoryToPath -Executable (
        Join-Path $env:CARGO_HOME 'bin\cargo.exe'
    )
}
if (-not [string]::IsNullOrWhiteSpace($RustupHome)) {
    $env:RUSTUP_HOME = (Resolve-Path -LiteralPath $RustupHome).Path
}

$protoc = if ([string]::IsNullOrWhiteSpace($ProtocPath)) {
    Resolve-Tool -Value 'protoc' -DisplayName 'protoc'
} else {
    Resolve-Tool -Value $ProtocPath -DisplayName 'protoc'
}
$env:PROTOC = $protoc
Add-ToolDirectoryToPath -Executable $protoc

if (-not [string]::IsNullOrWhiteSpace($PerlExecutable)) {
    $perl = Resolve-Tool -Value $PerlExecutable -DisplayName 'Perl'
    Add-ToolDirectoryToPath -Executable $perl
}
if (-not [string]::IsNullOrWhiteSpace($PerlModuleRoot)) {
    if (-not (Test-Path -LiteralPath $PerlModuleRoot -PathType Container)) {
        throw "Perl module root was not found at $PerlModuleRoot"
    }
    # OpenSSL executes Perl through a POSIX shell. A UNC path prevents the
    # drive-letter colon from being parsed as a PERL5LIB separator.
    $env:PERL5LIB = Convert-ToPosixUncPath -WindowsPath $PerlModuleRoot
}
if (-not [string]::IsNullOrWhiteSpace($MakeExecutable)) {
    $make = Resolve-Tool -Value $MakeExecutable -DisplayName 'GNU Make'
    Add-ToolDirectoryToPath -Executable $make
}

Push-Location $repositoryRoot
try {
    & $flutter build apk --flavor alpha "--$Mode" --target-platform android-arm64
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter build failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) {
    throw "Flutter reported success but did not create $apk"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($apk)
$verificationError = $null
try {
    $requiredEntries = @(
        'lib/arm64-v8a/libflutter.so'
        'lib/arm64-v8a/libapp.so'
        'lib/arm64-v8a/librust_lib_bluebubbles.so'
    )
    foreach ($entryName in $requiredEntries) {
        $entry = $archive.GetEntry($entryName)
        if ($null -eq $entry -or $entry.Length -le 0) {
            throw "APK verification failed: missing native entry $entryName"
        }
    }
} catch {
    $verificationError = $_
} finally {
    $archive.Dispose()
}
if ($null -ne $verificationError) {
    Remove-Item -LiteralPath $apk -Force
    throw $verificationError
}

$apkInfo = Get-Item -LiteralPath $apk
Write-Output "Verified $($apkInfo.FullName) ($($apkInfo.Length) bytes)"
