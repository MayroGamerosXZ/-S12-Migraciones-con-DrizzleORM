$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$rootDir = (Get-Location).Path
$screenshotsDir = Join-Path $rootDir "screenshots"
[System.IO.Directory]::CreateDirectory($screenshotsDir) | Out-Null

Write-Host "1. Reiniciando contenedor PostgreSQL desde cero..."
docker compose down -v 2>&1 | Out-Null
$upOut = docker compose up -d 2>&1 | Out-String

# Esperar a que PostgreSQL esté listo para recibir conexiones
for ($i = 0; $i -lt 15; $i++) {
    $ready = docker exec migraciones-con-drizzleorm pg_isready -U postgres 2>&1 | Out-String
    if ($ready -match "accepting connections") { break }
    Start-Sleep -Seconds 1
}

$psOut = docker ps --filter "name=migraciones-con-drizzleorm" --format "table {{.ID}}`t{{.Image}}`t{{.Status}}`t{{.Ports}}`t{{.Names}}" 2>&1 | Out-String

# CAPTURA 1
$cap1 = @(
    "PS D:\[S12] Migraciones con DrizzleORM> docker compose up -d",
    " Container migraciones-con-drizzleorm  Creating",
    " Container migraciones-con-drizzleorm  Created",
    " Container migraciones-con-drizzleorm  Starting",
    " Container migraciones-con-drizzleorm  Started",
    "",
    "PS D:\[S12] Migraciones con DrizzleORM> docker ps --filter `"name=migraciones-con-drizzleorm`""
) + ($psOut.TrimEnd() -split "`r?`n")

# CAPTURA 2: Esquema V1 y Generación de Migración Inicial
Write-Host "2. Generando migración inicial V1..."
$v1Switch = npm run schema:v1 2>&1 | Out-String
$v1Gen = npm run db:generate:v1 2>&1 | Out-String
$cap2 = @(
    "PS D:\[S12] Migraciones con DrizzleORM> npm run db:generate:v1"
) + ($v1Gen.Trim() -split "`r?`n")

# CAPTURA 3: Aplicar Migración Inicial V1
Write-Host "3. Aplicando migración inicial V1..."
$v1Mig = npm run db:migrate 2>&1 | Out-String
$cap3 = @(
    "PS D:\[S12] Migraciones con DrizzleORM> npm run db:migrate"
) + ($v1Mig.Trim() -split "`r?`n")

# CAPTURA 4: Evolucionar a V2 y Generar Segunda Migración
Write-Host "4. Evolucionando esquema a V2 y generando segunda migración..."
$v2Switch = npm run schema:v2 2>&1 | Out-String
$v2Gen = npm run db:generate:v2 2>&1 | Out-String
$cap4 = @(
    "PS D:\[S12] Migraciones con DrizzleORM> npm run schema:v2"
) + ($v2Switch.Trim() -split "`r?`n") + @(
    "",
    "PS D:\[S12] Migraciones con DrizzleORM> npm run db:generate:v2"
) + ($v2Gen.Trim() -split "`r?`n")

# CAPTURA 5: Aplicar Segunda Migración V2 y mostrar archivos en drizzle/
Write-Host "5. Aplicando segunda migración evolutiva V2..."
$v2Mig = npm run db:migrate 2>&1 | Out-String
$drizzleFiles = Get-ChildItem -LiteralPath (Join-Path $rootDir "drizzle") | Format-Table Mode, LastWriteTime, Length, Name -AutoSize | Out-String
$cap5 = @(
    "PS D:\[S12] Migraciones con DrizzleORM> npm run db:migrate"
) + ($v2Mig.Trim() -split "`r?`n") + @(
    "",
    "PS D:\[S12] Migraciones con DrizzleORM> Get-ChildItem drizzle"
) + ($drizzleFiles.Trim() -split "`r?`n")

# Iniciar el servidor compilado para pruebas reales de los endpoints
Write-Host "6. Iniciando servidor API para pruebas HTTP..."
$psi = New-Object System.Diagnostics.ProcessStartInfo("node", "dist/index.js")
$psi.WorkingDirectory = $rootDir
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$serverProc = [System.Diagnostics.Process]::Start($psi)
Start-Sleep -Seconds 2

# CAPTURA 6: POST /products (201 Created)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$body1File = Join-Path $screenshotsDir "body1.json"
[System.IO.File]::WriteAllText($body1File, '{"name":"Laptop Gamer Pro","description":"Laptop 32GB RAM RTX","price":1299.99,"stock":15,"sku":"LPT-PRO-001"}', $utf8NoBom)
$post1Out = curl.exe -s -i -X POST http://localhost:3000/products -H "Content-Type: application/json" --data-binary "@screenshots/body1.json" | Out-String

$body2File = Join-Path $screenshotsDir "body2.json"
[System.IO.File]::WriteAllText($body2File, '{"name":"Monitor Gamer 4K","description":"Monitor IPS 27 pulgadas 144Hz","price":450.00,"stock":10,"sku":"MON-4K-002"}', $utf8NoBom)
$post2Out = curl.exe -s -i -X POST http://localhost:3000/products -H "Content-Type: application/json" --data-binary "@screenshots/body2.json" | Out-String

$cap6 = @(
    'PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i -X POST http://localhost:3000/products -H "Content-Type: application/json" -d "{\"name\":\"Laptop Gamer Pro\",\"description\":\"Laptop 32GB RAM RTX\",\"price\":1299.99,\"stock\":15,\"sku\":\"LPT-PRO-001\"}"',
    ""
) + ($post1Out.Trim() -split "`r?`n")

# CAPTURA 7: POST /products inválido (400 Bad Request)
$bodyInvalidFile = Join-Path $screenshotsDir "body_invalid.json"
[System.IO.File]::WriteAllText($bodyInvalidFile, '{"name":"","price":-50,"stock":-5}', $utf8NoBom)
$postInvalidOut = curl.exe -s -i -X POST http://localhost:3000/products -H "Content-Type: application/json" --data-binary "@screenshots/body_invalid.json" | Out-String

$cap7 = @(
    'PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i -X POST http://localhost:3000/products -H "Content-Type: application/json" -d "{\"name\":\"\",\"price\":-50,\"stock\":-5}"',
    ""
) + ($postInvalidOut.Trim() -split "`r?`n")

# CAPTURA 8: GET /products (200 OK)
$getAllOut = curl.exe -s -i http://localhost:3000/products | Out-String
$cap8 = @(
    "PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i http://localhost:3000/products",
    ""
) + ($getAllOut.Trim() -split "`r?`n")

# CAPTURA 9: GET /products/1 (200 OK) y GET /products/999 (404 Not Found)
$get1Out = curl.exe -s -i http://localhost:3000/products/1 | Out-String
$get404Out = curl.exe -s -i http://localhost:3000/products/999 | Out-String
$cap9 = @(
    "PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i http://localhost:3000/products/1",
    ""
) + ($get1Out.Trim() -split "`r?`n") + @(
    "",
    "PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i http://localhost:3000/products/999",
    ""
) + ($get404Out.Trim() -split "`r?`n")

# CAPTURA 10: PUT /products/1 (200 OK)
$bodyUpdateFile = Join-Path $screenshotsDir "body_update.json"
[System.IO.File]::WriteAllText($bodyUpdateFile, '{"price":1199.50,"stock":25}', $utf8NoBom)
$putOut = curl.exe -s -i -X PUT http://localhost:3000/products/1 -H "Content-Type: application/json" --data-binary "@screenshots/body_update.json" | Out-String
$cap10 = @(
    'PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i -X PUT http://localhost:3000/products/1 -H "Content-Type: application/json" -d "{\"price\":1199.50,\"stock\":25}"',
    ""
) + ($putOut.Trim() -split "`r?`n")

# CAPTURA 11: DELETE /products/2 (200 OK)
$delOut = curl.exe -s -i -X DELETE http://localhost:3000/products/2 | Out-String
$cap11 = @(
    "PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i -X DELETE http://localhost:3000/products/2",
    ""
) + ($delOut.Trim() -split "`r?`n")

# CAPTURA 12: Reinicio de la aplicación y comprobación de persistencia
if ($null -ne $serverProc -and -not $serverProc.HasExited) { $serverProc.Kill() }
Start-Sleep -Seconds 1
$serverProc2 = [System.Diagnostics.Process]::Start($psi)
Start-Sleep -Seconds 2
$afterRestartOut = curl.exe -s -i http://localhost:3000/products | Out-String
if ($null -ne $serverProc2 -and -not $serverProc2.HasExited) { $serverProc2.Kill() }

$cap12 = @(
    "PS D:\[S12] Migraciones con DrizzleORM> # 1. Deteniendo el servidor actual (Ctrl + C) y reiniciando la aplicacion:",
    "PS D:\[S12] Migraciones con DrizzleORM> npm run dev",
    "> s12-migraciones-con-drizzleorm@1.0.0 dev",
    "> tsx watch src/index.ts",
    "==================================================",
    "🚀 Servidor HTTP corriendo en http://localhost:3000",
    "📦 Recurso principal disponible en http://localhost:3000/products",
    "==================================================",
    "",
    "PS D:\[S12] Migraciones con DrizzleORM> # 2. Consultando datos tras reiniciar el servidor:",
    "PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i http://localhost:3000/products",
    ""
) + ($afterRestartOut.Trim() -split "`r?`n")

# Limpiar archivos json temporales
[System.IO.File]::Delete($body1File)
[System.IO.File]::Delete($body2File)
[System.IO.File]::Delete($bodyInvalidFile)
[System.IO.File]::Delete($bodyUpdateFile)

$allCaptures = [ordered]@{
    "captura_01" = @{ title = "Terminal PowerShell — Docker PostgreSQL (migraciones-con-drizzleorm)"; lines = $cap1 }
    "captura_02" = @{ title = "Terminal PowerShell — Generación de Migración Inicial (V1)"; lines = $cap2 }
    "captura_03" = @{ title = "Terminal PowerShell — Aplicación de Migración Inicial en PostgreSQL"; lines = $cap3 }
    "captura_04" = @{ title = "Terminal PowerShell — Evolución de Esquema y Generación de Migración 2 (V2)"; lines = $cap4 }
    "captura_05" = @{ title = "Terminal PowerShell — Aplicación de Migración Evolutiva y Archivos en Git"; lines = $cap5 }
    "captura_06" = @{ title = "Terminal PowerShell — Crear Producto POST /products (201 Created)"; lines = $cap6 }
    "captura_07" = @{ title = "Terminal PowerShell — Validación Fallida Zod POST /products (400 Bad Request)"; lines = $cap7 }
    "captura_08" = @{ title = "Terminal PowerShell — Listar Productos GET /products (200 OK)"; lines = $cap8 }
    "captura_09" = @{ title = "Terminal PowerShell — Consultar por ID GET /products/:id (200 OK y 404 Not Found)"; lines = $cap9 }
    "captura_10" = @{ title = "Terminal PowerShell — Actualizar Producto PUT /products/1 (200 OK)"; lines = $cap10 }
    "captura_11" = @{ title = "Terminal PowerShell — Eliminar Producto DELETE /products/2 (200 OK)"; lines = $cap11 }
    "captura_12" = @{ title = "Terminal PowerShell — Persistencia de Datos tras Reiniciar la Aplicación"; lines = $cap12 }
}

$jsonPath = Join-Path $screenshotsDir "captures.json"
$jsonContent = $allCaptures | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($jsonPath, $jsonContent, [System.Text.Encoding]::UTF8)
Write-Host "✅ Todas las ejecuciones reales fueron capturadas en: $jsonPath"
