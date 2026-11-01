import { migrate } from "drizzle-orm/postgres-js/migrator";
import { migrationDb, migrationClient } from "./index";

async function runMigrations() {
  console.log("==================================================");
  console.log("🚀 Iniciando aplicación de migraciones Drizzle...");
  console.log("==================================================");

  try {
    await migrate(migrationDb, { migrationsFolder: "./drizzle" });
    console.log("✅ ¡Migraciones aplicadas exitosamente en PostgreSQL!");
  } catch (error) {
    console.error("❌ Error al aplicar las migraciones:", error);
    process.exit(1);
  } finally {
    await migrationClient.end();
    console.log("🔌 Conexión de migración cerrada.");
    process.exit(0);
  }
}

runMigrations();
