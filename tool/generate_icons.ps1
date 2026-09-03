$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot

# Rasterize the same simple vector geometry as assets/app-icon.svg.
function Write-AppIcon([int]$size, [string]$relativePath) {
    $bitmap = [System.Drawing.Bitmap]::new($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#0878ff'))
    $graphics.ScaleTransform($size / 1024.0, $size / 1024.0)
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $path.StartFigure()
    $path.AddLine(492, 734, 532, 734)
    $path.AddLine(532, 734, 532, 486)
    $path.AddBezier(532, 486, 682, 486, 758, 396, 758, 244)
    $path.AddBezier(758, 244, 609, 244, 523, 313, 512, 455)
    $path.AddBezier(512, 455, 501, 313, 415, 244, 266, 244)
    $path.AddBezier(266, 244, 266, 396, 342, 486, 492, 486)
    $path.AddLine(492, 486, 492, 734)
    $path.CloseFigure()
    $graphics.FillPath([System.Drawing.Brushes]::White, $path)
    $graphics.FillRectangle([System.Drawing.Brushes]::White, 416, 718, 192, 34)
    $graphics.FillEllipse([System.Drawing.Brushes]::White, 399, 718, 34, 34)
    $graphics.FillEllipse([System.Drawing.Brushes]::White, 591, 718, 34, 34)
    $bitmap.Save((Join-Path $projectRoot $relativePath), [System.Drawing.Imaging.ImageFormat]::Png)
    $path.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

$androidSizes = @{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($entry in $androidSizes.GetEnumerator()) {
    Write-AppIcon $entry.Value "android/app/src/main/res/mipmap-$($entry.Key)/ic_launcher.png"
}
$iosPath = Join-Path $projectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$catalog = Get-Content -LiteralPath (Join-Path $iosPath 'Contents.json') -Raw | ConvertFrom-Json
foreach ($entry in $catalog.images) {
    $points = [double]($entry.size -split 'x')[0]
    $scale = [double]($entry.scale -replace 'x', '')
    Write-AppIcon ([int]($points * $scale)) "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($entry.filename)"
}
Write-AppIcon 32 'web/favicon.png'
Write-AppIcon 192 'web/icons/Icon-192.png'
Write-AppIcon 512 'web/icons/Icon-512.png'
Write-AppIcon 192 'web/icons/Icon-maskable-192.png'
Write-AppIcon 512 'web/icons/Icon-maskable-512.png'
