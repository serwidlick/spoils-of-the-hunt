# Builds the DLC definition file (.reddlc) that tells the game to load our XML overrides.
#
# A .reddlc is a CR2W binary. Remastered writes CR2W version 164, which WolvenKit 7 refuses,
# but the layout is identical to version 162 (verified by a byte-exact round trip), so we:
#   1. take a vanilla template (dlc13.reddlc), patch its version to 162,
#   2. edit it with WolvenKit's CR2W library (runs under Windows PowerShell 5.1 / .NET Framework),
#   3. patch the version back to 164 and recompute the header checksum.
param([Parameter(Mandatory)][string]$OutFile)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$wk = Join-Path $root 'tools\WolvenKit'
$template = Join-Path $root 'vanilla\dlc-mounters\dlc__dlc13__dlc13.reddlc'
$dlcId = 'dlc_spoilsofthehunt'
$xmlPath = 'dlc\dlcspoilsofthehunt\data\gameplay\items\lore_trophies.xml'

$inner = @'
param($Wk, $Template, $OutFile, $DlcId, $XmlPath)
Set-Location $Wk
[System.Reflection.Assembly]::LoadFrom("$Wk\WolvenKit.Common.dll") | Out-Null
[System.Reflection.Assembly]::LoadFrom("$Wk\WolvenKit.CR2W.dll") | Out-Null
$crcType = [AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object { try { $_.GetTypes() } catch { } } | Where-Object { $_.FullName -eq 'RED.CRC32.Crc32Algorithm' } | Select-Object -First 1
$crcCompute = $crcType.GetMethod('Compute', [type[]]@([byte[]]))
$enumType = [AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object { try { $_.GetTypes() } catch { } } | Where-Object { $_.Name -eq 'EChunkDisplayMode' } | Select-Object -First 1

function HeaderCrc([byte[]]$buf) {
    # CR2W header CRC32 over the fixed header + table headers (first 0xA0 bytes), with the crc
    # field itself replaced by the 0xDEADBEEF placeholder (the scheme WolvenKit reverse-engineered).
    [byte[]]$h = $buf[0..0x9f]; [BitConverter]::GetBytes([uint32]3735928559).CopyTo($h, 32)
    [uint32]$crcCompute.Invoke($null, [object[]]@(,$h))
}

$bytes = [System.IO.File]::ReadAllBytes($Template)
$origVersion = [BitConverter]::ToUInt32($bytes, 4)
$origCrc = [BitConverter]::ToUInt32($bytes, 32)
$check = HeaderCrc $bytes
if ($check -ne $origCrc) { throw ("header CRC scheme mismatch on template: computed 0x{0:x8}, file has 0x{1:x8}" -f $check, $origCrc) }
"template: CR2W v$origVersion, header crc verified"

$patched = $bytes.Clone(); [BitConverter]::GetBytes([uint32]162).CopyTo($patched, 4)
$f = ([WolvenKit.CR2W.CR2WFile].GetConstructors()[0]).Invoke(@($null))
$rc = $f.Read($patched); if ("$rc" -ne 'NoError') { throw "read failed: $rc" }

$def = $f.chunks[0].data
$def.Id.Value = $DlcId
$def.LocalizedNameKey.val = 'dlc_spoilsofthehunt_name'
$def.LocalizedDescriptionKey.val = 'dlc_spoilsofthehunt_desc'
$def.VisibleInDLCMenu.val = $false

# Keep chunk 1 (definitions mounter) and chunk 5 (NG+ definitions mounter); drop the rest.
$f.chunks[1].data.DefinitionXmlFilePath.val = $XmlPath
$f.chunks[5].data.DefinitionXmlFilePath.val = $XmlPath
$remove = New-Object 'System.Collections.Generic.List[WolvenKit.CR2W.CR2WExportWrapper]'
foreach ($i in 2, 3, 4, 6) { $remove.Add($f.chunks[$i]) }
$n = $f.RemoveChunks($remove, $false, [Enum]::Parse($enumType, 'Linear'), $true, $false, $null)
"removed $n chunks; remaining: $($f.chunks.Count)"

$ms = New-Object System.IO.MemoryStream; $bw = New-Object System.IO.BinaryWriter($ms); $f.Write($bw); $bw.Flush()
$out = $ms.ToArray()
[BitConverter]::GetBytes([uint32]$origVersion).CopyTo($out, 4)
[BitConverter]::GetBytes([uint32](HeaderCrc $out)).CopyTo($out, 32)
New-Item -ItemType Directory -Force (Split-Path $OutFile) | Out-Null
[System.IO.File]::WriteAllBytes($OutFile, $out)

# read back and report
$verify = $out.Clone(); [BitConverter]::GetBytes([uint32]162).CopyTo($verify, 4)
$g = ([WolvenKit.CR2W.CR2WFile].GetConstructors()[0]).Invoke(@($null)); $null = $g.Read($verify)
"wrote $OutFile ($($out.Length) bytes, CR2W v$origVersion)"
foreach ($c in $g.chunks) {
    $line = "  [$($c.ChunkIndex)] $($c.REDType)"
    $d = $c.data
    if ($d.PSObject.Properties['Id']) { $line += " id=" + $d.Id.Value }
    if ($d.PSObject.Properties['Mounters']) { $line += " mounters=" + $d.Mounters.Count }
    if ($d.PSObject.Properties['DefinitionXmlFilePath']) { $line += " xml=" + $d.DefinitionXmlFilePath.val }
    $line
}
'@
$innerPath = Join-Path $env:TEMP 'make-reddlc-inner.ps1'
[System.IO.File]::WriteAllText($innerPath, $inner)
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $innerPath -Wk $wk -Template $template -OutFile $OutFile -DlcId $dlcId -XmlPath $xmlPath
if ($LASTEXITCODE -ne 0) { throw 'make-reddlc failed' }
