# Format the supplied artwork as an uncompressed 32-bit TGA for the WoW client.
param([string]$Source = (Join-Path $PSScriptRoot '..\Media\Logo.png'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sourceImage = [System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $Source).Path)
$bitmap = [System.Drawing.Bitmap]::new(256, 256)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
try {
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($sourceImage, 0, 0, 256, 256)
    $target = Join-Path $PSScriptRoot '..\Media\Logo.tga'
    $stream = [System.IO.File]::Create($target)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        # BGRA, top-left origin, eight alpha bits, no compression.
        $writer.Write([byte[]]@(0,0,2,0,0,0,0,0,0,0,0,0,0,1,0,1,32,40))
        for ($y = 0; $y -lt 256; $y++) {
            for ($x = 0; $x -lt 256; $x++) {
                $pixel = $bitmap.GetPixel($x, $y)
                $writer.Write([byte[]]@($pixel.B, $pixel.G, $pixel.R, $pixel.A))
            }
        }
    } finally { $writer.Dispose(); $stream.Dispose() }
} finally { $graphics.Dispose(); $bitmap.Dispose(); $sourceImage.Dispose() }
