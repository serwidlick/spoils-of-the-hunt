# Generates the mod's XML sources.
#
# Remastered (5.x) treats mod XML as additive: a DLC "definitions mounter" loads an XML
# whose entries may carry onConflict="replace" to override vanilla entries by name.
# Whole-file replacement of the vanilla def_item_trophies.xml (the pre-Remastered way)
# crashes the game at startup, so this writes one override XML instead.
#
# Re-run after editing the $abilities table below.

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$van  = Join-Path $root 'vanilla'
$dlcName = 'dlcspoilsofthehunt'                                  # lowercase: depot paths are case-insensitive but stored lowercase
$xmlRel  = "dlc\$dlcName\data\gameplay\items\lore_trophies.xml"
$dest    = Join-Path $root "src\dlc\$xmlRel"

function A($attr, $type, $val) { "`t`t`t`t<$attr type=`"$type`" min=`"$val`"/>" }

# Lore-friendly bonuses. "vs" bonuses use type=mult like oils do; resistances and
# flat chances use type=add, matching vanilla armor/weapon definitions.
$abilities = [ordered]@{
    # ---- base game ----
    'cave_troll_trophy_stats'      = @((A 'vsOgre_attack_power' 'mult' '0.05'), (A 'bludgeoning_resistance_perc' 'add' '0.05'))
    'nekkers_trophy_stats'         = @((A 'vsOgre_attack_power' 'mult' '0.05'))
    'nekker_warrior_trophy_stats'  = @((A 'vsOgre_attack_power' 'mult' '0.05'))
    'drowned_dead_trophy_stats'    = @((A 'vsNecrophage_attack_power' 'mult' '0.05'))
    'minion_trophy_stats'          = @((A 'frost_resistance_perc' 'add' '0.15'))          # Hound of the Wild Hunt
    'leshy_trophy_stats'           = @((A 'vsRelic_attack_power' 'mult' '0.10'))
    'leshy_mh302_trophy_stats'     = @((A 'vsRelic_attack_power' 'mult' '0.10'))
    'forktail_trophy_stats'        = @((A 'poison_resistance_perc' 'add' '0.15'))
    'wyvern_trophy_stats'          = @((A 'vsDraconide_attack_power' 'mult' '0.10'))
    'wyvern_mq1051_trophy_stats'   = @((A 'vsDraconide_attack_power' 'mult' '0.10'))
    'gravehag_trophy_stats'        = @((A 'vsNecrophage_attack_power' 'mult' '0.10'))
    'fogling_trophy_stats'         = @((A 'vsNecrophage_attack_power' 'mult' '0.05'))
    'fiend_trophy_stats'           = @((A 'vsRelic_attack_power' 'mult' '0.10'))
    'czart_trophy_stats'           = @((A 'bludgeoning_resistance_perc' 'add' '0.10'))   # Chort
    'wraith_trophy_stats'          = @((A 'vsSpecter_attack_power' 'mult' '0.10'))
    'lamia_trophy_stats'           = @((A 'vsHybrid_attack_power' 'mult' '0.05'))        # Ekhidna / siren
    'bies_trophy_stats'            = @((A 'vsRelic_attack_power' 'mult' '0.10'))
    'erynie_trophy_stats'          = @((A 'vsHybrid_attack_power' 'mult' '0.05'))
    'water_hag_trophy_stats'       = @((A 'poison_resistance_perc' 'add' '0.05'))
    'cockatrice_trophy_stats'      = @((A 'vsDraconide_attack_power' 'mult' '0.10'))
    'nightwraith_trophy_stats'     = @((A 'spell_power_yrden' 'mult' '0.10'))
    'ekimma_trophy_stats'          = @((A 'vsVampire_attack_power' 'mult' '0.10'))
    'arachas_trophy_stats'         = @((A 'poison_resistance_perc' 'add' '0.15'))
    'gryphon_trophy_stats'         = @((A 'vsHybrid_attack_power' 'mult' '0.10'))
    'gryphon_mh301_trophy_stats'   = @((A 'vsHybrid_attack_power' 'mult' '0.15'))        # Archgriffin
    'gryphon_sq108_trophy_stats'   = @((A 'vsHybrid_attack_power' 'mult' '0.10'))
    'succubus_trophy_stats'        = @((A 'spell_power_axii' 'mult' '0.10'))
    'katakan_trophy_stats'         = @((A 'vsVampire_attack_power' 'mult' '0.10'), (A 'critical_hit_chance' 'add' '0.05'))
    'dao_trophy_stats'             = @((A 'bludgeoning_resistance_perc' 'add' '0.15'))   # Earth elemental
    'doppler_trophy_stats'         = @((A 'bonus_money' 'add' '0.10'))                   # kept: the doppler is a thief
    'noonwraith_trophy_stats'      = @((A 'vsSpecter_attack_power' 'mult' '0.10'))
    'noonwraith_mh308_trophy_stats'= @((A 'vsSpecter_attack_power' 'mult' '0.10'))
    # ---- Hearts of Stone ----
    'pig_contest_trophy_stats'     = @((A 'bonus_money' 'add' '0.15'))                   # kept: it's a joke trophy
    'q603_sharley_trophy_stats'    = @((A 'bludgeoning_resistance_perc' 'add' '0.10'))
    # ---- Blood and Wine ----
    'cyclops_trophy_stats'         = @((A 'vsOgre_attack_power' 'mult' '0.10'), (A 'bludgeoning_resistance_perc' 'add' '0.05'))
    'wight_trophy_stats'           = @((A 'vsCursed_attack_power' 'mult' '0.10'))
    'garkain_trophy_stats'         = @((A 'vsVampire_attack_power' 'mult' '0.10'))
    'spriggan_trophy_stats'        = @((A 'vsRelic_attack_power' 'mult' '0.10'))
    'zmora_trophy_stats'           = @((A 'vsSpecter_attack_power' 'mult' '0.10'))       # new; night wraith of Toussaint
    'dracolizard_trophy_stats'     = @((A 'fire_resistance_perc' 'add' '0.15'))
    'white_basilisk_trophy_stats'  = @((A 'vsDraconide_attack_power' 'mult' '0.10'), (A 'poison_resistance_perc' 'add' '0.10'))
    'sharley_matriarch_trophy_stats'= @((A 'bludgeoning_resistance_perc' 'add' '0.15'))
    'camm_trophy_stats'            = @((A 'vsVampire_attack_power' 'mult' '0.15'))
}

# Every vanilla ability we override must exist in the vanilla files (typo guard).
$vanillaText = @(
    'gameplay\items\def_item_trophies.xml',
    'dlc\ep1\data\gameplay\items\def_item_trophies.xml',
    'dlc\bob\data\gameplay\items\def_item_trophies.xml'
) | ForEach-Object { [System.IO.File]::ReadAllText((Join-Path $van $_)) }
$vanillaAbilities = [regex]::Matches(($vanillaText -join "`n"), '<ability name="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
$newAbilities = @('zmora_trophy_stats')
foreach ($n in $abilities.Keys) { if ($n -notin $vanillaAbilities -and $n -notin $newAbilities) { throw "ability '$n' does not exist in vanilla" } }

# Item redefinitions, copied verbatim from vanilla and replaced by name:
#  - every trophy that shows vanilla's shared generic description gets its own (text in trophy-text.psd1);
#    the Blood and Wine trophies that already have a unique vanilla description are left alone.
#  - the Toussaint night wraith shared the spriggan's ability in vanilla; it gets its own.
$flavour = Import-PowerShellDataFile (Join-Path $root 'trophy-text.psd1')
$descByItem = [ordered]@{}
foreach ($pair in $flavour.Descriptions) { if ($descByItem.Contains($pair[0])) { throw "duplicate flavour text for $($pair[0])" }; $descByItem[$pair[0]] = $pair[1] }
$nameByItem = [ordered]@{}
foreach ($pair in $flavour.Names) { if ($nameByItem.Contains($pair[0])) { throw "duplicate name override for $($pair[0])" }; $nameByItem[$pair[0]] = $pair[1] }
$items = New-Object System.Collections.Generic.List[string]
$redefined = @{}
$trophyInfo = [ordered]@{}   # every vanilla trophy: its stats ability, saddle mesh, icon and price (fusion copies these)
foreach ($rel in 'gameplay\items\def_item_trophies.xml', 'dlc\ep1\data\gameplay\items\def_item_trophies.xml', 'dlc\bob\data\gameplay\items\def_item_trophies.xml') {
    $text = [System.IO.File]::ReadAllText((Join-Path $van $rel))
    $text = [regex]::Replace($text, '(?s)<!--.*?-->', '')          # drop the commented-out werewolf trophy
    foreach ($m in [regex]::Matches($text, '(?s)<item\s[^>]*?>.*?</item>')) {
        $item = $m.Value
        if ($item -notmatch 'category\s*=\s*"trophy"') { continue }
        $name = [regex]::Match($item, '(?<![\w])name\s*=\s*"([^"]+)"').Groups[1].Value
        $trophyInfo[$name] = @{
            Stats    = @([regex]::Matches($item, '<a>\s*([A-Za-z0-9_]+)\s*</a>') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -ne 'base_trophy_stats' })[0]
            Template = [regex]::Match($item, 'equip_template\s*=\s*"([^"]+)"').Groups[1].Value
            Icon     = [regex]::Match($item, 'icon_path\s*=\s*"([^"]+)"').Groups[1].Value
            Price    = [int][regex]::Match($item, '(?<![\w])price\s*=\s*"([0-9]+)"').Groups[1].Value
        }
        if ($name -eq 'mq7017_zmora_trophy') { $trophyInfo[$name].Stats = 'zmora_trophy_stats' }
        $changed = $false
        if ($item -match 'localisation_key_description\s*=\s*"item_desc_trophy"') {
            if (-not $descByItem.Contains($name)) { throw "no flavour text for '$name' in trophy-text.psd1" }
            $item = $item -replace 'localisation_key_description\s*=\s*"item_desc_trophy"', "localisation_key_description=`"item_desc_soth_$name`""
            $changed = $true
        }
        if ($name -eq 'mq7017_zmora_trophy') { $item = $item -replace 'spriggan_trophy_stats', 'zmora_trophy_stats'; $changed = $true }
        if ($nameByItem.Contains($name)) {
            if (-not $changed) { throw "name override for '$name': only redefined items can be renamed" }
            $item = $item -replace 'localisation_key_name\s*=\s*"[^"]+"', "localisation_key_name=`"item_name_soth_$name`""
        }
        if (-not $changed) { continue }
        $item = $item -replace '^<item\s+', 'XITEMX '
        $item = $item -replace '^XITEMX ', '<item on_conflict="replace" '
        $item = ($item -split "`r?`n" | ForEach-Object { "`t`t`t" + $_.Trim() }) -join "`n"
        $items.Add($item)
        $redefined[$name] = $true
    }
}
foreach ($n in $descByItem.Keys) { if (-not $redefined.ContainsKey($n)) { throw "flavour text for '$n' matches no vanilla trophy with the shared description" } }
foreach ($n in $nameByItem.Keys) { if (-not $redefined.ContainsKey($n)) { throw "name override for '$n' matches no redefined trophy" } }
if (-not $redefined.ContainsKey('mq7017_zmora_trophy')) { throw 'zmora item not found in vanilla BaW file' }

# ---- Trophy fusion (docs\fusion-design.md): per same-class pair, one fused ability, one fused item and one alchemy
# recipe per allowed binder. The fused trophy's bonuses are fixed in XML, so the tooltip and the attack script need
# nothing new. A generated script teaches the alchemy panel only the recipes whose two trophies Geralt holds.
$fusion = Import-PowerShellDataFile (Join-Path $root 'fusion-table.psd1')
function ParseAttrs($lines) { foreach ($l in $lines) { $m = [regex]::Match($l, '<(\w+) type="(\w+)" min="([0-9.]+)"/>'); [pscustomobject]@{ Name = $m.Groups[1].Value; Type = $m.Groups[2].Value; Value = [double]$m.Groups[3].Value } } }
function ClassAttr($token) { if ($token -eq 'Troll') { 'vsOgre_attack_power' } else { "vs${token}_attack_power" } }
function Short($item) { $item -replace '_trophy$', '' }
$fusedAbilities = [ordered]@{}
$fusedItems = New-Object System.Collections.Generic.List[string]
$fusedRecipes = New-Object System.Collections.Generic.List[string]
$fusionRows = New-Object System.Collections.Generic.List[object]   # (itemA, itemB, recipe) for the script
$byClass = [ordered]@{}
foreach ($t in $fusion.Trophies) {
    if (-not $trophyInfo.Contains($t.Item)) { throw "fusion table: '$($t.Item)' is not a vanilla trophy" }
    if (-not $fusion.Classes.ContainsKey($t.Class)) { throw "fusion table: unknown class '$($t.Class)' on $($t.Item)" }
    if (-not $fusion.GenericMutagens.ContainsKey($t.Colour)) { throw "fusion table: unknown colour '$($t.Colour)' on $($t.Item)" }
    if (-not $byClass.Contains($t.Class)) { $byClass[$t.Class] = New-Object System.Collections.Generic.List[object] }
    $byClass[$t.Class].Add($t)
}
foreach ($class in $byClass.Keys) {
    $list = $byClass[$class]
    $classAttr = ClassAttr $class
    for ($i = 0; $i -lt $list.Count; $i++) {
        for ($j = $i + 1; $j -lt $list.Count; $j++) {
            $a = $list[$i]; $b = $list[$j]
            $attrsA = @(ParseAttrs $abilities[$trophyInfo[$a.Item].Stats]); $attrsB = @(ParseAttrs $abilities[$trophyInfo[$b.Item].Stats])
            # class line: only if at least one source has one; then 5% + the better of the two, capped at 20%.
            # Two trait-only trophies (forktail + dracolizard) keep their traits and gain no class line.
            $lineA = [double](($attrsA | Where-Object { $_.Name -eq $classAttr } | ForEach-Object { $_.Value }) + 0)
            $lineB = [double](($attrsB | Where-Object { $_.Name -eq $classAttr } | ForEach-Object { $_.Value }) + 0)
            $classLine = if ($lineA -gt 0 -or $lineB -gt 0) { [Math]::Min(0.20, [Math]::Round(0.05 + [Math]::Max($lineA, $lineB), 2)) } else { 0 }
            # traits: both carry over; a shared trait becomes the higher one + 5%
            $traits = [ordered]@{}
            foreach ($attr in @($attrsA) + @($attrsB)) {
                if ($attr.Name -eq $classAttr) { continue }
                if ($traits.Contains($attr.Name)) { $traits[$attr.Name].Value = [Math]::Round([Math]::Max($traits[$attr.Name].Value, $attr.Value) + 0.05, 2) }
                else { $traits[$attr.Name] = [pscustomobject]@{ Type = $attr.Type; Value = $attr.Value } }
            }
            $short = "$(Short $a.Item)__$(Short $b.Item)"
            $abilityName = "soth_fused_${short}_stats"
            $lines = @()
            if ($classLine -gt 0) { $lines += (A $classAttr 'mult' ('{0:0.00}' -f $classLine)) }
            foreach ($k in $traits.Keys) { $lines += (A $k $traits[$k].Type ('{0:0.00}' -f $traits[$k].Value)) }
            if (-not $lines) { throw "fusion $short would have no bonuses at all" }
            $fusedAbilities[$abilityName] = $lines
            $itemName = "soth_fused_$short"
            $info = $trophyInfo[$a.Item]
            $fusedItems.Add(("`t`t`t<item name=`"$itemName`" category=`"trophy`" stackable=`"1`" equip_template=`"$($info.Template)`" ability_mode=`"OnMount`" grid_size=`"2`"`n" +
                             "`t`t`ticon_path=`"$($info.Icon)`" localisation_key_name=`"item_name_soth_fused_$($class.ToLower())`" localisation_key_description=`"item_desc_soth_fused_$($class.ToLower())`" price=`"$($info.Price + $trophyInfo[$b.Item].Price)`">`n" +
                             "`t`t`t`t<tags>Trophy,HorseTrophy,SpoilsOfTheHuntFused</tags>`n`t`t`t`t<base_abilities>`n`t`t`t`t`t<a>$abilityName</a>`n`t`t`t`t`t<a>base_trophy_stats</a>`n`t`t`t`t</base_abilities>`n`t`t`t</item>"))
            # binders: either trophy's own monster mutagen, or a normal-grade generic mutagen of either colour (deduplicated)
            $binders = @($a.Mutagen, $b.Mutagen, $fusion.GenericMutagens[$a.Colour], $fusion.GenericMutagens[$b.Colour]) | Where-Object { $_ } | Select-Object -Unique
            $k = 0
            foreach ($binder in $binders) {
                $k++
                $recipeName = "soth_fuse_${short}__$k"
                $fusedRecipes.Add(("`t`t`t<recipe name_name=`"$recipeName`" type_name=`"soth_fusion`" level=`"1`" cookedItem_name=`"$itemName`" cookedItemType=`"trophy`" cookedItemQuantity=`"1`" localisation_key_name=`"`">`n" +
                                   "`t`t`t`t<ingredients>`n`t`t`t`t`t<ingredient item_name=`"$($a.Item)`" quantity=`"1`"/>`n`t`t`t`t`t<ingredient item_name=`"$($b.Item)`" quantity=`"1`"/>`n`t`t`t`t`t<ingredient item_name=`"$binder`" quantity=`"1`"/>`n`t`t`t`t</ingredients>`n`t`t`t</recipe>"))
                # one row per recipe: WitcherScript has no string-to-name conversion, so names must be literals
                $fusionRows.Add([pscustomobject]@{ A = $a.Item; B = $b.Item; Recipe = $recipeName })
            }
        }
    }
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
[void]$sb.AppendLine('<!-- Witcher''s Trophies: lore-friendly saddle trophy bonuses. Generated by generate-sources.ps1 - do not edit by hand. -->')
[void]$sb.AppendLine('<redxml>')
[void]$sb.AppendLine("`t<definitions>")
[void]$sb.AppendLine("`t`t<abilities>")
foreach ($name in $abilities.Keys) {
    # The REDkit changelog spells it onConflict, but the engine binary parses on_conflict.
    $policy = if ($name -in $newAbilities) { '' } else { ' on_conflict="replace"' }
    [void]$sb.AppendLine("`t`t`t<ability name=`"$name`"$policy>")
    # The tag lets the attack-script patch read only trophy bonuses. Oils add their own ability
    # (tagged OilBonus) to the player too, so an untagged lookup would count an oil twice.
    [void]$sb.AppendLine("`t`t`t`t<tags>SpoilsOfTheHunt</tags>")
    foreach ($line in $abilities[$name]) { [void]$sb.AppendLine($line) }
    [void]$sb.AppendLine("`t`t`t</ability>")
}
foreach ($name in $fusedAbilities.Keys) {
    [void]$sb.AppendLine("`t`t`t<ability name=`"$name`">")
    [void]$sb.AppendLine("`t`t`t`t<tags>SpoilsOfTheHunt</tags>")
    foreach ($line in $fusedAbilities[$name]) { [void]$sb.AppendLine($line) }
    [void]$sb.AppendLine("`t`t`t</ability>")
}
[void]$sb.AppendLine("`t`t</abilities>")
[void]$sb.AppendLine("`t`t<items>")
foreach ($item in $items) { [void]$sb.AppendLine($item) }
foreach ($item in $fusedItems) { [void]$sb.AppendLine($item) }
[void]$sb.AppendLine("`t`t</items>")
[void]$sb.AppendLine("`t</definitions>")
[void]$sb.AppendLine("`t<custom>")
[void]$sb.AppendLine("`t`t<alchemy_recipes>")
foreach ($r in $fusedRecipes) { [void]$sb.AppendLine($r) }
[void]$sb.AppendLine("`t`t</alchemy_recipes>")
[void]$sb.AppendLine("`t</custom>")
[void]$sb.AppendLine('</redxml>')

New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
$text = $sb.ToString()
[xml]$text | Out-Null   # well-formedness check
[System.IO.File]::WriteAllText($dest, $text, (New-Object System.Text.UTF8Encoding $false))
"{0}  ({1} abilities, {2} items redefined, {3} with their own description; fusion: {4} pairs, {5} recipes)" -f $xmlRel, $abilities.Count, $items.Count, $descByItem.Count, $fusedItems.Count, $fusedRecipes.Count

# The recipe-teaching script. The alchemy panel lists every recipe Geralt knows, and ~250 fusion recipes would bury
# it, so the manager is taught only the pairs he currently holds, each time the panel opens. Nothing touches the save.
$wsRel = 'src\scripts\local\modSpoilsOfTheHunt_fusion.ws'
$ws = New-Object System.Text.StringBuilder
[void]$ws.AppendLine('// Spoils of the Hunt: trophy fusion recipes. Generated by generate-sources.ps1 - do not edit by hand.')
[void]$ws.AppendLine('// Teaches the alchemy manager only the fusion recipes whose two trophies are in Geralt''s bags, so the')
[void]$ws.AppendLine('// panel stays short. The recipes themselves live in the DLC XML; nothing is written to the save.')
[void]$ws.AppendLine('@wrapMethod(W3AlchemyManager)')
[void]$ws.AppendLine('function Init(optional alchemyRecipes : array<name>)')
[void]$ws.AppendLine('{')
[void]$ws.AppendLine("`tvar itemA, itemB, recipe, owned : array<name>;")
[void]$ws.AppendLine("`tvar i : int;")
[void]$ws.AppendLine('')
[void]$ws.AppendLine("`twrappedMethod(alchemyRecipes);")
# the table is split into small functions: the script compiler has a per-function size limit ("memory exhausted"
# at ~650 statements in one body)
$chunk = 24
$chunks = [Math]::Ceiling($fusionRows.Count / $chunk)
for ($c = 0; $c -lt $chunks; $c++) { [void]$ws.AppendLine("`tSOTH_FusionTable$($c + 1)(itemA, itemB, recipe);") }
[void]$ws.AppendLine("`tfor(i=0; i<recipe.Size(); i+=1)")
[void]$ws.AppendLine("`t{")
[void]$ws.AppendLine("`t`tif(thePlayer.inv.GetItemQuantityByName(itemA[i]) > 0 && thePlayer.inv.GetItemQuantityByName(itemB[i]) > 0)")
[void]$ws.AppendLine("`t`t`towned.PushBack(recipe[i]);")
[void]$ws.AppendLine("`t}")
[void]$ws.AppendLine("`tif(owned.Size() > 0)")
[void]$ws.AppendLine("`t`tLoadRecipesCustomXMLData(owned);")
[void]$ws.AppendLine('}')
for ($c = 0; $c -lt $chunks; $c++) {
    [void]$ws.AppendLine('')
    [void]$ws.AppendLine("function SOTH_FusionTable$($c + 1)(out itemA : array<name>, out itemB : array<name>, out recipe : array<name>)")
    [void]$ws.AppendLine('{')
    foreach ($row in ($fusionRows | Select-Object -Skip ($c * $chunk) -First $chunk)) { [void]$ws.AppendLine("`titemA.PushBack('$($row.A)'); itemB.PushBack('$($row.B)'); recipe.PushBack('$($row.Recipe)');") }
    [void]$ws.AppendLine('}')
}
[System.IO.File]::WriteAllText((Join-Path $root $wsRel), $ws.ToString(), (New-Object System.Text.UTF8Encoding $false))
"{0}  ({1} recipe rows in {2} table functions)" -f $wsRel, $fusionRows.Count, $chunks

# Tooltip table (a plain CSV, replaced whole via the Mods layer): the item tooltip only shows
# attributes listed here, and vanilla has no rows for percentage fire/frost resistance.
$csvRel = 'gameplay\globals\tooltip_settings.csv'
$csvDest = Join-Path $root "src\mod\$csvRel"
$csv = Get-Content (Join-Path $van $csvRel)
$outCsv = foreach ($line in $csv) {
    $line
    if ($line -like 'frost_resistance;*') {
        'fire_resistance_perc;BAADA0;TRUE;defence;0.4'
        'frost_resistance_perc;BAADA0;TRUE;defence;0.4'
    }
}
New-Item -ItemType Directory -Force (Split-Path $csvDest) | Out-Null
[System.IO.File]::WriteAllLines($csvDest, $outCsv, (New-Object System.Text.UTF8Encoding $false))
"{0}  ({1} rows, +2)" -f $csvRel, $outCsv.Count
