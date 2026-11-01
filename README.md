# API HTTP en TypeScript con PostgreSQL y Migraciones Versionadas (Drizzle ORM)

Este proyecto consiste en una API REST desarrollada con **TypeScript**, **Express**, **PostgreSQL** y **Drizzle ORM**. Implementa un recurso principal enfocado en la **Gestión de Catálogo e Inventario de Productos**, con validaciones rigurosas mediante **Zod**, respuestas con códigos de estado HTTP estandarizados y un sistema de migraciones versionadas y automatizadas.

---

## 🛠️ Tecnologías Utilizadas

- **Lenguaje:** [TypeScript](https://www.typescriptlang.org/)
- **Entorno de ejecución:** [Node.js](https://nodejs.org/) (v20+)
- **Framework HTTP:** [Express.js](https://expressjs.com/)
- **ORM & Migraciones:** [Drizzle ORM](https://orm.drizzle.team/) & [Drizzle Kit](https://orm.drizzle.team/kit-docs/overview)
- **Base de Datos:** [PostgreSQL 16](https://www.postgresql.org/) (orquestada mediante Docker Compose)
- **Validación de Datos:** [Zod](https://zod.dev/)
- **Driver de Conexión:** [Postgres.js](https://github.com/porsager/postgres)

---

## 📂 Estructura del Proyecto

```text
├── .env.example              # Plantilla de variables de entorno (sin credenciales)
├── docker-compose.yml        # Configuración del contenedor PostgreSQL
├── drizzle.config.ts         # Configuración del CLI de Drizzle Kit
├── drizzle/                  # Directorio de migraciones SQL versionadas
│   ├── 0000_typical_puck.sql      # Migración inicial V1 (tabla products base)
│   ├── 0001_fresh_red_ghost.sql   # Migración evolutiva V2 (stock, sku, updated_at)
│   └── meta/                      # Metadatos del historial de Drizzle
├── package.json              # Dependencias y scripts del proyecto
├── tsconfig.json             # Configuración del compilador TypeScript
└── src/
    ├── db/
    │   ├── index.ts          # Conexión al cliente de PostgreSQL con Drizzle
    │   ├── migrate.ts        # Script de migración programática automatizada
    │   └── schema.ts         # Definición del esquema Drizzle
    ├── controllers/
    │   └── product.controller.ts  # Lógica del CRUD y códigos HTTP
    ├── routes/
    │   └── product.routes.ts      # Enrutamiento de /products
    ├── validations/
    │   └── product.validation.ts  # Esquemas de validación Zod
    └── index.ts              # Punto de entrada del servidor Express
```

---

## 🚀 Requisitos Previos

- [Node.js](https://nodejs.org/) (versión 20 o superior recomendada)
- [npm](https://www.npmjs.com/)
- [Docker](https://www.docker.com/) & Docker Compose

---

## ⚙️ Instalación y Configuración

### 1. Clonar el repositorio
```bash
git clone https://github.com/MayroGamerosXZ/-S12-Migraciones-con-DrizzleORM.git
cd -S12-Migraciones-con-DrizzleORM
```

### 2. Instalar dependencias
```bash
npm install
```

### 3. Configurar variables de entorno
Copia el archivo `.env.example` y crea tu archivo `.env`:
```bash
cp .env.example .env
```
Verifica que las credenciales coincidan con la configuración de tu contenedor Docker:
```env
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://postgres:Robin1710@localhost:5435/drizzle_products_db
```

### 4. Iniciar la Base de Datos con Docker
El contenedor está configurado con el nombre `migraciones-con-drizzleorm` y mapeado al puerto local `5435`:
```bash
docker compose up -d
```
Para verificar que el contenedor esté corriendo:
```bash
docker ps
```

---

## 🗄️ Migraciones de Base de Datos con Drizzle ORM

Este proyecto utiliza migraciones versionadas sin realizar modificaciones manuales directas en la base de datos.

### Evolución del Esquema:
1. **Migración Inicial (`0000_typical_puck.sql`):**
   - Crea la tabla `products` con las columnas base:
     - `id`: Serial (Primary Key autoincremental).
     - `name`: Texto no nulo.
     - `description`: Texto opcional.
     - `price`: Decimal con precisión (10, 2) no nulo.
     - `created_at`: Timestamp por defecto al momento de creación (`now()`).

2. **Migración Evolutiva (`0001_fresh_red_ghost.sql`):**
   - Evoluciona el esquema de productos hacia un sistema de control de inventario y auditoría:
     - `stock`: Entero no nulo por defecto en `0`.
     - `sku`: Código único de inventario (`UNIQUE`).
     - `updated_at`: Timestamp para auditoría de actualizaciones (`now()`).

### Comandos de Migración:
* **Generar migraciones** (detecta cambios en `src/db/schema.ts` y genera el SQL):
  ```bash
  npm run db:generate
  ```
* **Aplicar migraciones** (ejecuta el script programático `src/db/migrate.ts`):
  ```bash
  npm run db:migrate
  ```

---

## ▶️ Ejecución de la API

### Modo Desarrollo:
```bash
npm run dev
```

### Modo Producción:
```bash
npm run build
npm start
```
El servidor estará disponible en: `http://localhost:3000`

---

## 📡 Endpoints de la API y Ejemplos

### 1. Healthcheck
- **Método:** `GET`
- **URL:** `http://localhost:3000/health`
- **Respuesta (200 OK):**
```json
{
  "status": "ok",
  "timestamp": "2026-11-01T03:39:43.929Z",
  "service": "S12-Migraciones-con-DrizzleORM API"
}
```

---

### 2. Listar Productos
- **Método:** `GET`
- **URL:** `http://localhost:3000/products`
- **Respuesta (200 OK):**
```json
{
  "success": true,
  "total": 1,
  "data": [
    {
      "id": 1,
      "name": "Laptop Gamer Pro",
      "description": "Laptop de alto rendimiento 32GB RAM",
      "price": "1299.99",
      "stock": 15,
      "sku": "LPT-PRO-001",
      "createdAt": "2026-11-01T03:39:44.113Z",
      "updatedAt": "2026-11-01T03:39:44.113Z"
    }
  ]
}
```

---

### 3. Consultar Producto por ID
- **Método:** `GET`
- **URL:** `http://localhost:3000/products/:id`
- **Respuesta Exitosa (200 OK):** Retorna el producto consultado.
- **Respuesta de Error (404 Not Found):**
```json
{
  "success": false,
  "message": "Producto con ID 999 no encontrado"
}
```

---

### 4. Crear Producto
- **Método:** `POST`
- **URL:** `http://localhost:3000/products`
- **Headers:** `Content-Type: application/json`
- **Body válido:**
```json
{
  "name": "Monitor Gamer 4K",
  "description": "Monitor IPS 27 pulgadas 144Hz",
  "price": 450.00,
  "stock": 10,
  "sku": "MON-4K-002"
}
```
- **Respuesta Exitosa (201 Created):**
```json
{
  "success": true,
  "message": "Producto creado exitosamente",
  "data": {
    "id": 2,
    "name": "Monitor Gamer 4K",
    "description": "Monitor IPS 27 pulgadas 144Hz",
    "price": "450.00",
    "stock": 10,
    "sku": "MON-4K-002",
    "createdAt": "2026-11-01T03:40:06.191Z",
    "updatedAt": "2026-11-01T03:40:06.191Z"
  }
}
```
- **Respuesta de Error de Validación (400 Bad Request):**
```json
{
  "success": false,
  "message": "Errores de validación en los datos enviados",
  "errors": {
    "name": ["El nombre es obligatorio"],
    "price": ["El precio debe ser un número positivo"],
    "stock": ["El stock no puede ser negativo"]
  }
}
```

---

### 5. Actualizar Producto
- **Método:** `PUT`
- **URL:** `http://localhost:3000/products/:id`
- **Headers:** `Content-Type: application/json`
- **Body:**
```json
{
  "price": 1199.50,
  "stock": 25
}
```
- **Respuesta Exitosa (200 OK):** Retorna el producto con los datos modificados y la fecha `updatedAt` actualizada.
- **Respuesta de Error (404 Not Found):** Si el ID no existe en la base de datos.

---

### 6. Eliminar Producto
- **Método:** `DELETE`
- **URL:** `http://localhost:3000/products/:id`
- **Respuesta Exitosa (200 OK):**
```json
{
  "success": true,
  "message": "Producto eliminado exitosamente",
  "data": {
    "id": 1,
    "name": "Laptop Gamer Pro",
    "description": "Laptop de alto rendimiento 32GB RAM",
    "price": "1199.50",
    "stock": 25,
    "sku": "LPT-PRO-001",
    "createdAt": "2026-11-01T03:39:44.113Z",
    "updatedAt": "2026-11-01T03:39:44.595Z"
  }
}
```

---

## 🔒 Persistencia Comprobada
Los datos se almacenan en el volumen de PostgreSQL gestionado por Docker (`postgres_data`). Incluso al detener el servidor Express o el contenedor, los datos persisten íntegramente tras reiniciar.
