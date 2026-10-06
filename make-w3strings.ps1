# Writes the mod's localisation tables (<lang>.w3strings) for game version 5.x.
#
# Format (as found in the 5.0 game files; ported from the Simple Loadout System's w3strings.py):
#   "RTSW"  u32 version=164 (UTF-8 text)  u16 key1
#   bit6 count, entries {u32 id, u32 offset, u32 length}      offset/length in bytes
#   bit6 count, keys    {u32 hash, u32 id}                     SORTED BY HASH (the game binary-searches it)
#   bit6 byte count, text buffer: each string UTF-8 + NUL
#   u16 key2
# key1/key2 = 0 means unobfuscated text. Key hash = Java String.hashCode over UTF-16 units of the lower-cased key.
# Mod string ids live in the 2110000000+ range by community convention.
param([Parameter(Mandatory)][string]$OutDir)
$ErrorActionPreference = 'Stop'

$base = 2117650000
$strings = @(
    # key                                   text
    @('attribute_name_fire_resistance_perc',  'Fire resistance'),
    @('attribute_name_frost_resistance_perc', 'Frost resistance'),
    @('dlc_spoilsofthehunt_name',                "Spoils of the Hunt"),
    @('dlc_spoilsofthehunt_desc',                'Lore-friendly saddle trophy bonuses.')
)
# English text is shipped for every language the game supports, so no language sees raw #keys.
$languages = 'en','ar','br','cn','cz','de','es','esmx','fr','hu','it','jp','kr','pl','ru','tr','ua','zh'

function KeyHash([string]$key) {
    [long]$h = 0
    foreach ($c in $key.ToLowerInvariant().ToCharArray()) { $h = ($h * 31 + [int]$c) -band 0xFFFFFFFFL }
    [uint32]$h
}
function Bit6([int]$v) {
    $out = New-Object System.Collections.Generic.List[byte]
    $first = [byte]($v -band 0x3F); $v = $v -shr 6
    if ($v) { $first = $first -bor 0x40 }
    $out.Add($first)
    while ($v) { $b = [byte]($v -band 0x7F); $v = $v -shr 7; if ($v) { $b = $b -bor 0x80 }; $out.Add($b) }
    ,$out.ToArray()
}

$rows = for ($i = 0; $i -lt $strings.Count; $i++) { [pscustomobject]@{ Id = [uint32]($base + $i); Key = $strings[$i][0]; Text = $strings[$i][1]; Hash = (KeyHash $strings[$i][0]) } }
$utf8 = New-Object System.Text.UTF8Encoding $false
$buf = New-Object System.IO.MemoryStream
$entries = New-Object System.IO.MemoryStream; $ew = New-Object System.IO.BinaryWriter($entries)
foreach ($r in ($rows | Sort-Object Id)) {
    $data = $utf8.GetBytes($r.Text)
    $ew.Write([uint32]$r.Id); $ew.Write([uint32]$buf.Length); $ew.Write([uint32]$data.Length)
    $buf.Write($data, 0, $data.Length); $buf.WriteByte(0)
}
$keys = New-Object System.IO.MemoryStream; $kw = New-Object System.IO.BinaryWriter($keys)
foreach ($r in ($rows | Sort-Object Hash)) { $kw.Write([uint32]$r.Hash); $kw.Write([uint32]$r.Id) }
$ew.Flush(); $kw.Flush()

$out = New-Object System.IO.MemoryStream; $w = New-Object System.IO.BinaryWriter($out)
$w.Write([System.Text.Encoding]::ASCII.GetBytes('RTSW')); $w.Write([uint32]164); $w.Write([uint16]0)
$c = Bit6 $rows.Count; $w.Write($c); $w.Write($entries.ToArray())
$c = Bit6 $rows.Count; $w.Write($c); $w.Write($keys.ToArray())
$c = Bit6 ([int]$buf.Length); $w.Write($c); $w.Write($buf.ToArray())
$w.Write([uint16]0); $w.Flush()
$bytes = $out.ToArray()

New-Item -ItemType Directory -Force $OutDir | Out-Null
foreach ($lang in $languages) { [System.IO.File]::WriteAllBytes((Join-Path $OutDir "$lang.w3strings"), $bytes) }
"wrote $($rows.Count) strings x $($languages.Count) languages ($($bytes.Length) bytes each) -> $OutDir"
foreach ($r in $rows) { '  {0}  0x{1:x8}  {2} = "{3}"' -f $r.Id, $r.Hash, $r.Key, $r.Text }
