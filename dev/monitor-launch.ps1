# Waits for witcher3.exe to start (after any running instance exits) and reports whether it
# survives startup or writes a crash dump. Used while testing builds.
param([int]$WaitMinutes = 10, [int]$SurviveSeconds = 150, [string]$Label = '')
$dumpDir = "$env:LOCALAPPDATA\CrashDumps"
$before = (Get-ChildItem $dumpDir -Filter 'witcher3*.dmp' -ErrorAction SilentlyContinue).Count
"monitor started $(Get-Date -Format T) $Label"
$old = Get-Process -Name witcher3 -ErrorAction SilentlyContinue
if ($old) { "waiting for running game (pid $($old[0].Id)) to exit..."; while (Get-Process -Name witcher3 -ErrorAction SilentlyContinue) { Start-Sleep 3 }; "old instance closed $(Get-Date -Format T)" }
$seen = $false; $t0 = $null
for ($i = 0; $i -lt ($WaitMinutes * 12); $i++) {
    Start-Sleep -Seconds 5
    $w = Get-Process -Name witcher3 -ErrorAction SilentlyContinue
    $dumps = (Get-ChildItem $dumpDir -Filter 'witcher3*.dmp' -ErrorAction SilentlyContinue).Count
    if ($w -and -not $seen) { $seen = $true; $t0 = Get-Date; "game started pid=$($w[0].Id) at $(Get-Date -Format T)" }
    if ($dumps -gt $before) { "NEW CRASH DUMP at $(Get-Date -Format T)"; break }
    if ($seen -and -not $w) { "game process gone after $([int]((Get-Date) - $t0).TotalSeconds)s, no dump"; break }
    if ($seen -and ((Get-Date) - $t0).TotalSeconds -gt $SurviveSeconds) { "game still running after ${SurviveSeconds}s: startup survived"; break }
}
if (-not $seen) { "game never started within $WaitMinutes minutes" }
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=(Get-Date).AddMinutes(-($WaitMinutes+2))} -ErrorAction SilentlyContinue |
    Where-Object { $_.Message -match 'witcher3' } | Select-Object -First 1 |
    ForEach-Object { "crash event: " + (($_.Message -split "`n")[0..8] -join ' | ') }
"done"
