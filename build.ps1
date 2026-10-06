# Builds the mod and optionally installs it.
#   .\build.ps1            -> build only, into .\build\
#   .\build.ps1 -Install   -> build and copy into the game folder (quit the game first: it holds the bundles open)
#
# Output (two parts, both needed):
#   DLC\dlcSpoilsOfTheHunt\content\{blob0.bundle, metadata.store}   XML overrides + the .reddlc that mounts them
#   Mods\modSpoilsOfTheHunt\content\{blob0.bundle, metadata.store}  whole-file replacements (tooltip table)
#   Mods\modSpoilsOfTheHunt\content\scripts\...                     the patched attack script (loose)
#   .\build.ps1 -Package   -> also zip a Nexus/Vortex-ready archive into .\build\
#   .\build.ps1 -Install -TestHarness -> also install the test-only scripts from src\scripts-test (never packaged)
param(
    [switch]$Install,
    [switch]$Package,
    [switch]$TestHarness,
    [string]$GameDir = 'C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3'
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$version = '1.0.0'
$dlcName = 'dlcSpoilsOfTheHunt'
$modName = 'modSpoilsOfTheHunt'
$buildDlc = Join-Path $root "build\$dlcName"
$buildMod = Join-Path $root "build\$modName"

& (Join-Path $root 'generate-sources.ps1')

# 0. Localisation tables first, then the build-time checks (they need the strings to verify labels)
& (Join-Path $root 'make-w3strings.ps1') -OutDir (Join-Path $buildMod 'content')
& (Join-Path $root 'check-sources.ps1')
if ($LASTEXITCODE -ne 0) { throw 'check-sources failed; not building' }

# 1. DLC container: override XML + .reddlc mounter
$stage = Join-Path $root 'build\stage-dlc'
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
Copy-Item (Join-Path $root 'src\dlc') $stage -Recurse
& (Join-Path $root 'make-reddlc.ps1') -OutFile (Join-Path $stage "dlc\$($dlcName.ToLower())\$($dlcName.ToLower()).reddlc")
if (Test-Path $buildDlc) { Remove-Item $buildDlc -Recurse -Force }
& (Join-Path $root 'pack-mod.ps1') -InputDir $stage -OutDir $buildDlc

# 2. Mod container: whole-file replacements, plus loose scripts (localisation tables were written in step 0)
Get-ChildItem (Join-Path $buildMod 'content') -Exclude '*.w3strings' -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
& (Join-Path $root 'pack-mod.ps1') -InputDir (Join-Path $root 'src\mod') -OutDir $buildMod
Copy-Item (Join-Path $root 'src\scripts') (Join-Path $buildMod 'content\scripts') -Recurse

# post-build assertions on the package layout
foreach ($must in @("$buildDlc\content\blob0.bundle", "$buildDlc\content\metadata.store",
                    "$buildMod\content\blob0.bundle", "$buildMod\content\metadata.store",
                    "$buildMod\content\en.w3strings",
                    "$buildMod\content\scripts\local\modSpoilsOfTheHunt_attack.ws")) {
    if (-not (Test-Path $must)) { throw "package layout wrong: missing $must" }
}
if (Test-Path "$buildMod\content\scripts\scripts") { throw 'package layout wrong: nested scripts folder' }

"Built:"
Get-ChildItem $buildDlc, $buildMod -Recurse -File | ForEach-Object { '  ' + $_.FullName.Replace((Join-Path $root 'build\'), '') + '  ' + $_.Length }

if ($TestHarness) {
    if ($Package) { throw 'refusing to package a build that contains the test harness' }
    Copy-Item (Join-Path $root 'src\scripts-test\*.ws') (Join-Path $buildMod 'content\scripts\local\')
    Write-Warning 'TEST HARNESS INCLUDED: this build spawns creatures and prints debug text. Do not distribute it.'
}

if ($Package) {
    # Vortex's Witcher 3 "mixed" installer wants <dlcName>\content\ and <modName>\content\ trees; the
    # top-level DLC\ and Mods\ folders match the game layout and also work for manual installs.
    $pkg = Join-Path $root 'build\package'
    if (Test-Path $pkg) { Remove-Item $pkg -Recurse -Force }
    New-Item -ItemType Directory -Force "$pkg\DLC", "$pkg\Mods" | Out-Null
    Copy-Item $buildDlc "$pkg\DLC\$dlcName" -Recurse
    Copy-Item $buildMod "$pkg\Mods\$modName" -Recurse
    Copy-Item (Join-Path $root 'dist\README.txt') "$pkg\README.txt"
    $zip = Join-Path $root "build\SpoilsOfTheHunt-$version.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path "$pkg\*" -DestinationPath $zip
    "Packaged $zip"
}

if ($Install) {
    # The game keeps the bundles open; a partial Remove-Item would leave a half-installed package.
    if (Get-Process -Name witcher3 -ErrorAction SilentlyContinue) { throw 'The game is running. Quit it before installing.' }
    # pre-rename installs (the mod was "Witcher's Trophies" / LoreTrophies before 2026-10-06)
    foreach ($legacy in @("DLC\dlcLoreTrophies", "Mods\modLoreTrophies", "bin\config\r4game\user_config_matrix\pc\LoreTrophiesTest.xml")) {
        $p = Join-Path $GameDir $legacy
        if (Test-Path $p) { Remove-Item $p -Recurse -Force; "Removed legacy $p" }
    }
    foreach ($pair in @(@($buildDlc, "DLC\$dlcName"), @($buildMod, "Mods\$modName"))) {
        $dest = Join-Path $GameDir $pair[1]
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        Copy-Item $pair[0] $dest -Recurse
        "Installed $dest"
    }
    # test-only config declaration (Options > Mods page); removed again on a normal install
    $cfgDest = Join-Path $GameDir 'bin\config\r4game\user_config_matrix\pc\SpoilsOfTheHuntTest.xml'
    if ($TestHarness) { Copy-Item (Join-Path $root 'src\config-test\SpoilsOfTheHuntTest.xml') $cfgDest; "Installed $cfgDest" }
    elseif (Test-Path $cfgDest) { Remove-Item $cfgDest -Force; "Removed $cfgDest" }
}
