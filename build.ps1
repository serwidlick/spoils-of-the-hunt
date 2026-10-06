# Builds the mod and optionally installs it.
#   .\build.ps1            -> build only, into .\build\
#   .\build.ps1 -Install   -> build and copy into the game folder (quit the game first: it holds the bundles open)
#
# Output (two parts, both needed):
#   DLC\dlcSpoilsOfTheHunt\content\{blob0.bundle, metadata.store}   XML overrides + the .reddlc that mounts them
#   Mods\modSpoilsOfTheHunt\content\{blob0.bundle, metadata.store}  whole-file replacements (tooltip table)
#   Mods\modSpoilsOfTheHunt\content\scripts\...                     the patched attack script (loose)
#   .\build.ps1 -Package   -> also zip a Nexus/Vortex-ready archive into .\build\
#   .\build.ps1 -ModIo     -> also zip a mod.io-ready archive (REDkit "packed" layout, lowercase paths, info.json)
#   .\build.ps1 -ModIo -ScriptBlob -> additionally compile the script into precompiled.rsblob with REDkit's wcc_lite
#                             (needed for the mod to be considered for consoles; PC works without it)
#   .\build.ps1 -Install -TestHarness -> also install the test-only scripts from src\scripts-test (never packaged)
#   .\build.ps1 -Uninstall -> remove the mod from the game folder (e.g. before letting Vortex manage it) and stop
param(
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Package,
    [switch]$ModIo,
    [switch]$ScriptBlob,
    [switch]$TestHarness,
    [string]$GameDir = 'C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3',
    [string]$RedkitDir = 'C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3 REDkit'
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$version = '1.0.0'
# Integer the game compares against its own build ("GAME version: current=%d, encountered=%d"). REDkit writes it
# into every project's info.json; 29 is what REDkit 5.0 projects published after the Remastered launch carry.
$modioGameVersion = '29'
$dlcName = 'dlcSpoilsOfTheHunt'
$modName = 'modSpoilsOfTheHunt'
$buildDlc = Join-Path $root "build\$dlcName"
$buildMod = Join-Path $root "build\$modName"

if ($Uninstall) {
    if (Get-Process -Name witcher3 -ErrorAction SilentlyContinue) { throw 'The game is running. Quit it before uninstalling.' }
    foreach ($rel in @("DLC\$dlcName", "Mods\$modName", "DLC\dlcLoreTrophies", "Mods\modLoreTrophies",
                       "bin\config\r4game\user_config_matrix\pc\SpoilsOfTheHuntTest.xml", "bin\config\r4game\user_config_matrix\pc\LoreTrophiesTest.xml")) {
        $p = Join-Path $GameDir $rel
        if (Test-Path $p) { Remove-Item $p -Recurse -Force; "Removed $p" }
    }
    "Uninstalled. (A DlcEnabled_dlc_spoilsofthehunt line may remain in Documents\The Witcher 3\dx12user.settings; it is harmless.)"
    return
}

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

if ($ScriptBlob -and -not $ModIo) { throw '-ScriptBlob only makes sense together with -ModIo' }

if ($ModIo) {
    if ($TestHarness) { throw 'refusing to package a build that contains the test harness' }
    # mod.io (the in-game Mods menu) expects what REDkit's Publish step writes to its "packed" folder: dlc\ and
    # mods\ at the archive root, an info.json manifest in the mod's content folder, and lowercase paths (the
    # console file systems are case-sensitive; bundle-internal paths are already lowercase). Nothing else at root.
    $mio = Join-Path $root 'build\modio'
    if (Test-Path $mio) { Remove-Item $mio -Recurse -Force }
    foreach ($pair in @(@($buildDlc, "dlc\$dlcName"), @($buildMod, "mods\$modName"))) {
        Get-ChildItem $pair[0] -Recurse -File | ForEach-Object {
            $rel = $_.FullName.Substring($pair[0].Length).TrimStart('\')
            $dest = Join-Path $mio (($pair[1] + '\' + $rel).ToLowerInvariant())
            New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
            Copy-Item $_.FullName $dest
        }
    }
    $mioMod = Join-Path $mio "mods\$($modName.ToLower())\content"

    if ($ScriptBlob) {
        # Consoles cannot compile WitcherScript; the game looks for precompiled.rsblob next to info.json
        # ("missingScriptBlob" in the loader). wcc_lite is REDkit's offline compiler.
        & (Join-Path $root 'make-rsblob.ps1') -ScriptsDir (Join-Path $root 'src\scripts') -OutFile (Join-Path $mioMod 'precompiled.rsblob') -LogFile (Join-Path $root 'build\wcc.log') -RedkitDir $RedkitDir
        if (-not (Test-Path (Join-Path $mioMod 'precompiled.rsblob'))) { throw 'script blob was not produced' }
    }

    # Same keys REDkit writes (bool spelled "succesfullyCooked" in REDkit too). name = project name, modName = title.
    $manifest = [ordered]@{
        name              = 'SpoilsOfTheHunt'
        modName           = 'Spoils of the Hunt'
        version           = $version
        gameVersion       = $modioGameVersion
        description       = 'Lore-friendly saddle trophy bonuses: each trophy gives attack power against its own monster class or a trait of the beast, instead of +5% gold or XP.'
        author            = 'serwidlick'
        idSpace           = 10000000
        workshopId        = 0
        succesfullyCooked = $true
        dependencies      = @()
        useLooseScripts   = $false
    }
    $json = ($manifest | ConvertTo-Json -Depth 3) -replace '"dependencies":\s*(null|\{\})', '"dependencies": []'
    [IO.File]::WriteAllText((Join-Path $mioMod 'info.json'), $json + "`n", [Text.UTF8Encoding]::new($false))

    # layout assertions
    if (Get-ChildItem $mio -Recurse -File -Include '*.log', '*.txt', '*.md') { throw 'mod.io layout wrong: stray text file in package' }
    foreach ($must in @("dlc\$dlcName\content\blob0.bundle", "dlc\$dlcName\content\metadata.store",
                        "mods\$modName\content\blob0.bundle", "mods\$modName\content\metadata.store",
                        "mods\$modName\content\en.w3strings", "mods\$modName\content\info.json",
                        "mods\$modName\content\scripts\local\modSpoilsOfTheHunt_attack.ws")) {
        if (-not (Test-Path (Join-Path $mio $must.ToLowerInvariant()))) { throw "mod.io layout wrong: missing $must" }
    }
    Get-ChildItem $mio -Recurse | ForEach-Object {
        $rel = $_.FullName.Substring($mio.Length)
        if ($rel -cne $rel.ToLowerInvariant()) { throw "mod.io layout wrong: path is not lowercase: $rel" }
    }
    $parsed = Get-Content (Join-Path $mioMod 'info.json') -Raw | ConvertFrom-Json
    if ($parsed.gameVersion -ne $modioGameVersion -or $parsed.version -ne $version -or $parsed.dependencies.Count -ne 0) { throw 'info.json round-trip mismatch' }

    # .NET's zip writer uses forward slashes in entry names (Compress-Archive on Windows PowerShell did not).
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = Join-Path $root "build\SpoilsOfTheHunt-$version-modio.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    [IO.Compression.ZipFile]::CreateFromDirectory($mio, $zip, [IO.Compression.CompressionLevel]::Optimal, $false)
    $entries = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        foreach ($e in $entries.Entries) {
            if ($e.FullName -match '\\' -or $e.FullName -cne $e.FullName.ToLowerInvariant()) { throw "bad zip entry name: $($e.FullName)" }
            if ($e.FullName -notmatch '^(dlc|mods)/') { throw "unexpected zip root entry: $($e.FullName)" }
        }
        "Packaged $zip ($($entries.Entries.Count) entries$(if ($ScriptBlob) { ', with precompiled.rsblob' } else { ', loose script only: PC' }))"
    } finally { $entries.Dispose() }
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
