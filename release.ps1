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
    [int]$ModIoGameId = 8254,   # The Witcher 3: Wild Hunt on mod.io; the API lives on a per-game host (api.mod.io is deprecated for writes)
    [string]$NexusEditUrl = 'https://www.nexusmods.com/witcher3/mods/edit/?id=13705&step=files',
    [string]$NexusGameDomain = 'witcher3',
    [int]$NexusModId = 13705,          # game-scoped id from the mod page URL
    [string]$NexusFileId = '',        # the "mod file" to add versions to; resolved automatically when the mod has exactly one active file
    [switch]$NexusManual               # skip the Nexus API and just open the upload page
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

function Step($msg) { Write-Host "`n== $msg" -ForegroundColor Cyan }

# ---- preconditions: fail before anything is changed --------------------------------------------------------
Step 'Preconditions'
if (Get-Process -Name witcher3 -ErrorAction SilentlyContinue) { throw 'The game is running. Quit it first.' }
if (git status --porcelain) { if ($DryRun) { Write-Warning 'Working tree is not clean (allowed for a dry run).' } else { throw 'Working tree is not clean. Commit or stash first.' } }
if ((git rev-parse --abbrev-ref HEAD) -ne 'main') { throw 'Release from main.' }
if (git tag -l "v$Version") { throw "Tag v$Version already exists." }
$buildFile = Join-Path $root 'build.ps1'
$current = [regex]::Match((Get-Content $buildFile -Raw), "(?m)^\`$version = '(\d+\.\d+\.\d+)'").Groups[1].Value
if (-not $current) { throw 'could not find $version in build.ps1' }
if ([version]$Version -le [version]$current) { throw "Version $Version is not newer than the current $current." }
if (-not $SkipGitHub) { gh auth status *> $null; if ($LASTEXITCODE -ne 0) { throw 'gh is not logged in (gh auth login).' } }
$token = $null
if (-not $SkipModIo) {
    $tokenFile = @('.modio-token', 'modio-token.txt', '.modio-token.txt') | ForEach-Object { Join-Path $env:USERPROFILE $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1
    $token = if ($env:MODIO_TOKEN) { $env:MODIO_TOKEN } elseif ($tokenFile) { (Get-Content $tokenFile -Raw).Trim() }
    if (-not $token) { throw "No mod.io token: set MODIO_TOKEN or write it to $env:USERPROFILE\.modio-token (or pass -SkipModIo)." }
    if ($token -match '^[0-9a-f]{32}$') { throw 'That is a mod.io API key (read-only). Uploads need an OAuth access token: mod.io > avatar > API Access > "Create an OAuth 2 Access Token" (it is several hundred characters long).' }
    $headers = @{ Authorization = "Bearer $token"; Accept = 'application/json' }
    $api = "https://g-$ModIoGameId.modapi.io/v1"
    # resolve the mod id from the account's own mods; this also proves the token works before we change anything
    $mine = Invoke-RestMethod -Uri "$api/me/mods?name_id=$ModIoNameId" -Headers $headers
    if ($mine.result_count -ne 1) { throw "mod.io: expected exactly one of your mods with name_id '$ModIoNameId', got $($mine.result_count)." }
    $modio = $mine.data[0]
    "mod.io mod #$($modio.id) '$($modio.name)' (game #$($modio.game_id)), currently $($modio.modfile.version ?? 'no file')"
}
$nexusKey = $null
if (-not $SkipNexus -and -not $NexusManual) {
    # Nexus v3 API: personal key from https://www.nexusmods.com/settings/api-keys, sent as an "apikey" header.
    $keyFile = @('.nexus-apikey', 'nexus-apikey.txt', '.nexus-apikey.txt') | ForEach-Object { Join-Path $env:USERPROFILE $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1
    $nexusKey = if ($env:NEXUS_API_KEY) { $env:NEXUS_API_KEY } elseif ($keyFile) { (Get-Content $keyFile -Raw).Trim() }
    if (-not $nexusKey) { throw "No Nexus API key: set NEXUS_API_KEY or write it to $env:USERPROFILE\nexus-apikey.txt (or pass -NexusManual to upload by hand)." }
    $nexusApi = 'https://api.nexusmods.com/v3'
    $nexusHeaders = @{ apikey = $nexusKey; Accept = 'application/json'; 'User-Agent' = 'spoils-of-the-hunt release.ps1' }
    $nexusMod = (Invoke-RestMethod -Uri "$nexusApi/games/$NexusGameDomain/mods/$NexusModId" -Headers $nexusHeaders).data
    # A Nexus "mod file" is the persistent entry on the Files tab; each upload becomes a new version of it. With one
    # active file there is nothing to choose; otherwise -NexusFileId picks (the id shows under Files > Advanced).
    $nexusFiles = @((Invoke-RestMethod -Uri "$nexusApi/mods/$($nexusMod.id)/files" -Headers $nexusHeaders).data.mod_files | Where-Object { $_.is_active })
    if (-not $NexusFileId) {
        if ($nexusFiles.Count -ne 1) { throw "Nexus mod has $($nexusFiles.Count) active files; pass -NexusFileId (one of: $(($nexusFiles | ForEach-Object { "$($_.id) '$($_.name)'" }) -join ', '))." }
        $NexusFileId = $nexusFiles[0].id
    }
    $nexusFile = $nexusFiles | Where-Object { $_.id -eq $NexusFileId }
    if (-not $nexusFile) { throw "Nexus mod file $NexusFileId is not one of this mod's active files." }
    "Nexus mod #$($nexusMod.id) '$($nexusMod.name)', file #$($nexusFile.id) '$($nexusFile.name)' ($($nexusFile.versions_count) versions so far)"
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
    "upload $modioZip to mod.io mod #$($modio.id) as version $Version (active),"
    if ($nexusKey) { "upload $nexusZip to Nexus mod #$($nexusMod.id) as a new version of file '$($nexusFile.name)' with the changelog" } else { "and open $NexusEditUrl" }
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
    $file = Invoke-RestMethod -Method Post -Uri "$api/games/$($modio.game_id)/mods/$($modio.id)/files" -Headers $headers -Form $form
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

# ---- Nexus -------------------------------------------------------------------------------------------------------
if ($nexusKey) {
    Step 'Upload to Nexus'
    # Single-part upload session (files under 100 MiB): create -> PUT bytes to the presigned URL -> finalise ->
    # wait for state "available" -> attach as a new version of the existing mod file -> add the changelog.
    # Same sequence as Nexus-Mods/upload-action; md5 binds the presigned URL to this exact file.
    $nexusMd5 = (Get-FileHash $nexusZip -Algorithm MD5).Hash.ToLower()
    $nexusName = Split-Path $nexusZip -Leaf
    $body = @{ filename = $nexusName; size_bytes = (Get-Item $nexusZip).Length; md5 = $nexusMd5 } | ConvertTo-Json
    $upload = (Invoke-RestMethod -Method Post -Uri "$nexusApi/uploads" -Headers $nexusHeaders -ContentType 'application/json' -Body $body).data
    "upload session $($upload.id)"
    $md5b64 = [Convert]::ToBase64String([byte[]] -split ($nexusMd5 -replace '..', '0x$& '))
    Invoke-WebRequest -Method Put -Uri $upload.presigned_url -InFile $nexusZip -ContentType 'application/octet-stream' `
        -Headers @{ 'Content-Disposition' = "attachment; filename=`"$nexusName`""; 'Content-MD5' = $md5b64 } | Out-Null
    Invoke-RestMethod -Method Post -Uri "$nexusApi/uploads/$($upload.id)/finalise" -Headers $nexusHeaders | Out-Null
    $state = ''
    for ($i = 0; $i -lt 60 -and $state -ne 'available'; $i++) {
        Start-Sleep -Seconds ([Math]::Min(2 * [Math]::Pow(1.5, $i), 30))
        $state = (Invoke-RestMethod -Uri "$nexusApi/uploads/$($upload.id)" -Headers $nexusHeaders).data.state
        "  state: $state"
    }
    if ($state -ne 'available') { throw "Nexus upload $($upload.id) did not become available (last state '$state'); attach it by hand at $NexusEditUrl" }
    $verBody = @{
        upload_id                    = $upload.id
        name                         = "SpoilsOfTheHunt $Version"
        version                      = $Version
        file_category                = 'main'
        primary_mod_manager_download = $true
        allow_mod_manager_download   = $true
        update_mod_version           = $true
        archive_existing_file        = $true
    } | ConvertTo-Json
    $ver = (Invoke-RestMethod -Method Post -Uri "$nexusApi/mod-files/$NexusFileId/versions" -Headers $nexusHeaders -ContentType 'application/json' -Body $verBody).data
    "Nexus file version #$($ver.version.id) '$($ver.version.name)' live; previous version archived"
    if ($nexusFile.name -ne 'SpoilsOfTheHunt') {
        # the mod file was created from the first upload and inherited its versioned name; versions carry the number
        Invoke-RestMethod -Method Put -Uri "$nexusApi/mod-files/$NexusFileId" -Headers $nexusHeaders -ContentType 'application/json' -Body (@{ name = 'SpoilsOfTheHunt' } | ConvertTo-Json) | Out-Null
    }
    Invoke-RestMethod -Method Post -Uri "$nexusApi/mods/$($nexusMod.id)/changelogs" -Headers $nexusHeaders -ContentType 'application/json' -Body (@{ version = $Version; changelog = $Changelog } | ConvertTo-Json) | Out-Null
    "Changelog added. Page: https://www.nexusmods.com/$NexusGameDomain/mods/$NexusModId?tab=files"
} elseif (-not $SkipNexus) {
    Step 'Nexus (manual)'
    Set-Clipboard -Value $Changelog
    "Opening $NexusEditUrl"
    "  File:      $nexusZip"
    "  Version:   $Version"
    "  Changelog: copied to the clipboard"
    Start-Process $NexusEditUrl
}
Step "Released $Version"
