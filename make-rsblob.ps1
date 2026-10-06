# Compiles the mod's scripts into a REDkit "script blob" (precompiled.rsblob) with wcc_lite, REDkit's offline
# compiler. Consoles cannot compile WitcherScript, so a mod.io mod needs this file next to its info.json to be
# considered for PlayStation/Xbox/Switch 2. PC ignores it and compiles the loose .ws files as usual.
#
# Usage (normally called by build.ps1 -ModIo -ScriptBlob):
#   .\make-rsblob.ps1 -ScriptsDir .\src\scripts -OutFile .\build\precompiled.rsblob
#
# wcc_lite shows REDkit's EULA the first time it runs (a window titled "EULA"). Accepting it is your decision,
# so this script waits and tells you about it instead of clicking through.
param(
    [Parameter(Mandatory)] [string]$ScriptsDir,
    [Parameter(Mandatory)] [string]$OutFile,
    [string]$RedkitDir = 'C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3 REDkit',
    [int]$TimeoutMinutes = 20
)
$ErrorActionPreference = 'Stop'

$wcc = Join-Path $RedkitDir 'bin\x64_RedKit\wcc_lite.exe'
$vanilla = Join-Path $RedkitDir 'r4data\scripts'
if (-not (Test-Path $wcc)) { throw "wcc_lite not found at $wcc (install The Witcher 3 REDkit from Steam, or pass -RedkitDir)" }
if (-not (Test-Path (Join-Path $vanilla 'game\r4Game.ws'))) { throw "REDkit's vanilla script tree not found at $vanilla" }
$ScriptsDir = (Resolve-Path $ScriptsDir).Path
if (-not (Get-ChildItem $ScriptsDir -Recurse -Filter *.ws)) { throw "no .ws files under $ScriptsDir" }

# wcc_lite wants absolute Windows paths and an empty output folder; it names the result itself.
$work = Join-Path ([IO.Path]::GetTempPath()) ("spoilsofthehunt-rsblob-" + [guid]::NewGuid().ToString('n'))
$patch = Join-Path $work 'scripts'
$outDir = Join-Path $work 'out'
New-Item -ItemType Directory -Force $patch, $outDir | Out-Null
Copy-Item (Join-Path $ScriptsDir '*') $patch -Recurse

$psi = [Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $wcc
$psi.WorkingDirectory = Split-Path $wcc
$psi.Arguments = "compilescripts `"$vanilla`" -patch=`"$patch`" -out=`"$outDir`""
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
"wcc_lite compilescripts (vanilla: $vanilla; patch: $ScriptsDir)"
$p = [Diagnostics.Process]::Start($psi)
$stdout = $p.StandardOutput.ReadToEndAsync()
$stderr = $p.StandardError.ReadToEndAsync()

$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$warned = $false
while (-not $p.WaitForExit(2000)) {
    $p.Refresh()
    if (-not $warned -and $p.MainWindowTitle -eq 'EULA') {
        Write-Warning 'wcc_lite is showing the REDkit EULA. Read and accept it in that window to continue (this script will not click it for you).'
        $warned = $true
    }
    if ((Get-Date) -gt $deadline) { $p.Kill(); throw "wcc_lite did not finish within $TimeoutMinutes minutes" }
}
$log = $stdout.Result + $stderr.Result
$logFile = [IO.Path]::ChangeExtension($OutFile, '.wcc.log')
New-Item -ItemType Directory -Force (Split-Path $OutFile) | Out-Null
$log | Set-Content $logFile
if ($p.ExitCode -ne 0) { throw "wcc_lite exited with code $($p.ExitCode); see $logFile" }

$blob = Get-ChildItem $outDir -Recurse -Filter *.rsblob | Select-Object -First 1
if (-not $blob) { throw "wcc_lite produced no .rsblob in $outDir; see $logFile" }
if ($log -match '(?im)^\s*\S*error') { Write-Warning "wcc_lite log mentions errors; check $logFile" }
Copy-Item $blob.FullName $OutFile -Force
Remove-Item $work -Recurse -Force
"Wrote $OutFile ($($blob.Length) bytes, from $($blob.Name))"
