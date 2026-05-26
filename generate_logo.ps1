Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap 1024, 1024
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
$g.Clear([System.Drawing.Color]::White)

$fontU = New-Object System.Drawing.Font("Segoe UI", 550.0, [System.Drawing.FontStyle]::Bold)
$brushOrange = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 120, 0))
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment = [System.Drawing.StringAlignment]::Center

# Draw U
$rectU = New-Object System.Drawing.RectangleF(0, -50, 1024, 1024)
$g.DrawString("U", $fontU, $brushOrange, $rectU, $sf)

# Draw Badge
$badgeWidth = 460
$badgeHeight = 160
$badgeX = (1024 - $badgeWidth) / 2
$badgeY = 720
$badgeRect = New-Object System.Drawing.Rectangle($badgeX, $badgeY, $badgeWidth, $badgeHeight)
$brushDark = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 30, 30))

$g.FillRectangle($brushDark, $badgeRect)

# Draw NEO
$fontNeo = New-Object System.Drawing.Font("Segoe UI", 85.0, [System.Drawing.FontStyle]::Bold)
$brushWhite = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$badgeRectF = New-Object System.Drawing.RectangleF($badgeX, $badgeY, $badgeWidth, $badgeHeight)
$g.DrawString("NEO", $fontNeo, $brushWhite, $badgeRectF, $sf)

$bmp.Save("UntisPlus\assets\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
