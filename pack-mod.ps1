# Packs a directory of already-cooked files into a legacy-format Witcher 3 container:
#   <Out>\content\blob0.bundle   (POTATO70 version 3, uncompressed)
#   <Out>\content\metadata.store (version 6, with directory tree and FNV-1a path hashes)
#
# The layout mirrors what wcc_lite produces and what the Remastered-compatible
# Witcher3FontTool writes, which is known to load on game version 5.x.
param(
    [Parameter(Mandatory)][string]$InputDir,
    [Parameter(Mandatory)][string]$OutDir
)
$ErrorActionPreference = 'Stop'
$latin1 = [System.Text.Encoding]::GetEncoding('ISO-8859-1')

$files = Get-ChildItem $InputDir -Recurse -File | Sort-Object FullName
if (-not $files) { throw "no files under $InputDir" }
$root = (Resolve-Path $InputDir).Path.TrimEnd('\') + '\'
$entries = foreach ($f in $files) {
    [pscustomobject]@{ Path = $f.FullName.Substring($root.Length).ToLowerInvariant(); Data = [System.IO.File]::ReadAllBytes($f.FullName) }
}

# ---------------------------------------------------------------- bundle (version 3)
$dataStart = 4096
$offsets = New-Object int[] $entries.Count
$length = $dataStart
for ($i = 0; $i -lt $entries.Count; $i++) { $offsets[$i] = $length; $length = ($length + $entries[$i].Data.Length + 15) -band -bnot 15 }

# standard CRC-32 (IEEE 802.3), as written by wcc_lite into bundle entries. All math in [long] to
# dodge PowerShell's unsigned-arithmetic quirks.
$crcTable = New-Object long[] 256
for ($i = 0; $i -lt 256; $i++) {
    [long]$c = $i
    for ($k = 0; $k -lt 8; $k++) { if ($c -band 1L) { $c = (($c -shr 1) -bxor 3988292384L) -band 4294967295L } else { $c = $c -shr 1 } }
    $crcTable[$i] = $c
}
function Crc32([byte[]]$bytes) {
    [long]$crc = 4294967295L
    foreach ($b in $bytes) { $crc = ($crcTable[($crc -bxor [long]$b) -band 255L] -bxor ($crc -shr 8)) -band 4294967295L }
    [uint32]($crc -bxor 4294967295L)
}

$content = Join-Path $OutDir 'content'
New-Item -ItemType Directory -Force $content | Out-Null
$bs = [System.IO.File]::Create((Join-Path $content 'blob0.bundle'))
$bw = New-Object System.IO.BinaryWriter($bs)
$bw.Write([System.Text.Encoding]::ASCII.GetBytes('POTATO70'))
$bw.Write([uint32]$length); $bw.Write([uint32]0); $bw.Write([uint32]($entries.Count * 320))
$bw.Write([uint32]0x00010003); $bw.Write([byte[]]@(0x00,0x13,0x13,0x13,0x13,0x13,0x13,0x13))
for ($i = 0; $i -lt $entries.Count; $i++) {
    $e = $entries[$i]
    $name = New-Object byte[] 256; $nb = $latin1.GetBytes($e.Path); [Array]::Copy($nb, $name, $nb.Length)
    $bw.Write($name)                       # 0x000 path
    $bw.Write((New-Object byte[] 16))      # 0x100 hash (unused by the game for mods)
    $bw.Write([uint32]0)                   # 0x110 empty
    $bw.Write([uint32]$e.Data.Length)      # 0x114 size
    $bw.Write([uint32]$e.Data.Length)      # 0x118 zsize (== size: uncompressed)
    $bw.Write([uint32]$offsets[$i])        # 0x11c offset
    $bw.Write((New-Object byte[] 24))      # 0x120 date, time, 16 zero bytes
    $bw.Write([uint32](Crc32 $e.Data))     # 0x138 crc32
    $bw.Write([uint32]0)                   # 0x13c compression = none
}
for ($i = 0; $i -lt $entries.Count; $i++) { $bs.Position = $offsets[$i]; $bw.Write($entries[$i].Data) }
$bs.SetLength($length); $bw.Flush(); $bw.Close()

# ---------------------------------------------------------------- metadata.store (version 6)
$strings = New-Object System.IO.MemoryStream
function AddStr([string]$s) { $at = [int]$strings.Position; $b = $latin1.GetBytes($s); $strings.Write($b, 0, $b.Length); $strings.WriteByte(0); $at }
function Vlq([System.IO.BinaryWriter]$w, [int]$n) {
    $w.Write([byte](($n -band 63) -bor $(if ($n -ge 64) { 64 } else { 0 }))); $n = $n -shr 6
    while ($n -gt 0) { $w.Write([byte](($n -band 127) -bor $(if ($n -ge 128) { 128 } else { 0 }))); $n = $n -shr 7 }
}
function Fnv1a64([string]$s) {
    $M = [System.Numerics.BigInteger]::Pow(2, 64); $h = [System.Numerics.BigInteger]::Parse('14695981039346656037')
    foreach ($c in $latin1.GetBytes($s.ToLowerInvariant())) { $h = $h -bxor [System.Numerics.BigInteger]$c; $h = ($h * 1099511628211) % $M }
    [uint64]$h
}

$null = AddStr ''                                   # offset 0: empty sentinel
$bundleNameOff = AddStr 'blob0.bundle'
$pathOffs = foreach ($e in $entries) { AddStr $e.Path }
# directory tree: index 0 = root (empty name, parent 0)
$dirNames = New-Object System.Collections.Generic.List[int]; $dirParents = New-Object System.Collections.Generic.List[int]
$dirIndex = @{}
$dirNames.Add((AddStr '')); $dirParents.Add(0); $dirIndex[''] = 0
$fileDir = New-Object int[] $entries.Count
for ($i = 0; $i -lt $entries.Count; $i++) {
    $parts = $entries[$i].Path.Split('\'); $cur = ''; $parent = 0
    for ($p = 0; $p -lt $parts.Length - 1; $p++) {
        $cur = if ($cur) { "$cur\$($parts[$p])" } else { $parts[$p] }
        if (-not $dirIndex.ContainsKey($cur)) { $dirIndex[$cur] = $dirNames.Count; $dirNames.Add((AddStr $parts[$p])); $dirParents.Add($parent) }
        $parent = $dirIndex[$cur]
    }
    $fileDir[$i] = $parent
}
$leafOffs = foreach ($e in $entries) { AddStr ($e.Path.Split('\')[-1]) }

$out = New-Object System.IO.MemoryStream; $w = New-Object System.IO.BinaryWriter($out)
$w.Write([byte[]]@(3, 0x56, 0x54, 0x4D)); $w.Write([int32]6)
$max = ($entries | Measure-Object { $_.Data.Length } -Maximum).Maximum
$w.Write([int32]$max); $w.Write([int32]$max)
Vlq $w ([int]$strings.Length); $w.Write($strings.ToArray())
# file infos: nameOff, pathHash, sizeInBundle, sizeInMemory, firstEntry, compression, bufferId, hasBuffer
Vlq $w ($entries.Count + 1); $w.Write((New-Object byte[] 24)); $w.Write([uint32]0x02100000); $w.Write([uint32]0)
for ($i = 0; $i -lt $entries.Count; $i++) {
    $w.Write([uint32]$pathOffs[$i]); $w.Write([uint32]0); $w.Write([uint32]$entries[$i].Data.Length); $w.Write([uint32]$entries[$i].Data.Length)
    $w.Write([uint32]($i + 1)); $w.Write([uint32]0); $w.Write([uint32]0); $w.Write([uint32]0)
}
# file entries: fileId, bundleId, offsetInBundle, sizeInBundle, nextEntry
Vlq $w ($entries.Count + 1); $w.Write((New-Object byte[] 20))
for ($i = 0; $i -lt $entries.Count; $i++) { $w.Write([uint32]($i + 1)); $w.Write([uint32]1); $w.Write([uint32]$offsets[$i]); $w.Write([uint32]$entries[$i].Data.Length); $w.Write([uint32]0) }
# bundle infos: name, firstFileEntry, numEntries, dataBlockSize, dataBlockOffset, burstDataBlockSize
Vlq $w 2; $w.Write((New-Object byte[] 24))
$indexEnd = 32 + 320 * $entries.Count
$w.Write([uint32]$bundleNameOff); $w.Write([uint32]1); $w.Write([uint32]$entries.Count); $w.Write([uint32]($length - $indexEnd)); $w.Write([uint32]$indexEnd); $w.Write([uint32]0)
# buffers (none)
Vlq $w 0
# dir init infos
Vlq $w $dirNames.Count
for ($i = 0; $i -lt $dirNames.Count; $i++) { $w.Write([int32]$dirNames[$i]); $w.Write([int32]$dirParents[$i]) }
# file init infos: fileId, dirId, nameOff
Vlq $w $entries.Count
for ($i = 0; $i -lt $entries.Count; $i++) { $w.Write([int32]($i + 1)); $w.Write([int32]$fileDir[$i]); $w.Write([int32]$leafOffs[$i]) }
# hashes: FNV-1a 64 of lowercased path -> fileId, ascending
Vlq $w $entries.Count
$rows = for ($i = 0; $i -lt $entries.Count; $i++) { [pscustomobject]@{ H = (Fnv1a64 $entries[$i].Path); Id = [int64]($i + 1) } }
foreach ($r in ($rows | Sort-Object H)) { $w.Write([uint64]$r.H); $w.Write([int64]$r.Id) }
$w.Flush()
[System.IO.File]::WriteAllBytes((Join-Path $content 'metadata.store'), $out.ToArray())

"packed $($entries.Count) files -> $content"
foreach ($e in $entries) { "  $($e.Path)  ($($e.Data.Length) bytes)" }
