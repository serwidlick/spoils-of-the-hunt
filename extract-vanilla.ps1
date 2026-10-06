# Rebuilds .\vanilla\ from the installed game. The build and its checks read these files; they are
# CD PROJEKT RED's and are not committed to the repository.
#
# Pulls from the game's bundles:
#   gameplay\items\def_item_trophies.xml (+ items_plus), the Hearts of Stone and Blood and Wine copies,
#   gameplay\globals\tooltip_settings.csv, and the DLC definition files (.reddlc) used as templates.
param([string]$GameDir = 'C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out = Join-Path $root 'vanilla'
$bundles = Join-Path $GameDir 'content\content0\bundles'
if (-not (Test-Path $bundles)) { throw "game bundles not found under $GameDir" }

# bundle path -> destination (relative to vanilla\); reddlc files go flat into vanilla\dlc-mounters\
$wanted = @{
    'gameplay\items\def_item_trophies.xml'                          = 'gameplay\items\def_item_trophies.xml'
    'gameplay\items_plus\def_item_trophies.xml'                     = 'gameplay\items_plus\def_item_trophies.xml'
    'dlc\ep1\data\gameplay\items\def_item_trophies.xml'             = 'dlc\ep1\data\gameplay\items\def_item_trophies.xml'
    'dlc\ep1\data\gameplay\items_plus\def_item_trophies.xml'        = 'dlc\ep1\data\gameplay\items_plus\def_item_trophies.xml'
    'dlc\bob\data\gameplay\items\def_item_trophies.xml'             = 'dlc\bob\data\gameplay\items\def_item_trophies.xml'
    'dlc\bob\data\gameplay\items_plus\def_item_trophies.xml'        = 'dlc\bob\data\gameplay\items_plus\def_item_trophies.xml'
    'gameplay\items\def_item_ingredients.xml'                       = 'gameplay\items\def_item_ingredients.xml'
    'dlc\bob\data\gameplay\items\def_item_ingredients.xml'          = 'dlc\bob\data\gameplay\items\def_item_ingredients.xml'
    'gameplay\items\def_item_alchemy_recipes_mutagens.xml'          = 'gameplay\items\def_item_alchemy_recipes_mutagens.xml'
    'gameplay\globals\tooltip_settings.csv'                         = 'gameplay\globals\tooltip_settings.csv'
}
foreach ($d in 1,2,5,8,10,11,13,14,18) { $wanted["dlc\dlc$d\dlc$d.reddlc"] = "dlc-mounters\dlc__dlc$d`__dlc$d.reddlc" }
$wanted['dlc\dlc11\off_dlc11.reddlc'] = 'dlc-mounters\dlc__dlc11__off_dlc11.reddlc'
$wanted['dlc\ep1\ep1.reddlc'] = 'dlc-mounters\dlc__ep1__ep1.reddlc'
$wanted['dlc\bob\bob.reddlc'] = 'dlc-mounters\dlc__bob__bob.reddlc'
$wanted['dlc\bob\activation_bob.reddlc'] = 'dlc-mounters\dlc__bob__activation_bob.reddlc'

$found = 0
foreach ($bundle in 'xml.bundle', 'ep1.bundle', 'bob.bundle', 'dlc0.bundle', 'startup.bundle') {
    $fs = [System.IO.File]::OpenRead((Join-Path $bundles $bundle)); $br = New-Object System.IO.BinaryReader($fs)
    # Remastered bundle (version 5): 32-byte header, TOC size at offset 16, 304-byte entries
    $fs.Seek(16, 'Begin') | Out-Null; $tocSize = $br.ReadUInt32(); $fs.Seek(32, 'Begin') | Out-Null
    $entries = @()
    while ($fs.Position -lt 32 + $tocSize) {
        $nb = $br.ReadBytes(256); $n = [System.Array]::IndexOf($nb, [byte]0); if ($n -lt 0) { $n = 256 }
        $name = [System.Text.Encoding]::ASCII.GetString($nb, 0, $n)
        $null = $br.ReadBytes(16); $off = $br.ReadUInt64(); $size = $br.ReadUInt32(); $zsize = $br.ReadUInt32(); $null = $br.ReadUInt32(); $comp = $br.ReadUInt32(); $null = $br.ReadBytes(8)
        if ($wanted.ContainsKey($name)) { $entries += [pscustomobject]@{ Name = $name; Offset = $off; ZSize = $zsize; Comp = $comp } }
    }
    foreach ($e in $entries) {
        $fs.Seek([int64]$e.Offset, 'Begin') | Out-Null; $raw = $br.ReadBytes($e.ZSize)
        if ($e.Comp -eq 1) { $ms = New-Object System.IO.MemoryStream(,$raw); $z = New-Object System.IO.Compression.ZLibStream($ms, [System.IO.Compression.CompressionMode]::Decompress); $o = New-Object System.IO.MemoryStream; $z.CopyTo($o); $raw = $o.ToArray() }
        elseif ($e.Comp -ne 0) { throw "unsupported compression $($e.Comp) for $($e.Name)" }
        $dest = Join-Path $out $wanted[$e.Name]
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        [System.IO.File]::WriteAllBytes($dest, $raw)
        "  $bundle : $($e.Name)"; $found++
    }
    $br.Close()
}
"extracted $found of $($wanted.Count) files into $out"
$missing = $wanted.Keys | Where-Object { -not (Test-Path (Join-Path $out $wanted[$_])) }
if ($missing) { Write-Warning "missing: $($missing -join ', ')" }
