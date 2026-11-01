Add-Type -AssemblyName System.Drawing

$rootDir = (Get-Location).Path
$screenshotsDir = Join-Path $rootDir "screenshots"
$jsonPath = Join-Path $screenshotsDir "captures.json"

if (-not [System.IO.File]::Exists($jsonPath)) {
    Write-Error "No se encontró $jsonPath"
    exit 1
}

$rawJson = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
$captures = $rawJson | ConvertFrom-Json

function Wrap-TerminalLines([string[]]$rawLines, [int]$maxChars = 96) {
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($raw in $rawLines) {
        if ($null -eq $raw) {
            $result.Add("")
            continue
        }
        $clean = $raw -replace "\x1B\[[0-9;]*[a-zA-Z]", ""
        $clean = $clean.Replace("🚀", "").Replace("✅", "[✓]").Replace("🔌", "[*]").Replace("📦", "[*]").Replace("👉", "->").Replace("🧹", "[*]")
        $clean = $clean.TrimEnd()
        if ($clean.Length -le $maxChars) {
            $result.Add($clean)
        } else {
            $pos = 0
            while ($pos -lt $clean.Length) {
                $len = [Math]::Min($maxChars, $clean.Length - $pos)
                $chunk = $clean.Substring($pos, $len)
                if ($pos -gt 0) {
                    $result.Add("  " + $chunk)
                } else {
                    $result.Add($chunk)
                }
                $pos += $len
            }
        }
    }
    return $result
}

function Render-TerminalImage([string]$fileName, [string]$windowTitle, [string[]]$rawLines) {
    $lines = Wrap-TerminalLines -rawLines $rawLines -maxChars 98

    $width = 960
    $titleBarHeight = 38
    $paddingTop = 18
    $paddingBottom = 22
    $paddingX = 20
    $lineHeight = 21

    $height = $titleBarHeight + $paddingTop + ($lines.Count * $lineHeight) + $paddingBottom
    if ($height -lt 200) { $height = 200 }

    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $bgTerminal = [System.Drawing.Color]::FromArgb(15, 23, 42)
    $bgTitleBar = [System.Drawing.Color]::FromArgb(30, 41, 59)
    $borderCol  = [System.Drawing.Color]::FromArgb(51, 65, 85)

    $brushBg = New-Object System.Drawing.SolidBrush($bgTerminal)
    $brushTitle = New-Object System.Drawing.SolidBrush($bgTitleBar)
    $penBorder = New-Object System.Drawing.Pen($borderCol, 2)

    $g.FillRectangle($brushBg, 0, 0, $width, $height)
    $g.FillRectangle($brushTitle, 0, 0, $width, $titleBarHeight)

    $bRed = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(239, 68, 68))
    $bYel = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 158, 11))
    $bGrn = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(16, 185, 129))
    $g.FillEllipse($bRed, 16, 13, 12, 12)
    $g.FillEllipse($bYel, 36, 13, 12, 12)
    $g.FillEllipse($bGrn, 56, 13, 12, 12)

    $fontTitle = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $fontMono  = New-Object System.Drawing.Font("Consolas", 10.0, [System.Drawing.FontStyle]::Regular)
    $fontMonoB = New-Object System.Drawing.Font("Consolas", 10.0, [System.Drawing.FontStyle]::Bold)

    $brushTitleText = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(226, 232, 240))
    $g.DrawString($windowTitle, $fontTitle, $brushTitleText, 82, 10)

    $cPrompt  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(56, 189, 248))
    $cCmd     = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(250, 204, 21))
    $cSuccess = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(74, 222, 128))
    $cError   = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(248, 113, 113))
    $cJson    = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(199, 210, 254))
    $cDefault = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(241, 245, 249))
    $cMuted   = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(148, 163, 184))

    $y = $titleBarHeight + $paddingTop
    foreach ($line in $lines) {
        if ($line.StartsWith("PS D:\")) {
            $idx = $line.IndexOf("> ")
            if ($idx -gt 0) {
                $promptPart = $line.Substring(0, $idx + 2)
                $cmdPart = $line.Substring($idx + 2)
                $g.DrawString($promptPart, $fontMonoB, $cPrompt, $paddingX, $y)
                $promptWidth = ($g.MeasureString($promptPart, $fontMonoB)).Width + 2
                $g.DrawString($cmdPart, $fontMonoB, $cCmd, $paddingX + $promptWidth, $y)
            } else {
                $g.DrawString($line, $fontMonoB, $cPrompt, $paddingX, $y)
            }
        }
        elseif ($line -match "\[✓\]|201 Created|200 OK|Started|Up |Servidor HTTP corriendo") {
            $g.DrawString($line, $fontMonoB, $cSuccess, $paddingX, $y)
        }
        elseif ($line -match "400 Bad Request|404 Not Found|❌|errors|obligatorio|positivo|negativo|no encontrado") {
            $g.DrawString($line, $fontMonoB, $cError, $paddingX, $y)
        }
        elseif ($line -match "^\s*[\{\}\[\]]" -or $line -match '^\s*"[^"]+":') {
            $g.DrawString($line, $fontMono, $cJson, $paddingX, $y)
        }
        elseif ($line -match "^(X-Powered-By|Content-Type|Date|Connection|Content-Length|ETag):") {
            $g.DrawString($line, $fontMono, $cMuted, $paddingX, $y)
        }
        else {
            $g.DrawString($line, $fontMono, $cDefault, $paddingX, $y)
        }
        $y += $lineHeight
    }

    $g.DrawRectangle($penBorder, 1, 1, $width - 2, $height - 2)

    $outFile = Join-Path $screenshotsDir "$fileName.png"
    $bmp.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)

    $g.Dispose()
    $bmp.Dispose()
    Write-Host "🖼️ Imagen generada: $outFile ($width x $height px)"
}

foreach ($prop in $captures.PSObject.Properties) {
    $key = $prop.Name
    $val = $prop.Value
    Render-TerminalImage -fileName $key -windowTitle $val.title -rawLines $val.lines
}

Write-Host "✅ Las 12 capturas PNG fueron generadas exitosamente."
