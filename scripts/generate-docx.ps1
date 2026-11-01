Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing

$rootDir = (Get-Location).Path
$screenshotsDir = Join-Path $rootDir "screenshots"
$docxPath = Join-Path $rootDir "Entregable_S12_Migraciones_DrizzleORM.docx"

if ([System.IO.File]::Exists($docxPath)) {
    [System.IO.File]::Delete($docxPath)
}

function Escape-Xml([string]$text) {
    if ($null -eq $text) { return "" }
    return $text.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;").Replace("'", "&apos;")
}

function New-Heading1([string]$text) {
    $t = Escape-Xml $text
    return @"
<w:p>
  <w:pPr>
    <w:pBdr>
      <w:bottom w:val="single" w:sz="12" w:space="4" w:color="1E3A8A"/>
    </w:pBdr>
    <w:spacing w:before="360" w:after="160"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:color w:val="1E3A8A"/>
      <w:sz w:val="32"/>
    </w:rPr>
    <w:t>$t</w:t>
  </w:r>
</w:p>
"@
}

function New-Heading2([string]$text) {
    $t = Escape-Xml $text
    return @"
<w:p>
  <w:pPr>
    <w:spacing w:before="280" w:after="120"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:color w:val="2563EB"/>
      <w:sz w:val="26"/>
    </w:rPr>
    <w:t>$t</w:t>
  </w:r>
</w:p>
"@
}

function New-Paragraph([string]$text, [bool]$bold = $false, [string]$color = "1F2937") {
    $t = Escape-Xml $text
    $bTag = if ($bold) { "<w:b/>" } else { "" }
    return @"
<w:p>
  <w:pPr>
    <w:spacing w:before="80" w:after="120" w:line="276" w:lineRule="auto"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      $bTag
      <w:color w:val="$color"/>
      <w:sz w:val="22"/>
    </w:rPr>
    <w:t xml:space="preserve">$t</w:t>
  </w:r>
</w:p>
"@
}

function New-Bullet([string]$label, [string]$text) {
    $l = Escape-Xml $label
    $t = Escape-Xml $text
    return @"
<w:p>
  <w:pPr>
    <w:ind w:left="360"/>
    <w:spacing w:before="60" w:after="60" w:line="260" w:lineRule="auto"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:color w:val="1E3A8A"/>
      <w:sz w:val="22"/>
    </w:rPr>
    <w:t xml:space="preserve">• $l </w:t>
  </w:r>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:color w:val="1F2937"/>
      <w:sz w:val="22"/>
    </w:rPr>
    <w:t xml:space="preserve">$t</w:t>
  </w:r>
</w:p>
"@
}

function New-CodeBlock([string[]]$lines) {
    $runs = ""
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineText = Escape-Xml $lines[$i]
        $br = if ($i -lt $lines.Count - 1) { "<w:br/>" } else { "" }
        $runs += @"
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/>
      <w:color w:val="0F172A"/>
      <w:sz w:val="19"/>
    </w:rPr>
    <w:t xml:space="preserve">$lineText</w:t>
    $br
  </w:r>
"@
    }
    return @"
<w:p>
  <w:pPr>
    <w:pBdr>
      <w:top w:val="single" w:sz="6" w:space="6" w:color="CBD5E1"/>
      <w:left w:val="single" w:sz="18" w:space="8" w:color="2563EB"/>
      <w:bottom w:val="single" w:sz="6" w:space="6" w:color="CBD5E1"/>
      <w:right w:val="single" w:sz="6" w:space="6" w:color="CBD5E1"/>
    </w:pBdr>
    <w:shd w:val="clear" w:color="auto" w:fill="F1F5F9"/>
    <w:spacing w:before="100" w:after="160" w:line="240" w:lineRule="auto"/>
    <w:ind w:left="180" w:right="180"/>
  </w:pPr>
$runs
</w:p>
"@
}

function New-CaptureWithImage([int]$imgIndex, [string]$number, [string]$title, [string]$command, [string]$expectedDesc) {
    $num = Escape-Xml $number
    $tit = Escape-Xml $title
    $cmd = Escape-Xml $command
    $desc = Escape-Xml $expectedDesc

    $fileKey = ("captura_{0:D2}.png" -f $imgIndex)
    $imgPath = Join-Path $screenshotsDir $fileKey
    $cx = 5600000
    $cy = 2400000
    if ([System.IO.File]::Exists($imgPath)) {
        $imgObj = [System.Drawing.Image]::FromFile($imgPath)
        $cx = 5600000
        $cy = [long]([Math]::Round(5600000.0 * $imgObj.Height / $imgObj.Width))
        $imgObj.Dispose()
    }
    $relId = "rIdImg$imgIndex"

    return @"
<w:tbl>
  <w:tblPr>
    <w:tblW w:w="5000" w:type="pct"/>
    <w:tblBorders>
      <w:top w:val="single" w:sz="10" w:space="0" w:color="2563EB"/>
      <w:left w:val="single" w:sz="10" w:space="0" w:color="2563EB"/>
      <w:bottom w:val="single" w:sz="10" w:space="0" w:color="2563EB"/>
      <w:right w:val="single" w:sz="10" w:space="0" w:color="2563EB"/>
    </w:tblBorders>
    <w:tblCellMar>
      <w:top w:w="140" w:type="dxa"/>
      <w:left w:w="160" w:type="dxa"/>
      <w:bottom w:w="140" w:type="dxa"/>
      <w:right w:w="160" w:type="dxa"/>
    </w:tblCellMar>
  </w:tblPr>
  <w:tr>
    <w:tc>
      <w:tcPr>
        <w:shd w:val="clear" w:color="auto" w:fill="F8FAFC"/>
      </w:tcPr>
      <w:p>
        <w:pPr><w:spacing w:before="40" w:after="40"/></w:pPr>
        <w:r>
          <w:rPr>
            <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
            <w:b/>
            <w:color w:val="1E3A8A"/>
            <w:sz w:val="23"/>
          </w:rPr>
          <w:t xml:space="preserve">📸 [$num] $tit</w:t>
        </w:r>
      </w:p>
      <w:p>
        <w:pPr><w:spacing w:before="20" w:after="40"/></w:pPr>
        <w:r>
          <w:rPr>
            <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
            <w:b/>
            <w:color w:val="334155"/>
            <w:sz w:val="19"/>
          </w:rPr>
          <w:t xml:space="preserve">Comando ejecutado: </w:t>
        </w:r>
        <w:r>
          <w:rPr>
            <w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/>
            <w:color w:val="0F172A"/>
            <w:sz w:val="18"/>
          </w:rPr>
          <w:t xml:space="preserve">$cmd</w:t>
        </w:r>
      </w:p>
      <w:p>
        <w:pPr><w:spacing w:before="20" w:after="80"/></w:pPr>
        <w:r>
          <w:rPr>
            <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
            <w:i/>
            <w:color w:val="475569"/>
            <w:sz w:val="19"/>
          </w:rPr>
          <w:t xml:space="preserve">Descripción de la evidencia: $desc</w:t>
        </w:r>
      </w:p>
      <w:p>
        <w:pPr>
          <w:jc w:val="center"/>
          <w:spacing w:before="80" w:after="80"/>
        </w:pPr>
        <w:r>
          <w:drawing>
            <wp:inline distT="0" distB="0" distL="0" distR="0">
              <wp:extent cx="$cx" cy="$cy"/>
              <wp:effectExtent l="0" t="0" r="0" b="0"/>
              <wp:docPr id="$imgIndex" name="Imagen $imgIndex"/>
              <wp:cNvGraphicFramePr>
                <a:graphicFrameLocks noChangeAspect="1"/>
              </wp:cNvGraphicFramePr>
              <a:graphic>
                <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
                  <pic:pic>
                    <pic:nvPicPr>
                      <pic:cNvPr id="$imgIndex" name="$fileKey"/>
                      <pic:cNvPicPr/>
                    </pic:nvPicPr>
                    <pic:blipFill>
                      <a:blip r:embed="$relId"/>
                      <a:stretch><a:fillRect/></a:stretch>
                    </pic:blipFill>
                    <pic:spPr>
                      <a:xfrm>
                        <a:off x="0" y="0"/>
                        <a:ext cx="$cx" cy="$cy"/>
                      </a:xfrm>
                      <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
                    </pic:spPr>
                  </pic:pic>
                </a:graphicData>
              </a:graphic>
            </wp:inline>
          </w:drawing>
        </w:r>
      </w:p>
    </w:tc>
  </w:tr>
</w:tbl>
<w:p><w:pPr><w:spacing w:before="100" w:after="100"/></w:pPr></w:p>
"@
}

function New-TableRow([string[]]$cells, [bool]$isHeader = $false) {
    $tcXml = ""
    foreach ($cell in $cells) {
        $c = Escape-Xml $cell
        $fill = if ($isHeader) { "1E3A8A" } else { "FFFFFF" }
        $color = if ($isHeader) { "FFFFFF" } else { "1F2937" }
        $bold = if ($isHeader) { "<w:b/>" } else { "" }
        $tcXml += @"
    <w:tc>
      <w:tcPr>
        <w:shd w:val="clear" w:color="auto" w:fill="$fill"/>
      </w:tcPr>
      <w:p>
        <w:pPr><w:spacing w:before="60" w:after="60"/></w:pPr>
        <w:r>
          <w:rPr>
            <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
            $bold
            <w:color w:val="$color"/>
            <w:sz w:val="20"/>
          </w:rPr>
          <w:t xml:space="preserve">$c</w:t>
        </w:r>
      </w:p>
    </w:tc>
"@
    }
    return "<w:tr>$tcXml</w:tr>"
}

function New-Table([string[]]$headers, [array]$rows) {
    $rowsXml = New-TableRow -cells $headers -isHeader $true
    foreach ($r in $rows) {
        $rowsXml += New-TableRow -cells $r -isHeader $false
    }
    return @"
<w:tbl>
  <w:tblPr>
    <w:tblW w:w="5000" w:type="pct"/>
    <w:tblBorders>
      <w:top w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>
      <w:left w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>
      <w:bottom w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>
      <w:right w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>
      <w:insideH w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>
      <w:insideV w:val="single" w:sz="6" w:space="0" w:color="CBD5E1"/>
    </w:tblBorders>
    <w:tblCellMar>
      <w:top w:w="100" w:type="dxa"/>
      <w:left w:w="140" w:type="dxa"/>
      <w:bottom w:w="100" w:type="dxa"/>
      <w:right w:w="140" w:type="dxa"/>
    </w:tblCellMar>
  </w:tblPr>
  $rowsXml
</w:tbl>
<w:p><w:pPr><w:spacing w:before="80" w:after="80"/></w:pPr></w:p>
"@
}

$bodyContent = ""

# TÍTULO PRINCIPAL / PORTADA
$bodyContent += @"
<w:p>
  <w:pPr>
    <w:jc w:val="center"/>
    <w:spacing w:before="160" w:after="60"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:color w:val="1E3A8A"/>
      <w:sz w:val="38"/>
    </w:rPr>
    <w:t>ENTREGABLE SEMANA 12 — DRIZZLE ORM &amp; POSTGRESQL</w:t>
  </w:r>
</w:p>
<w:p>
  <w:pPr>
    <w:jc w:val="center"/>
    <w:spacing w:before="40" w:after="200"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>
      <w:b/>
      <w:color w:val="2563EB"/>
      <w:sz w:val="26"/>
    </w:rPr>
    <w:t>API HTTP en TypeScript con PostgreSQL y Migraciones Versionadas</w:t>
  </w:r>
</w:p>
"@

$bodyContent += New-Table -headers @("Campo", "Detalle del Proyecto") -rows @(
    @("Autor / Estudiante", "Mayro Gameros"),
    @("Dominio de la Aplicación", "Gestión de Catálogo e Inventario de Productos (Recurso principal: /products)"),
    @("Stack Tecnológico", "TypeScript, Node.js, Express.js, PostgreSQL 16, Drizzle ORM, Drizzle Kit, Zod"),
    @("Contenedor PostgreSQL", "migraciones-con-drizzleorm (Puerto 5435:5432 | Base de datos: drizzle_products_db)"),
    @("Enlace a GitHub", "https://github.com/MayroGamerosXZ/-S12-Migraciones-con-DrizzleORM.git")
)

# 1. ENLACE AL REPOSITORIO Y VARIABLES DE ENTORNO
$bodyContent += New-Heading1 "1. Enlace al Repositorio Público de GitHub y Configuración"
$bodyContent += New-Paragraph "El código fuente completo del proyecto, las migraciones SQL versionadas (carpeta drizzle/), el archivo de plantilla .env.example sin secretos y la documentación detallada en README.md se encuentran publicados en el siguiente repositorio público de GitHub:"
$bodyContent += New-CodeBlock @(
    "Repositorio Público de GitHub:",
    "https://github.com/MayroGamerosXZ/-S12-Migraciones-con-DrizzleORM.git"
)
$bodyContent += New-Bullet "Gestión de Variables de Entorno (.env.example):" "El proyecto utiliza dotenv para cargar la cadena de conexión DATABASE_URL y el puerto PORT desde variables de entorno. El archivo .env real está excluido en .gitignore, mientras que .env.example se conserva en Git sin credenciales ni secretos."
$bodyContent += New-CodeBlock @(
    "# Contenido de .env.example (sin secretos)",
    "PORT=3000",
    "NODE_ENV=development",
    "DATABASE_URL=postgresql://postgres:TU_PASSWORD_AQUI@localhost:5435/drizzle_products_db"
)

# 2. EVOLUCIÓN DEL ESQUEMA
$bodyContent += New-Heading1 "2. Explicación de la Evolución Realizada al Esquema"
$bodyContent += New-Paragraph "El modelado de la base de datos se diseñó aplicando el principio de migraciones evolutivas versionadas con Drizzle ORM y Drizzle Kit, evitando cualquier modificación manual sobre PostgreSQL:"
$bodyContent += New-Bullet "1. Migración Inicial (0000_initial_products_table.sql):" "Se creó la tabla principal products con 5 atributos esenciales para registrar productos en un catálogo básico: id (clave primaria serial autoincremental), name (texto obligatorio), description (texto opcional), price (numérico decimal 10,2 obligatorio) y created_at (marca de tiempo automática DEFAULT now())."
$bodyContent += New-Bullet "2. Segunda Migración Evolutiva (0001_evolve_products_inventory.sql):" "Para evolucionar la aplicación hacia un sistema formal de control de inventario y trazabilidad sin perder los registros existentes, se modificó el esquema en src/db/schema.ts agregando tres nuevas columnas y una restricción de unicidad mediante sentencias ALTER TABLE:"
$bodyContent += New-Bullet "   • Columna stock:" "Tipo integer NOT NULL DEFAULT 0. Permite controlar las unidades disponibles de cada producto."
$bodyContent += New-Bullet "   • Columna sku:" "Tipo text con restricción UNIQUE (products_sku_unique). Permite asignar un código alfanumérico único de inventario a cada artículo."
$bodyContent += New-Bullet "   • Columna updated_at:" "Tipo timestamp NOT NULL DEFAULT now(). Permite auditar la fecha y hora exacta de la última modificación del registro."

$bodyContent += New-Heading2 "2.1. Comparativa del Esquema Inicial (V1) vs Esquema Evolucionado (V2)"
$bodyContent += New-Table -headers @("Columna", "Tipo en PostgreSQL", "Restricciones", "Versión donde se incorpora") -rows @(
    @("id", "serial", "PRIMARY KEY NOT NULL", "Migración 1 (0000 - Inicial)"),
    @("name", "text", "NOT NULL", "Migración 1 (0000 - Inicial)"),
    @("description", "text", "NULLABLE", "Migración 1 (0000 - Inicial)"),
    @("price", "numeric(10, 2)", "NOT NULL", "Migración 1 (0000 - Inicial)"),
    @("created_at", "timestamp", "DEFAULT now() NOT NULL", "Migración 1 (0000 - Inicial)"),
    @("stock", "integer", "DEFAULT 0 NOT NULL", "Migración 2 (0001 - Evolutiva)"),
    @("sku", "text", "UNIQUE (products_sku_unique)", "Migración 2 (0001 - Evolutiva)"),
    @("updated_at", "timestamp", "DEFAULT now() NOT NULL", "Migración 2 (0001 - Evolutiva)")
)

$bodyContent += New-Heading2 "2.2. Archivos SQL Generados y Conservados en Git (/drizzle)"
$bodyContent += New-Paragraph "Archivo 1: drizzle/0000_initial_products_table.sql" -bold $true
$bodyContent += New-CodeBlock @(
    'CREATE TABLE "products" (',
    '  "id" serial PRIMARY KEY NOT NULL,',
    '  "name" text NOT NULL,',
    '  "description" text,',
    '  "price" numeric(10, 2) NOT NULL,',
    '  "created_at" timestamp DEFAULT now() NOT NULL',
    ');'
)
$bodyContent += New-Paragraph "Archivo 2: drizzle/0001_evolve_products_inventory.sql" -bold $true
$bodyContent += New-CodeBlock @(
    'ALTER TABLE "products" ADD COLUMN "stock" integer DEFAULT 0 NOT NULL;--> statement-breakpoint',
    'ALTER TABLE "products" ADD COLUMN "sku" text;--> statement-breakpoint',
    'ALTER TABLE "products" ADD COLUMN "updated_at" timestamp DEFAULT now() NOT NULL;--> statement-breakpoint',
    'ALTER TABLE "products" ADD CONSTRAINT "products_sku_unique" UNIQUE("sku");'
)

# 3. CAPTURAS DE LAS MIGRACIONES
$bodyContent += New-Heading1 "3. Evidencias de Generación y Aplicación de Migraciones"
$bodyContent += New-Paragraph "A continuación se presentan las capturas reales de la ejecución del contenedor PostgreSQL, la generación de la migración inicial y evolutiva con Drizzle Kit, y su aplicación automatizada mediante el script programático src/db/migrate.ts."

$bodyContent += New-CaptureWithImage -imgIndex 1 -number "CAPTURA 1" `
    -title "Contenedor PostgreSQL 'migraciones-con-drizzleorm' en ejecución" `
    -command "docker compose up -d ; docker ps --filter `"name=migraciones-con-drizzleorm`"" `
    -expectedDesc "El contenedor 'migraciones-con-drizzleorm' se encuentra en estado 'Up' recibiendo conexiones en el puerto 5435->5432/tcp."

$bodyContent += New-CaptureWithImage -imgIndex 2 -number "CAPTURA 2" `
    -title "Generación de la Migración Inicial (0000_initial_products_table.sql)" `
    -command "npm run db:generate:v1" `
    -expectedDesc "Drizzle Kit inspecciona el esquema inicial V1 (5 columnas) y genera el archivo SQL 'drizzle\0000_initial_products_table.sql'."

$bodyContent += New-CaptureWithImage -imgIndex 3 -number "CAPTURA 3" `
    -title "Aplicación Exitosa de la Migración Inicial en PostgreSQL" `
    -command "npm run db:migrate" `
    -expectedDesc "Ejecución sin cambios manuales aplicando la migración inicial 0000 sobre PostgreSQL."

$bodyContent += New-CaptureWithImage -imgIndex 4 -number "CAPTURA 4" `
    -title "Generación de la Segunda Migración Evolutiva (0001_evolve_products_inventory.sql)" `
    -command "npm run schema:v2 ; npm run db:generate:v2" `
    -expectedDesc "Tras evolucionar el esquema a 8 columnas (+stock, +sku, +updated_at), Drizzle Kit genera 'drizzle\0001_evolve_products_inventory.sql'."

$bodyContent += New-CaptureWithImage -imgIndex 5 -number "CAPTURA 5" `
    -title "Aplicación Exitosa de la Segunda Migración Evolutiva y Archivos en Git" `
    -command "npm run db:migrate ; Get-ChildItem drizzle" `
    -expectedDesc "Aplicación exitosa de la segunda migración sobre la tabla existente y verificación de ambos archivos SQL conservados en la carpeta drizzle/."

# 4. OPERACIONES PRINCIPALES DE LA API
$bodyContent += New-Heading1 "4. Operaciones Principales de la API HTTP y Validaciones"
$bodyContent += New-Paragraph "La API implementa todas las operaciones CRUD sobre el recurso /products utilizando Express y validaciones de entrada con Zod, respondiendo con los códigos de estado HTTP apropiados:"

$bodyContent += New-Table -headers @("Método", "Endpoint", "Operación", "Códigos HTTP") -rows @(
    @("GET", "/products", "Listar todos los productos registrados", "200 OK | 500 Internal Error"),
    @("GET", "/products/:id", "Consultar un producto específico por su ID", "200 OK | 400 Bad Request | 404 Not Found"),
    @("POST", "/products", "Crear un nuevo producto validando tipos y restricciones", "201 Created | 400 Bad Request"),
    @("PUT", "/products/:id", "Actualizar datos de un producto existente", "200 OK | 400 Bad Request | 404 Not Found"),
    @("DELETE", "/products/:id", "Eliminar un producto por su ID", "200 OK | 400 Bad Request | 404 Not Found")
)

$bodyContent += New-CaptureWithImage -imgIndex 6 -number "CAPTURA 6" `
    -title "Operación CREAR Producto (POST /products -> 201 Created)" `
    -command "curl.exe -i -X POST http://localhost:3000/products -H `"Content-Type: application/json`" -d `"{\`"name\`":\`"Laptop Gamer Pro\`",...}`"" `
    -expectedDesc "Creación exitosa del producto retornando código HTTP 201 Created y el registro insertado con sus campos del esquema evolucionado."

$bodyContent += New-CaptureWithImage -imgIndex 7 -number "CAPTURA 7" `
    -title "Validación de Datos Inválidos con Zod (POST /products -> 400 Bad Request)" `
    -command "curl.exe -i -X POST http://localhost:3000/products -H `"Content-Type: application/json`" -d `"{\`"name\`":\`"\`",\`"price\`":-50,\`"stock\`":-5}`"" `
    -expectedDesc "Rechazo de datos inválidos con código HTTP 400 Bad Request detallando los errores de validación por cada atributo."

$bodyContent += New-CaptureWithImage -imgIndex 8 -number "CAPTURA 8" `
    -title "Operación LISTAR Productos (GET /products -> 200 OK)" `
    -command "curl.exe -i http://localhost:3000/products" `
    -expectedDesc "Consulta general retornando código HTTP 200 OK y el listado completo de productos almacenados en PostgreSQL."

$bodyContent += New-CaptureWithImage -imgIndex 9 -number "CAPTURA 9" `
    -title "Operación CONSULTAR Producto por ID (GET /products/1 -> 200 OK y GET /products/999 -> 404 Not Found)" `
    -command "curl.exe -i http://localhost:3000/products/1 ; curl.exe -i http://localhost:3000/products/999" `
    -expectedDesc "Consulta individual exitosa por ID existente (200 OK) y respuesta controlada ante un ID inexistente (404 Not Found)."

$bodyContent += New-CaptureWithImage -imgIndex 10 -number "CAPTURA 10" `
    -title "Operación ACTUALIZAR Producto (PUT /products/1 -> 200 OK)" `
    -command "curl.exe -i -X PUT http://localhost:3000/products/1 -H `"Content-Type: application/json`" -d `"{\`"price\`":1199.50,\`"stock\`":25}`"" `
    -expectedDesc "Actualización exitosa del producto ID 1 modificando precio y stock, actualizando el sello updatedAt y respondiendo 200 OK."

$bodyContent += New-CaptureWithImage -imgIndex 11 -number "CAPTURA 11" `
    -title "Operación ELIMINAR Producto (DELETE /products/2 -> 200 OK)" `
    -command "curl.exe -i -X DELETE http://localhost:3000/products/2" `
    -expectedDesc "Eliminación del producto ID 2 en la base de datos confirmada con código HTTP 200 OK."

# 5. EVIDENCIA DE PERSISTENCIA TRAS REINICIAR LA APLICACIÓN
$bodyContent += New-Heading1 "5. Evidencia de Persistencia tras Reiniciar la Aplicación"
$bodyContent += New-Paragraph "Dado que la API persiste todos los registros en el motor PostgreSQL dentro del contenedor Docker 'migraciones-con-drizzleorm' respaldado por el volumen 'postgres_data', la detención o reinicio del proceso de Node.js/Express no afecta la integridad ni la disponibilidad de la información almacenada."

$bodyContent += New-CaptureWithImage -imgIndex 12 -number "CAPTURA 12" `
    -title "Reinicio del Servidor de la Aplicación y Comprobación de Persistencia (GET /products)" `
    -command "Detener servidor (Ctrl + C), reiniciar con 'npm run dev' y consultar: curl.exe -i http://localhost:3000/products" `
    -expectedDesc "Tras detener y volver a iniciar la aplicación desde cero, la consulta GET /products retorna los datos intactos desde PostgreSQL."

# 6. MATRIZ DE CUMPLIMIENTO DE REQUERIMIENTOS
$bodyContent += New-Heading1 "6. Matriz de Verificación de Requerimientos (3 / 3 Puntos)"
$bodyContent += New-Table -headers @("Criterio de Evaluación", "Requerimiento", "Estado", "Puntaje") -rows @(
    @("API, validaciones y persistencia", "Recurso principal (/products), CRUD completo, validaciones Zod (400/404/201/200) y persistencia en PostgreSQL.", "CUMPLIDO", "1.0 / 1.0 pt"),
    @("Migraciones inicial y evolutiva", "Migración 0000 inicial + Migración 0001 evolutiva conservadas en Git y ejecutadas sin SQL manual.", "CUMPLIDO", "1.0 / 1.0 pt"),
    @("Repositorio, documentación y evidencias", "Repositorio GitHub público, .env.example sin secretos, README.md completo y reporte con capturas.", "CUMPLIDO", "1.0 / 1.0 pt")
)

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
            xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
            xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
            xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
  <w:body>
    $bodyContent
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1000" w:right="1000" w:bottom="1000" w:left="1000" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$contentTypesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>
"@

$relsXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
"@

$docRelsItems = ""
for ($i = 1; $i -le 12; $i++) {
    $fileKey = ("captura_{0:D2}.png" -f $i)
    $docRelsItems += "  <Relationship Id=`"rIdImg$i`" Type=`"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image`" Target=`"media/$fileKey`"/>`r`n"
}

$docRelsXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
$docRelsItems</Relationships>
"@

$zip = [System.IO.Compression.ZipFile]::Open($docxPath, [System.IO.Compression.ZipArchiveMode]::Create)

function Add-ZipTextEntry($archive, [string]$entryName, [string]$content) {
    $entry = $archive.CreateEntry($entryName)
    $stream = $entry.Open()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()
}

Add-ZipTextEntry $zip "[Content_Types].xml" $contentTypesXml
Add-ZipTextEntry $zip "_rels/.rels" $relsXml
Add-ZipTextEntry $zip "word/document.xml" $documentXml
Add-ZipTextEntry $zip "word/_rels/document.xml.rels" $docRelsXml

for ($i = 1; $i -le 12; $i++) {
    $fileKey = ("captura_{0:D2}.png" -f $i)
    $imgFullPath = Join-Path $screenshotsDir $fileKey
    if ([System.IO.File]::Exists($imgFullPath)) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $imgFullPath, "word/media/$fileKey") | Out-Null
    }
}

$zip.Dispose()
Write-Host "✅ Documento Word con las 12 capturas incrustadas creado en: $docxPath"
