import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as dotenv from "dotenv";
import * as schema from "./schema";

dotenv.config();

const connectionString =
  process.env.DATABASE_URL ||
  "postgresql://postgres:Robin1710@localhost:5435/drizzle_products_db";

// Cliente para consultas regulares de la API (con pool)
export const queryClient = postgres(connectionString);
export const db = drizzle(queryClient, { schema });

// Cliente dedicado para migraciones (máx 1 conexión según mejores prácticas de Drizzle)
export const migrationClient = postgres(connectionString, { max: 1 });
export const migrationDb = drizzle(migrationClient);
