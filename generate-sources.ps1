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
$items = New-Object System.Collections.Generic.List[string]
$redefined = @{}
foreach ($rel in 'gameplay\items\def_item_trophies.xml', 'dlc\ep1\data\gameplay\items\def_item_trophies.xml', 'dlc\bob\data\gameplay\items\def_item_trophies.xml') {
    $text = [System.IO.File]::ReadAllText((Join-Path $van $rel))
    $text = [regex]::Replace($text, '(?s)<!--.*?-->', '')          # drop the commented-out werewolf trophy
    foreach ($m in [regex]::Matches($text, '(?s)<item\s[^>]*?>.*?</item>')) {
        $item = $m.Value
        if ($item -notmatch 'category\s*=\s*"trophy"') { continue }
        $name = [regex]::Match($item, '(?<![\w])name\s*=\s*"([^"]+)"').Groups[1].Value
        $changed = $false
        if ($item -match 'localisation_key_description\s*=\s*"item_desc_trophy"') {
            if (-not $descByItem.Contains($name)) { throw "no flavour text for '$name' in trophy-text.psd1" }
            $item = $item -replace 'localisation_key_description\s*=\s*"item_desc_trophy"', "localisation_key_description=`"item_desc_soth_$name`""
            $changed = $true
        }
        if ($name -eq 'mq7017_zmora_trophy') { $item = $item -replace 'spriggan_trophy_stats', 'zmora_trophy_stats'; $changed = $true }
        if (-not $changed) { continue }
        $item = $item -replace '^<item\s+', 'XITEMX '
        $item = $item -replace '^XITEMX ', '<item on_conflict="replace" '
        $item = ($item -split "`r?`n" | ForEach-Object { "`t`t`t" + $_.Trim() }) -join "`n"
        $items.Add($item)
        $redefined[$name] = $true
    }
}
foreach ($n in $descByItem.Keys) { if (-not $redefined.ContainsKey($n)) { throw "flavour text for '$n' matches no vanilla trophy with the shared description" } }
if (-not $redefined.ContainsKey('mq7017_zmora_trophy')) { throw 'zmora item not found in vanilla BaW file' }

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
[void]$sb.AppendLine("`t`t</abilities>")
[void]$sb.AppendLine("`t`t<items>")
foreach ($item in $items) { [void]$sb.AppendLine($item) }
[void]$sb.AppendLine("`t`t</items>")
[void]$sb.AppendLine("`t</definitions>")
[void]$sb.AppendLine('</redxml>')

New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
$text = $sb.ToString()
[xml]$text | Out-Null   # well-formedness check
[System.IO.File]::WriteAllText($dest, $text, (New-Object System.Text.UTF8Encoding $false))
"{0}  ({1} abilities, {2} items redefined, {3} with their own description)" -f $xmlRel, $abilities.Count, $items.Count, $descByItem.Count

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
