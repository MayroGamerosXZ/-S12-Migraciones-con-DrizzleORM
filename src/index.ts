import express, { Request, Response } from "express";
import * as dotenv from "dotenv";
import productRoutes from "./routes/product.routes";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares y configuración de formato JSON legible
app.set("json spaces", 2);
app.use(express.json());

// Logger simple de solicitudes
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
  next();
});

// Endpoint de estado
app.get("/health", (_req: Request, res: Response) => {
  return res.status(200).json({
    status: "ok",
    timestamp: new Date().toISOString(),
    service: "S12-Migraciones-con-DrizzleORM API",
  });
});

// Rutas de la API
app.use("/products", productRoutes);

// Manejador de rutas no encontradas
app.use((_req: Request, res: Response) => {
  return res.status(404).json({
    success: false,
    message: "Ruta no encontrada en el servidor",
  });
});

// Iniciar el servidor
app.listen(PORT, () => {
  console.log("==================================================");
  console.log(`🚀 Servidor HTTP corriendo en http://localhost:${PORT}`);
  console.log(`📦 Recurso principal disponible en http://localhost:${PORT}/products`);
  console.log("==================================================");
});

export default app;
