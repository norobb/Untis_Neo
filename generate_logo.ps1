Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap 1024, 1024
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

# Transparent background instead of white
$g.Clear([System.Drawing.Color]::Transparent)

# Draw U
$fontU = New-Object System.Drawing.Font("Segoe UI", 550.0, [System.Drawing.FontStyle]::Bold)
$brushOrange = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 120, 0))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center

# Center U
$rectU = New-Object System.Drawing.RectangleF(0, -60, 1024, 1024)
$g.DrawString("U", $fontU, $brushOrange, $rectU, $sf)

# Draw Badge (Rounded corners)
$badgeWidth = 460
$badgeHeight = 160
$badgeX = (1024 - $badgeWidth) / 2
$badgeY = 640 # Moved up slightly inside the U
$radius = 40

# Create GraphicsPath for rounded rectangle
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddArc($badgeX, $badgeY, ($radius * 2), ($radius * 2), 180, 90)
$path.AddArc(($badgeX + $badgeWidth - ($radius * 2)), $badgeY, ($radius * 2), ($radius * 2), 270, 90)
$path.AddArc(($badgeX + $badgeWidth - ($radius * 2)), ($badgeY + $badgeHeight - ($radius * 2)), ($radius * 2), ($radius * 2), 0, 90)
$path.AddArc($badgeX, ($badgeY + $badgeHeight - ($radius * 2)), ($radius * 2), ($radius * 2), 90, 90)
$path.CloseFigure()

$brushDark = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 30, 30))
$g.FillPath($brushDark, $path)

# Draw NEO
$fontNeo = New-Object System.Drawing.Font("Segoe UI", 85.0, [System.Drawing.FontStyle]::Bold)
$brushWhite = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$badgeRectF = New-Object System.Drawing.RectangleF($badgeX, $badgeY, $badgeWidth, $badgeHeight)
$g.DrawString("NEO", $fontNeo, $brushWhite, $badgeRectF, $sf)

# Save to the correct path relative to script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($scriptDir)) {
    $scriptDir = $PWD.Path
}
$savePath = Join-Path $scriptDir "assets\icon.png"

# Ensure assets directory exists
$assetsDir = Join-Path $scriptDir "assets"
if (-not (Test-Path $assetsDir)) {
    New-Item -ItemType Directory -Path $assetsDir | Out-Null
}

$bmp.Save($savePath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
$fontU.Dispose()
$fontNeo.Dispose()
$brushOrange.Dispose()
$brushDark.Dispose()
$brushWhite.Dispose()
$path.Dispose()
$sf.Dispose()
