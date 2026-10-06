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
#   7. every override ability carries the SpoilsOfTheHunt tag (the attack script reads only tagged abilities)
#   8. every trophy with vanilla's generic description is redefined with its own text, strings exist, and each
#      redefinition is vanilla plus that one change (icon, mesh, tags, price, abilities intact)
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
foreach ($n in $ourAbilities.Keys) { if ($n -ne 'zmora_trophy_stats' -and $n -notlike 'soth_fused_*' -and -not $vanillaAbilityNames.ContainsKey($n)) { Fail "mod ability '$n' overrides nothing in vanilla" } }

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

# ---------------------------------------------------------------- 8. item redefinitions and flavour text
"`n[8] item redefinitions and flavour text"
$flavour = Import-PowerShellDataFile (Join-Path $root 'trophy-text.psd1')
$descByItem = @{}
foreach ($p in $flavour.Descriptions) { if ($descByItem.ContainsKey($p[0])) { Fail "duplicate flavour text entry $($p[0])" }; $descByItem[$p[0]] = $p[1] }
$nameByItem = @{}
foreach ($p in $flavour.Names) { if ($nameByItem.ContainsKey($p[0])) { Fail "duplicate name override $($p[0])" }; $nameByItem[$p[0]] = $p[1] }
$ourItems = @{}
foreach ($it in $ours.redxml.definitions.items.item) { $ourItems[$it.name.Trim()] = $it }
$vanillaItems = @{}
foreach ($f in $vanillaFiles) {
    $text = [System.IO.File]::ReadAllText((Join-Path $van $f))
    [xml]$doc = [regex]::Replace($text, '(?s)<!--.*?-->', '')
    foreach ($it in $doc.redxml.definitions.items.item) { if ($it.category -eq 'trophy') { $vanillaItems[$it.name.Trim()] = $it } }
}
foreach ($name in ($vanillaItems.Keys | Sort-Object)) {
    $v = $vanillaItems[$name]
    $generic = $v.localisation_key_description.Trim() -eq 'item_desc_trophy'
    if ($generic) {
        if (-not $ourItems.ContainsKey($name)) { Fail "$name still shows the generic vanilla description"; continue }
        $key = $ourItems[$name].localisation_key_description.Trim()
        $t = $descByItem[$name]
        if ($key -ne "item_desc_soth_$name") { Fail "$name description key is '$key', expected item_desc_soth_$name" }
        elseif (-not $ourKeys.Contains((KeyHash $key))) { Fail "no string for $key in our w3strings (tooltip would show #$key)" }
        elseif (-not $t -or $t.Length -lt 40 -or $t.Length -gt 260) { Fail "$name flavour text is $($t.Length) chars (want 40-260 so it fits the tooltip)" }
        else { Pass "${name}: own description ($($t.Length) chars)" }
    } elseif ($ourItems.ContainsKey($name) -and $name -ne 'mq7017_zmora_trophy') { Fail "$name has a unique vanilla description and should not be redefined" }
    else { Pass "${name}: keeps its vanilla description" }
    if ($ourItems.ContainsKey($name)) {
        # a redefinition must be vanilla plus our one change, or the trophy would lose its icon, mesh, tags or price
        $o = $ourItems[$name]
        if ($o.GetAttribute('on_conflict') -ne 'replace') { Fail "$name redefinition lacks on_conflict=`"replace`"" }
        foreach ($attr in $v.Attributes) {
            if ($attr.Name -eq 'localisation_key_description' -and $generic) { continue }
            if ($attr.Name -eq 'localisation_key_name' -and $nameByItem.ContainsKey($name)) {
                if ($o.GetAttribute('localisation_key_name').Trim() -ne "item_name_soth_$name" -or -not $ourKeys.Contains((KeyHash "item_name_soth_$name"))) { Fail "${name}: renamed, but key or string is wrong" } else { Pass "${name}: renamed to '$($nameByItem[$name])'" }
                continue
            }
            if ($o.GetAttribute($attr.Name).Trim() -ne $attr.Value.Trim()) { Fail "$name attribute '$($attr.Name)' differs from vanilla" }
        }
        if (("$($o.tags)" -replace '\s', '') -ne ("$($v.tags)" -replace '\s', '')) { Fail "$name tags differ from vanilla" }
        $vAb = @($v.base_abilities.a | ForEach-Object { "$_".Trim() }); $oAb = @($o.base_abilities.a | ForEach-Object { "$_".Trim() })
        if ($name -eq 'mq7017_zmora_trophy') { $vAb = $vAb -replace '^spriggan_trophy_stats$', 'zmora_trophy_stats' }
        if (($vAb -join ',') -ne ($oAb -join ',')) { Fail "$name abilities differ from vanilla: $($oAb -join ',')" }
    }
}
foreach ($n in $descByItem.Keys) { if (-not $vanillaItems.ContainsKey($n)) { Fail "flavour text for unknown item '$n'" } }

# ---------------------------------------------------------------- 9. trophy fusion
"`n[9] trophy fusion"
$fusion = Import-PowerShellDataFile (Join-Path $root 'fusion-table.psd1')
$fusionRow = @{}; foreach ($t in $fusion.Trophies) { if ($fusionRow.ContainsKey($t.Item)) { Fail "fusion table lists $($t.Item) twice" }; $fusionRow[$t.Item] = $t }
foreach ($n in $vanillaItems.Keys) { if (-not $fusionRow.ContainsKey($n) -and $n -ne 'q602_pig_contest_trophy') { Fail "fusion table has no class for $n" } }
# vanilla mutagen ingredients (name -> colour), for binder validation
$mutagenColour = @{}
foreach ($f in 'gameplay\items\def_item_ingredients.xml', 'dlc\bob\data\gameplay\items\def_item_ingredients.xml') {
    [xml]$doc = [regex]::Replace([System.IO.File]::ReadAllText((Join-Path $van $f)), '(?s)<!--.*?-->', '')
    foreach ($it in $doc.redxml.definitions.items.item) {
        if (("$($it.tags)" -replace '\s', '') -notmatch 'MutagenIngredient') { continue }
        $col = @($it.base_abilities.a | ForEach-Object { "$_".Trim() } | Where-Object { $_ -match 'mutagen_color_(red|green|blue)' } | ForEach-Object { $Matches[1] })[0]
        $mutagenColour[$it.name.Trim()] = $col
    }
}
foreach ($t in $fusion.Trophies) {
    if ($t.Mutagen -and -not $mutagenColour.ContainsKey($t.Mutagen)) { Fail "$($t.Item): binder '$($t.Mutagen)' is not a vanilla mutagen ingredient" }
    elseif ($t.Mutagen -and $mutagenColour[$t.Mutagen] -ne $t.Colour) { Fail "$($t.Item): colour '$($t.Colour)' does not match its mutagen's colour '$($mutagenColour[$t.Mutagen])'" }
}
foreach ($c in 'red', 'green', 'blue') { $g = $fusion.GenericMutagens[$c]; if ($mutagenColour[$g] -ne $c) { Fail "generic binder '$g' is not a vanilla $c mutagen" } }
$fusedItems = @($ours.redxml.definitions.items.item | Where-Object { $_.name.Trim() -like 'soth_fused_*' })
$recipes = @($ours.redxml.custom.alchemy_recipes.recipe)
$recipeNames = @{}; foreach ($r in $recipes) { if ($recipeNames.ContainsKey($r.name_name)) { Fail "duplicate recipe $($r.name_name)" }; $recipeNames[$r.name_name] = $r }
$fusionScript = Get-Content (Join-Path $root 'src\scripts\local\modSpoilsOfTheHunt_fusion.ws') -Raw
$classAttrOf = { param($token) if ($token -eq 'Troll') { 'vsOgre_attack_power' } else { "vs${token}_attack_power" } }
$expectedPairs = 0
$byClass = @{}; foreach ($t in $fusion.Trophies) { if (-not $byClass.ContainsKey($t.Class)) { $byClass[$t.Class] = @() }; $byClass[$t.Class] += @($t) }
foreach ($class in $byClass.Keys) { $n = $byClass[$class].Count; $expectedPairs += $n * ($n - 1) / 2 }
if ($fusedItems.Count -ne $expectedPairs) { Fail "expected $expectedPairs fused items (one per same-class pair), found $($fusedItems.Count)" } else { Pass "$expectedPairs fused items, one per same-class pair" }
foreach ($fi in $fusedItems) {
    $iname = $fi.name.Trim()
    $ab = @($fi.base_abilities.a | ForEach-Object { "$_".Trim() })
    $statsName = $ab | Where-Object { $_ -ne 'base_trophy_stats' }
    if ($ab.Count -ne 2 -or -not $ourAbilities.ContainsKey($statsName)) { Fail "${iname}: abilities should be its fused stats + base_trophy_stats"; continue }
    $its = @($recipes | Where-Object { $_.cookedItem_name -eq $iname })
    if (-not $its) { Fail "$iname has no recipe"; continue }
    # every recipe for this item names the same two trophies plus one binder
    $ok = $true
    foreach ($r in $its) {
        $ing = @($r.ingredients.ingredient | ForEach-Object { $_.item_name })
        if ($ing.Count -ne 3) { Fail "$($r.name_name): expected 3 ingredients"; $ok = $false; continue }
        $a = $fusionRow[$ing[0]]; $b = $fusionRow[$ing[1]]
        if (-not $a -or -not $b) { Fail "$($r.name_name): ingredient trophies not in the fusion table"; $ok = $false; continue }
        if ($a.Class -ne $b.Class) { Fail "$($r.name_name): $($a.Item) ($($a.Class)) and $($b.Item) ($($b.Class)) are not the same class"; $ok = $false }
        $binder = $ing[2]
        $allowed = @($a.Mutagen, $b.Mutagen, $fusion.GenericMutagens[$a.Colour], $fusion.GenericMutagens[$b.Colour]) | Where-Object { $_ }
        if ($binder -notin $allowed) { Fail "$($r.name_name): binder '$binder' is not allowed for this pair"; $ok = $false }
        # "trophy" is not a vanilla type: the loader maps it to EACIT_Undefined, whose group name and label our
        # alchemygroup script replaces with the Trophies group
        if ($r.cookedItemType -ne 'trophy') { Fail "$($r.name_name): cookedItemType must be trophy (the Trophies group)"; $ok = $false }
        if ($fusionScript -notmatch "itemA\.PushBack\('$([regex]::Escape($ing[0]))'\); itemB\.PushBack\('$([regex]::Escape($ing[1]))'\); recipe\.PushBack\('$([regex]::Escape($r.name_name))'\);") { Fail "$($r.name_name) is missing from the recipe-teaching script"; $ok = $false }
        # the class line follows the rule: 5% + the better of the two (trait-only = 5%), capped at 20%
        $classAttr = & $classAttrOf $a.Class
        $statsA = @($vanillaItems[$a.Item].base_abilities.a | ForEach-Object { "$_".Trim() } | Where-Object { $_ -ne 'base_trophy_stats' })[0]
        if ($a.Item -eq 'mq7017_zmora_trophy') { $statsA = 'zmora_trophy_stats' }
        $statsB = @($vanillaItems[$b.Item].base_abilities.a | ForEach-Object { "$_".Trim() } | Where-Object { $_ -ne 'base_trophy_stats' })[0]
        if ($b.Item -eq 'mq7017_zmora_trophy') { $statsB = 'zmora_trophy_stats' }
        $srcA = $ourAbilities[$statsA]; $srcB = $ourAbilities[$statsB]
        # class line only when a source has one: 5% + the better of the two, capped at 20%; else none
        $la = [double](($srcA | Where-Object { $_.Name -eq $classAttr }).Min + 0)
        $lb = [double](($srcB | Where-Object { $_.Name -eq $classAttr }).Min + 0)
        $want = if ($la -gt 0 -or $lb -gt 0) { [Math]::Min(0.20, [Math]::Round(0.05 + [Math]::Max($la, $lb), 2)) } else { 0 }
        $got = [double](($ourAbilities[$statsName] | Where-Object { $_.Name -eq $classAttr }).Min + 0)
        if ($got -ne $want) { Fail "${iname}: class line $got, rule says $want"; $ok = $false }
        $sourceAttrs = @($srcA | ForEach-Object { $_.Name }) + @($srcB | ForEach-Object { $_.Name })
        foreach ($attr in $ourAbilities[$statsName]) { if ($attr.Name -ne $classAttr -and $attr.Name -notin $sourceAttrs) { Fail "${iname}: bonus $($attr.Name) comes from neither source trophy"; $ok = $false } }
        foreach ($attr in $ourAbilities[$statsName]) { if ($attr.Name -ne $classAttr -and [double]$attr.Min -gt 0.20) { Fail "${iname}: trait $($attr.Name) = $($attr.Min) exceeds 0.20"; $ok = $false } }
        if (($fi.localisation_key_name.Trim() -ne "item_name_soth_fused_$($a.Class.ToLower())") -or -not $ourKeys.Contains((KeyHash $fi.localisation_key_name.Trim())) -or -not $ourKeys.Contains((KeyHash $fi.localisation_key_description.Trim()))) { Fail "${iname}: class name/description strings missing"; $ok = $false }
        if ($fi.equip_template.Trim() -ne $vanillaItems[$a.Item].equip_template.Trim()) { Fail "${iname}: should hang the first trophy's mesh"; $ok = $false }
    }
    if ($ok) { Pass "${iname}: $($its.Count) recipes, class line $got" }
}
$groupScript = Get-Content (Join-Path $root 'src\scripts\local\modSpoilsOfTheHunt_alchemygroup.ws') -Raw
if ($groupScript -match "@replaceMethod\s*\n\s*function AlchemyCookedItemTypeEnumToName" -and $groupScript -match "default\s*:\s*return 'trophy';" -and
    $groupScript -match "@replaceMethod\s*\n\s*function AlchemyCookedItemTypeToLocKey" -and $groupScript -match 'default\s*:\s*return "panel_alchemy_tab_trophies";' -and
    $ourKeys.Contains((KeyHash 'panel_alchemy_tab_trophies'))) { Pass 'Trophies group: both type-mapping functions replaced and the label string exists' }
else { Fail 'Trophies group: alchemygroup script or its label string is wrong'

}
Pass "$($recipes.Count) fusion recipes checked"

# ---------------------------------------------------------------- summary
"`n$passes checks passed, $($fails.Count) failed"
if ($fails.Count) { $fails | ForEach-Object { "  - $_" }; exit 1 }
exit 0   # explicit, so the caller's $LASTEXITCODE is never stale
