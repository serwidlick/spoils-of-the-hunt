#Requires -Version 7
# Cuts a release: bumps the version, builds both store packages, tags and pushes, publishes a GitHub release
# with both zips, uploads the mod.io package through the mod.io API, and opens the Nexus upload page (Nexus has
# no upload API, so that last step is a manual file pick).
#
#   .\release.ps1 -Version 1.0.1 -Changelog "Fixes the katakan crit label."
#   .\release.ps1 -Version 1.1.0 -Changelog "..." -DryRun      # build and show what would happen, change nothing
#
# mod.io needs an OAuth access token with write access: mod.io > your avatar > API Access > create a token.
# Put it in the MODIO_TOKEN environment variable or in %USERPROFILE%\.modio-token (one line). Never in the repo.
param(
    [Parameter(Mandatory)] [ValidatePattern('^\d+\.\d+\.\d+$')] [string]$Version,
    [Parameter(Mandatory)] [string]$Changelog,
    [switch]$SkipModIo,
    [switch]$SkipGitHub,
    [switch]$SkipNexus,
    [switch]$DryRun,
    [string]$ModIoNameId = 'spoils-of-the-hunt',
    [string]$NexusEditUrl = 'https://www.nexusmods.com/witcher3/mods/edit/?id=13705&step=files'
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

function Step($msg) { Write-Host "`n== $msg" -ForegroundColor Cyan }

# ---- preconditions: fail before anything is changed --------------------------------------------------------
Step 'Preconditions'
if (Get-Process -Name witcher3 -ErrorAction SilentlyContinue) { throw 'The game is running. Quit it first.' }
if (git status --porcelain) { throw 'Working tree is not clean. Commit or stash first.' }
if ((git rev-parse --abbrev-ref HEAD) -ne 'main') { throw 'Release from main.' }
if (git tag -l "v$Version") { throw "Tag v$Version already exists." }
$buildFile = Join-Path $root 'build.ps1'
$current = [regex]::Match((Get-Content $buildFile -Raw), "(?m)^\`$version = '(\d+\.\d+\.\d+)'").Groups[1].Value
if (-not $current) { throw 'could not find $version in build.ps1' }
if ([version]$Version -le [version]$current) { throw "Version $Version is not newer than the current $current." }
if (-not $SkipGitHub) { gh auth status *> $null; if ($LASTEXITCODE -ne 0) { throw 'gh is not logged in (gh auth login).' } }
$token = $null
if (-not $SkipModIo) {
    $tokenFile = Join-Path $env:USERPROFILE '.modio-token'
    $token = if ($env:MODIO_TOKEN) { $env:MODIO_TOKEN } elseif (Test-Path $tokenFile) { (Get-Content $tokenFile -Raw).Trim() }
    if (-not $token) { throw "No mod.io token: set MODIO_TOKEN or write it to $tokenFile (or pass -SkipModIo)." }
    $headers = @{ Authorization = "Bearer $token"; Accept = 'application/json' }
    # resolve the mod id from the account's own mods; this also proves the token works before we change anything
    $mine = Invoke-RestMethod -Uri "https://api.mod.io/v1/me/mods?name_id=$ModIoNameId" -Headers $headers
    if ($mine.result_count -ne 1) { throw "mod.io: expected exactly one of your mods with name_id '$ModIoNameId', got $($mine.result_count)." }
    $modio = $mine.data[0]
    "mod.io mod #$($modio.id) '$($modio.name)' (game #$($modio.game_id)), currently $($modio.modfile.version ?? 'no file')"
}
"Releasing $current -> $Version$(if ($DryRun) { ' (dry run)' })"

# ---- version bump + build -------------------------------------------------------------------------------------
Step 'Build'
$content = Get-Content $buildFile -Raw
$content = $content -replace "(?m)^\`$version = '\d+\.\d+\.\d+'", "`$version = '$Version'"
[IO.File]::WriteAllText($buildFile, $content, [Text.UTF8Encoding]::new($false))
try {
    & $buildFile -Package -ModIo -ScriptBlob
    if ($LASTEXITCODE) { throw "build failed with exit code $LASTEXITCODE" }
} catch {
    git checkout -- $buildFile
    throw
}
$nexusZip = Join-Path $root "build\SpoilsOfTheHunt-$Version.zip"
$modioZip = Join-Path $root "build\SpoilsOfTheHunt-$Version-modio.zip"
foreach ($z in @($nexusZip, $modioZip)) { if (-not (Test-Path $z)) { git checkout -- $buildFile; throw "missing $z" } }
$md5 = (Get-FileHash $modioZip -Algorithm MD5).Hash.ToLower()
"Nexus:  $nexusZip ($((Get-Item $nexusZip).Length) bytes)"
"mod.io: $modioZip ($((Get-Item $modioZip).Length) bytes, md5 $md5)"

if ($DryRun) {
    git checkout -- $buildFile
    Step 'Dry run: nothing committed, tagged, pushed or uploaded'
    "Would commit 'chore(release): v$Version', tag v$Version, push, create GitHub release with both zips,"
    "upload $modioZip to mod.io mod #$($modio.id) as version $Version (active), and open $NexusEditUrl"
    return
}

# ---- commit + tag (local; pushed only after mod.io accepts the file) --------------------------------------------
Step 'Commit and tag'
git add -- $buildFile
git commit -q -m "chore(release): v$Version" -m $Changelog
if ($LASTEXITCODE) { throw 'commit failed' }
git tag -a "v$Version" -m "Spoils of the Hunt $Version`n`n$Changelog"
"Tagged v$Version (undo with: git tag -d v$Version; git reset --hard HEAD~1)"

# ---- mod.io upload ----------------------------------------------------------------------------------------------
if (-not $SkipModIo) {
    Step 'Upload to mod.io'
    $form = @{
        filedata  = Get-Item $modioZip
        version   = $Version
        changelog = $Changelog
        active    = 'true'
        filehash  = $md5
    }
    $file = Invoke-RestMethod -Method Post -Uri "https://api.mod.io/v1/games/$($modio.game_id)/mods/$($modio.id)/files" -Headers $headers -Form $form
    "mod.io file #$($file.id) version $($file.version), $($file.filesize) bytes, virus scan: $($file.virus_status) (0 = not scanned yet). Live."
    "Page: https://mod.io/g/the-witcher-3/m/$ModIoNameId"
}

# ---- push + GitHub release -------------------------------------------------------------------------------------
Step 'Push'
git push -q origin main
git push -q origin "v$Version"
if (-not $SkipGitHub) {
    Step 'GitHub release'
    gh release create "v$Version" $nexusZip $modioZip --title "Spoils of the Hunt $Version" --notes "$Changelog`n`n- SpoilsOfTheHunt-$Version.zip: Nexus / Vortex / manual install`n- SpoilsOfTheHunt-$Version-modio.zip: mod.io package (lowercase REDkit layout, info.json, precompiled.rsblob)"
    if ($LASTEXITCODE) { throw 'gh release create failed (the tag is pushed; rerun: gh release create ...)' }
}

# ---- Nexus: manual --------------------------------------------------------------------------------------------
if (-not $SkipNexus) {
    Step 'Nexus (manual: no upload API)'
    Set-Clipboard -Value $Changelog
    "Opening $NexusEditUrl"
    "  File:      $nexusZip"
    "  Version:   $Version"
    "  Changelog: copied to the clipboard"
    Start-Process $NexusEditUrl
}
Step "Released $Version"
