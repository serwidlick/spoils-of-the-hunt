# Watches the game's user settings file for the test harness's values and prints changes.
# Ends when both damage buckets have at least -MinHits non-critical hits, or after -WaitMinutes.
param([int]$MinHits = 6, [int]$WaitMinutes = 60, [string]$RequireKey = '')
# -RequireKey: ignore the file until this key appears (used to skip stale totals written by an older harness build)
$file = "$env:USERPROFILE\Documents\The Witcher 3\dx12user.settings"
"watching $file for LT* values ($(Get-Date -Format T))$(if ($RequireKey) { "; waiting for key $RequireKey" })"
$last = ''
$deadline = (Get-Date).AddMinutes($WaitMinutes)
function Val($lines, $key) { $m = [regex]::Match($lines, "(?m)^$key=(\d+)"); if ($m.Success) { [double]$m.Groups[1].Value } else { 0 } }
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 3
    if (-not (Test-Path $file)) { continue }
    $lines = (Get-Content $file -ErrorAction SilentlyContinue | Where-Object { $_ -match '^LT' }) -join "`n"
    if ($RequireKey -and $lines -notmatch "(?m)^$RequireKey=") { continue }
    if ($lines -and $lines -ne $last) {
        $last = $lines
        $wn = Val $lines 'LTwithN'; $ws = Val $lines 'LTwithSum'; $on = Val $lines 'LTwithoutN'; $os = Val $lines 'LTwithoutSum'
        $wa = if ($wn) { $ws / $wn } else { 0 }; $oa = if ($on) { $os / $on } else { 0 }
        $ratio = if ($oa) { $wa / $oa } else { 0 }
        "--- $(Get-Date -Format T)  with trophy: n=$wn avg=$([math]::Round($wa,1))  | without: n=$on avg=$([math]::Round($oa,1))  | ratio=$([math]::Round($ratio,3))  | last equip: hybridBonus=$((Val $lines 'LTequipHybridX1000')/1000) anyBonus=$(Val $lines 'LTequipAnyBonus')  | power: base=$((Val $lines 'LTpowerBaseX1000')/1000) mult=$((Val $lines 'LTpowerMultX1000')/1000) add=$((Val $lines 'LTpowerAddX1000')/1000)"
        if ($wn -ge $MinHits -and $on -ge $MinHits) { "both buckets have >= $MinHits hits; done"; break }
    }
}
"watch ended $(Get-Date -Format T)"
