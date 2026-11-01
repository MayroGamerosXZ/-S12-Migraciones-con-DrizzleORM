import * as fs from "fs";
import * as path from "path";

const mode = process.argv[2];
const schemaPath = path.resolve(process.cwd(), "src/db/schema.ts");
const drizzleDir = path.resolve(process.cwd(), "drizzle");

const schemaV1 = `import { pgTable, serial, text, numeric, timestamp } from "drizzle-orm/pg-core";

// ESQUEMA INICIAL (V1) - Migración 0000
export const products = pgTable("products", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description"),
  price: numeric("price", { precision: 10, scale: 2 }).notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export type Product = typeof products.$inferSelect;
export type NewProduct = typeof products.$inferInsert;
`;

const schemaV2 = `import { pgTable, serial, text, numeric, integer, timestamp } from "drizzle-orm/pg-core";

// ESQUEMA EVOLUCIONADO (V2) - Migración 0001 (agrega stock, sku único y updated_at)
export const products = pgTable("products", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description"),
  price: numeric("price", { precision: 10, scale: 2 }).notNull(),
  stock: integer("stock").default(0).notNull(),
  sku: text("sku").unique(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

export type Product = typeof products.$inferSelect;
export type NewProduct = typeof products.$inferInsert;
`;

if (mode === "v1") {
  if (fs.existsSync(drizzleDir)) {
    fs.rmSync(drizzleDir, { recursive: true, force: true });
    console.log("🧹 Carpeta './drizzle' limpiada para iniciar desde cero.");
  }
  fs.writeFileSync(schemaPath, schemaV1, "utf-8");
  console.log("📝 Esquema configurado en Versión 1 (Inicial: id, name, description, price, created_at).");
  console.log("👉 Siguiente paso: Ejecuta 'npx drizzle-kit generate --name=initial_products_table'");
} else if (mode === "v2") {
  fs.writeFileSync(schemaPath, schemaV2, "utf-8");
  console.log("🚀 Esquema evolucionado a Versión 2 (+ stock, + sku UNIQUE, + updated_at).");
  console.log("👉 Siguiente paso: Ejecuta 'npx drizzle-kit generate --name=evolve_products_inventory'");
} else {
  console.error("Uso: tsx src/db/switch-schema.ts <v1|v2>");
  process.exit(1);
}
