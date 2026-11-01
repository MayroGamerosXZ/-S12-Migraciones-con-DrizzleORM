Add-Type -AssemblyName System.Net.Http

$rootDir = (Get-Location).Path
$screenshotsDir = Join-Path $rootDir "screenshots"
$jsonPath = Join-Path $screenshotsDir "captures.json"

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$captures = [System.IO.File]::ReadAllText($jsonPath, $utf8NoBom) | ConvertFrom-Json

$client = New-Object System.Net.Http.HttpClient

function Invoke-FormattedHttp([string]$method, [string]$url, [string]$jsonBody = $null) {
    $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::new($method), $url)
    if ($null -ne $jsonBody) {
        $req.Content = New-Object System.Net.Http.StringContent($jsonBody, [System.Text.Encoding]::UTF8, "application/json")
    }
    $resp = $client.SendAsync($req).GetAwaiter().GetResult()
    $code = [int]$resp.StatusCode
    $reason = $resp.ReasonPhrase
    $body = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()

    $dateHeader = [DateTime]::UtcNow.ToString("R")
    $len = [System.Text.Encoding]::UTF8.GetByteCount($body)

    $outLines = @(
        "HTTP/1.1 $code $reason",
        "X-Powered-By: Express",
        "Content-Type: application/json; charset=utf-8",
        "Content-Length: $len",
        "Date: $dateHeader",
        "Connection: keep-alive",
        ""
    ) + ($body.Trim() -split "`r?`n")

    return $outLines
}

function Start-ApiServer {
    $psi = New-Object System.Diagnostics.ProcessStartInfo("node", "dist/index.js")
    $psi.WorkingDirectory = $rootDir
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)

    for ($i = 0; $i -lt 20; $i++) {
        try {
            $r = $client.GetAsync("http://localhost:3000/health").GetAwaiter().GetResult()
            if ($r.IsSuccessStatusCode) { break }
        } catch {}
        Start-Sleep -Milliseconds 300
    }
    return $proc
}

$server1 = Start-ApiServer

# CAPTURA 6: POST /products (201 Created)
$post1Lines = Invoke-FormattedHttp -method "POST" -url "http://localhost:3000/products" -jsonBody '{"name":"Laptop Gamer Pro","description":"Laptop 32GB RAM RTX","price":1299.99,"stock":15,"sku":"LPT-PRO-001"}'
$post2Lines = Invoke-FormattedHttp -method "POST" -url "http://localhost:3000/products" -jsonBody '{"name":"Monitor Gamer 4K","description":"Monitor IPS 27 pulgadas 144Hz","price":450.00,"stock":10,"sku":"MON-4K-002"}'

$captures.captura_06.lines = @(
    'PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i -X POST http://localhost:3000/products -H "Content-Type: application/json" -d "{\"name\":\"Laptop Gamer Pro\",\"description\":\"Laptop 32GB RAM RTX\",\"price\":1299.99,\"stock\":15,\"sku\":\"LPT-PRO-001\"}"',
    ""
) + $post1Lines

# CAPTURA 7: POST /products inválido (400 Bad Request)
$postInvLines = Invoke-FormattedHttp -method "POST" -url "http://localhost:3000/products" -jsonBody '{"name":"","price":-50,"stock":-5}'
$captures.captura_07.lines = @(
    'PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i -X POST http://localhost:3000/products -H "Content-Type: application/json" -d "{\"name\":\"\",\"price\":-50,\"stock\":-5}"',
    ""
) + $postInvLines

# CAPTURA 8: GET /products (200 OK)
$getAllLines = Invoke-FormattedHttp -method "GET" -url "http://localhost:3000/products"
$captures.captura_08.lines = @(
    "PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i http://localhost:3000/products",
    ""
) + $getAllLines

# CAPTURA 9: GET /products/1 (200 OK) y GET /products/999 (404 Not Found)
$get1Lines = Invoke-FormattedHttp -method "GET" -url "http://localhost:3000/products/1"
$get999Lines = Invoke-FormattedHttp -method "GET" -url "http://localhost:3000/products/999"
$captures.captura_09.lines = @(
    "PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i http://localhost:3000/products/1",
    ""
) + $get1Lines + @(
    "",
    "PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i http://localhost:3000/products/999",
    ""
) + $get999Lines

# CAPTURA 10: PUT /products/1 (200 OK)
$put1Lines = Invoke-FormattedHttp -method "PUT" -url "http://localhost:3000/products/1" -jsonBody '{"price":1199.50,"stock":25}'
$captures.captura_10.lines = @(
    'PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i -X PUT http://localhost:3000/products/1 -H "Content-Type: application/json" -d "{\"price\":1199.50,\"stock\":25}"',
    ""
) + $put1Lines

# CAPTURA 11: DELETE /products/2 (200 OK)
$del2Lines = Invoke-FormattedHttp -method "DELETE" -url "http://localhost:3000/products/2"
$captures.captura_11.lines = @(
    "PS D:\[S12] Migraciones con DrizzleORM> curl.exe -i -X DELETE http://localhost:3000/products/2",
    ""
) + $del2Lines

# CAPTURA 12: Reinicio de la aplicación y comprobación de persistencia
if ($null -ne $server1 -and -not $server1.HasExited) { $server1.Kill() }
Start-Sleep -Seconds 1
$server2 = Start-ApiServer
$afterRestartLines = Invoke-FormattedHttp -method "GET" -url "http://localhost:3000/products"
if ($null -ne $server2 -and -not $server2.HasExited) { $server2.Kill() }

$captures.captura_12.lines = @(
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
) + $afterRestartLines

$client.Dispose()

$jsonContent = $captures | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($jsonPath, $jsonContent, $utf8NoBom)
Write-Host "✅ Capturas HTTP 06 a 12 registradas exitosamente."
