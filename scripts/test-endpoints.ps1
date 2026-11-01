# Script de prueba rápida para tomar evidencias de la API
$baseUrl = "http://localhost:3000/products"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "1. CREAR PRODUCTO EXITOSO (POST 201)" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
$p1 = @{
    name = "Teclado Mecanico RGB"
    description = "Switches Red silenciosos con layout en español"
    price = 89.99
    stock = 50
    sku = "KB-MECH-003"
} | ConvertTo-Json
$res1 = Invoke-RestMethod -Uri $baseUrl -Method Post -Body $p1 -ContentType "application/json"
$res1 | ConvertTo-Json

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "2. ERROR DE VALIDACION ZOD (POST 400 Bad Request)" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
try {
    $invalid = @{
        name = ""
        price = -25.50
        stock = -10
    } | ConvertTo-Json
    Invoke-RestMethod -Uri $baseUrl -Method Post -Body $invalid -ContentType "application/json"
} catch {
    Write-Host "Status Code: 400 Bad Request" -ForegroundColor Red
    $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    Write-Host $streamReader.ReadToEnd() -ForegroundColor Red
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "3. LISTAR TODOS LOS PRODUCTOS (GET 200)" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
$list = Invoke-RestMethod -Uri $baseUrl -Method Get
$list | ConvertTo-Json

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "4. CONSULTAR POR ID EXISTENTE (GET 200)" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
$idToGet = $res1.data.id
$getById = Invoke-RestMethod -Uri "$baseUrl/$idToGet" -Method Get
$getById | ConvertTo-Json

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "5. CONSULTAR POR ID INEXISTENTE (GET 404 Not Found)" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
try {
    Invoke-RestMethod -Uri "$baseUrl/99999" -Method Get
} catch {
    Write-Host "Status Code: 404 Not Found" -ForegroundColor Red
    $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    Write-Host $streamReader.ReadToEnd() -ForegroundColor Red
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "6. ACTUALIZAR PRODUCTO (PUT 200)" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
$updateBody = @{
    price = 79.99
    stock = 45
} | ConvertTo-Json
$updated = Invoke-RestMethod -Uri "$baseUrl/$idToGet" -Method Put -Body $updateBody -ContentType "application/json"
$updated | ConvertTo-Json

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "7. ELIMINAR PRODUCTO (DELETE 200)" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
$deleted = Invoke-RestMethod -Uri "$baseUrl/$idToGet" -Method Delete
$deleted | ConvertTo-Json
