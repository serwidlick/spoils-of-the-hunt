# Build-time checks. Run by build.ps1 after sources and localisation tables are generated.
# Exits non-zero on any failure so a broken build never gets installed.
#
# Checks:
#   1. every attribute the mod uses has a row in the tooltip table (otherwise the stat is invisible)
#   2. every attribute has a display label (attribute_name_<stat>) in vanilla or our .w3strings
#   3. every vanilla trophy item still resolves to defined abilities, and every trophy is covered by the design
#   4. values are sane and use the right type (vs-class = mult like oils, resistances/chances = add)
#   5. the tooltip table is vanilla plus exactly the rows we add
#   6. the shipped script is vanilla plus the one marked patch block, nothing else (no leftover test hooks)
param(
    [string]$GameDir = 'C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3',
    [string]$OurStrings = "$PSScriptRoot\build\modSpoilsOfTheHunt\content\en.w3strings"
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$van = Join-Path $root 'vanilla'
$fails = New-Object System.Collections.Generic.List[string]
$passes = 0
function Pass($msg) { $script:passes++; "  ok   $msg" }
function Fail($msg) { $script:fails.Add($msg); "  FAIL $msg" }

# ---------------------------------------------------------------- load our XML
$xmlPath = Join-Path $root 'src\dlc\dlc\dlcspoilsofthehunt\data\gameplay\items\lore_trophies.xml'
[xml]$ours = Get-Content $xmlPath -Raw
$ourAbilities = @{}
foreach ($ab in $ours.redxml.definitions.abilities.ability) {
    $attrs = @()
    foreach ($node in $ab.ChildNodes) { if ($node.NodeType -eq 'Element' -and $node.Name -ne 'tags') { $attrs += [pscustomobject]@{ Name = $node.Name; Type = $node.GetAttribute('type'); Min = $node.GetAttribute('min') } } }
    $ourAbilities[$ab.name] = $attrs
}
$usedAttrs = $ourAbilities.Values | ForEach-Object { $_.Name } | Sort-Object -Unique
"checking $($ourAbilities.Count) abilities using $($usedAttrs.Count) distinct attributes"

# ---------------------------------------------------------------- 1. tooltip table rows
"`n[1] tooltip table"
$csvRows = Get-Content (Join-Path $root 'src\mod\gameplay\globals\tooltip_settings.csv') | ForEach-Object { ($_ -split ';')[0].Trim() } | Where-Object { $_ }
foreach ($a in $usedAttrs) { if ($a -in $csvRows) { Pass "tooltip row: $a" } else { Fail "no tooltip row for attribute '$a' (stat would be invisible)" } }

# ---------------------------------------------------------------- 2. labels
"`n[2] display labels"
function KeyHash([string]$key) { [long]$h = 0; foreach ($c in $key.ToLowerInvariant().ToCharArray()) { $h = ($h * 31 + [int]$c) -band 0xFFFFFFFFL }; [uint32]$h }
function LoadKeyHashes([string]$path) {
    $b = [System.IO.File]::ReadAllBytes($path)
    if ([System.Text.Encoding]::ASCII.GetString($b, 0, 4) -ne 'RTSW') { throw "$path is not a w3strings file" }
    $pos = [ref]10
    $nEntries = ReadBit6 $b $pos; $pos.Value += 12 * $nEntries
    $nKeys = ReadBit6 $b $pos
    $set = New-Object 'System.Collections.Generic.HashSet[uint32]'
    $p = $pos.Value
    for ($i = 0; $i -lt $nKeys; $i++) { [void]$set.Add([BitConverter]::ToUInt32($b, $p)); $p += 8 }
    $set
}
function ReadBit6([byte[]]$b, [ref]$pos) {
    $p = $pos.Value
    $v = [int64]($b[$p] -band 0x3F); $cont = ($b[$p] -band 0x40) -ne 0; $p++; $shift = 6
    while ($cont) { $v = $v -bor ([int64]($b[$p] -band 0x7F) -shl $shift); $cont = ($b[$p] -band 0x80) -ne 0; $p++; $shift += 7 }
    $pos.Value = $p
    $v
}
$vanillaKeys = LoadKeyHashes (Join-Path $GameDir 'content\content0\en.w3strings')
$ourKeys = if (Test-Path $OurStrings) { LoadKeyHashes $OurStrings } else { Fail "our strings not built: $OurStrings"; New-Object 'System.Collections.Generic.HashSet[uint32]' }
"  vanilla key table: $($vanillaKeys.Count) keys; ours: $($ourKeys.Count)"
foreach ($a in $usedAttrs) {
    $key = 'attribute_name_' + $a.ToLowerInvariant(); $h = KeyHash $key
    if ($vanillaKeys.Contains($h)) { Pass "label (vanilla): $key" }
    elseif ($ourKeys.Contains($h)) { Pass "label (mod):     $key" }
    else { Fail "no display label '$key' in vanilla or mod strings (tooltip would show #StatName)" }
}
foreach ($k in 'dlc_spoilsofthehunt_name', 'dlc_spoilsofthehunt_desc') { if ($ourKeys.Contains((KeyHash $k))) { Pass "string: $k" } else { Fail "missing string $k" } }

# ---------------------------------------------------------------- 3. every vanilla trophy resolves and is covered
"`n[3] trophy coverage"
$vanillaFiles = 'gameplay\items\def_item_trophies.xml', 'dlc\ep1\data\gameplay\items\def_item_trophies.xml', 'dlc\bob\data\gameplay\items\def_item_trophies.xml'
$vanillaAbilityNames = @{}
$trophies = @()
foreach ($f in $vanillaFiles) {
    $text = [System.IO.File]::ReadAllText((Join-Path $van $f))
    $text = [regex]::Replace($text, '(?s)<!--.*?-->', '')          # drop commented-out werewolf trophy
    [xml]$doc = $text
    foreach ($ab in $doc.redxml.definitions.abilities.ability) { $vanillaAbilityNames[$ab.name] = $true }
    foreach ($it in $doc.redxml.definitions.items.item) {
        if ($it.category -ne 'trophy') { continue }
        $abs = @($it.base_abilities.a | ForEach-Object { "$_".Trim() })
        $trophies += [pscustomobject]@{ Name = $it.name.Trim(); Abilities = $abs; File = $f }
    }
}
# apply our override of the zmora item
$zmora = $trophies | Where-Object { $_.Name -eq 'mq7017_zmora_trophy' }
if ($zmora) { $zmora.Abilities = @($ours.redxml.definitions.items.item | Where-Object { $_.name.Trim() -eq 'mq7017_zmora_trophy' } | ForEach-Object { $_.base_abilities.a | ForEach-Object { "$_".Trim() } }) }
$definedAfter = @{}; foreach ($k in $vanillaAbilityNames.Keys) { $definedAfter[$k] = 'vanilla' }; foreach ($k in $ourAbilities.Keys) { $definedAfter[$k] = 'mod' }
"  $($trophies.Count) vanilla trophy items found"
foreach ($t in $trophies) {
    $stat = $t.Abilities | Where-Object { $_ -ne 'base_trophy_stats' }
    foreach ($a in $stat) {
        if (-not $definedAfter.ContainsKey($a)) { Fail "$($t.Name) references undefined ability '$a'" }
        elseif ($definedAfter[$a] -ne 'mod') { Fail "$($t.Name) still uses vanilla ability '$a' (not covered by the design)" }
        else { Pass "$($t.Name) -> $a" }
    }
    if (-not $stat) { Fail "$($t.Name) has no stat ability at all" }
}
foreach ($n in $ourAbilities.Keys) { if ($n -ne 'zmora_trophy_stats' -and -not $vanillaAbilityNames.ContainsKey($n)) { Fail "mod ability '$n' overrides nothing in vanilla" } }

# ---------------------------------------------------------------- 4. value sanity
"`n[4] values"
$expectedType = @{ '^vs\w+_attack_power$' = 'mult'; '_resistance_perc$' = 'add'; '^critical_hit_chance$' = 'add'; '^spell_power_' = 'mult'; '^bonus_money$' = 'add' }
foreach ($n in $ourAbilities.Keys) {
    $attrs = $ourAbilities[$n]
    if (-not $attrs) { Fail "$n has no attributes"; continue }
    foreach ($a in $attrs) {
        $v = 0.0
        if (-not [double]::TryParse($a.Min, [ref]$v)) { Fail "$n/$($a.Name): min '$($a.Min)' is not a number"; continue }
        if ($v -le 0 -or $v -gt 0.5) { Fail "$n/$($a.Name): value $v outside (0, 0.5]" }
        $rule = $expectedType.Keys | Where-Object { $a.Name -match $_ } | Select-Object -First 1
        if (-not $rule) { Fail "$n/$($a.Name): attribute not in the known list (add a type rule)" }
        elseif ($a.Type -ne $expectedType[$rule]) { Fail "$n/$($a.Name): type '$($a.Type)' should be '$($expectedType[$rule])'" }
    }
}
Pass "$($ourAbilities.Count) abilities checked for type and range"

# ---------------------------------------------------------------- 5. tooltip table is vanilla + our rows
"`n[5] tooltip table integrity"
$vanCsv = Get-Content (Join-Path $van 'gameplay\globals\tooltip_settings.csv')
$ourCsv = Get-Content (Join-Path $root 'src\mod\gameplay\globals\tooltip_settings.csv')
$added = Compare-Object $vanCsv $ourCsv | Where-Object { $_.SideIndicator -eq '=>' } | ForEach-Object { $_.InputObject }
$removed = Compare-Object $vanCsv $ourCsv | Where-Object { $_.SideIndicator -eq '<=' }
if ($removed) { Fail "tooltip table lost vanilla rows: $($removed.InputObject -join ' | ')" } else { Pass 'no vanilla tooltip rows removed' }
foreach ($r in $added) { if ($r -match '^[A-Za-z_]+;[0-9A-Fa-f]{6};(TRUE|FALSE);[a-z]+;[0-9.]+$') { Pass "added row: $r" } else { Fail "malformed added row: $r" } }

# ---------------------------------------------------------------- 6. script = vanilla + marked patch only
"`n[6] scripts"
# Every shipped script must be annotation-style (@wrapMethod etc.): no whole-file copies of vanilla
# scripts, so the mod never collides with another mod and never needs Script Merger (Vortex records
# this as the mod's script style).
$vanillaScriptNames = Get-ChildItem (Join-Path $GameDir 'content\content0\scripts') -Recurse -Filter *.ws | ForEach-Object { $_.Name.ToLowerInvariant() }
$scripts = Get-ChildItem (Join-Path $root 'src\scripts') -Recurse -Filter *.ws
if (-not $scripts) { Fail 'no script shipped (the vs-class bonus needs the attack wrapper)' }
foreach ($s in $scripts) {
    $text = Get-Content $s.FullName -Raw
    if ($text -notmatch '@(wrapMethod|replaceMethod|addMethod|addField)\b') { Fail "$($s.Name) is not annotation-style (would need Script Merger)" } else { Pass "$($s.Name) uses scope annotations" }
    if ($s.Name.ToLowerInvariant() -in $vanillaScriptNames) { Fail "$($s.Name) shadows a vanilla script file name" } else { Pass "$($s.Name) does not shadow a vanilla file" }
    if ($text -match 'TEST HARNESS|DisplayHudMessage') { Fail "$($s.Name) still contains test-hook code" } else { Pass "$($s.Name) has no test-hook code" }
    if ($text -match '@wrapMethod' -and $text -notmatch 'wrappedMethod\(') { Fail "$($s.Name) wraps a method but never calls wrappedMethod()" }
}
$attack = $scripts | Where-Object { $_.Name -eq 'modSpoilsOfTheHunt_attack.ws' } | ForEach-Object { Get-Content $_.FullName -Raw }
if ($attack -match "GetAttributeValue\(\s*bonusName\s*,\s*trophyTags\s*\)" -and $attack -match "PushBack\('SpoilsOfTheHunt'\)") { Pass 'attack wrapper reads only SpoilsOfTheHunt-tagged abilities' } else { Fail 'attack wrapper lookup is not tag-filtered (would double-count sword oils)' }
# The bonus must scale the attack power multiplier (x1.10), not add to it, so the tooltip % stays true however large the multiplier is.
if ($attack -match "valueMultiplicative\s*\*=\s*\(1\s*\+\s*bonus\.valueMultiplicative\)") { Pass 'attack wrapper scales the multiplier (tooltip % = real damage %)' } else { Fail 'attack wrapper adds to the multiplier instead of scaling it (bonus would be ~1% damage)' }

"`n[7] ability tags"
foreach ($ab in $ours.redxml.definitions.abilities.ability) { if (("$($ab.tags)").Trim() -eq 'SpoilsOfTheHunt') { $script:passes++ } else { Fail "$($ab.name) is missing <tags>SpoilsOfTheHunt</tags>" } }
Pass "$($ourAbilities.Count) abilities carry the SpoilsOfTheHunt tag"

# ---------------------------------------------------------------- summary
"`n$passes checks passed, $($fails.Count) failed"
if ($fails.Count) { $fails | ForEach-Object { "  - $_" }; exit 1 }
exit 0   # explicit, so the caller's $LASTEXITCODE is never stale
