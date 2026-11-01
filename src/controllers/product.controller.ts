import { Request, Response } from "express";
import { eq } from "drizzle-orm";
import { db } from "../db/index";
import { products } from "../db/schema";
import {
  createProductSchema,
  updateProductSchema,
  productIdSchema,
} from "../validations/product.validation";

// Listar todos los productos
export const getAllProducts = async (_req: Request, res: Response) => {
  try {
    const allProducts = await db.select().from(products).orderBy(products.id);
    return res.status(200).json({
      success: true,
      total: allProducts.length,
      data: allProducts,
    });
  } catch (error) {
    console.error("Error al obtener productos:", error);
    return res.status(500).json({
      success: false,
      message: "Error interno del servidor al consultar productos",
    });
  }
};

// Consultar un producto por ID
export const getProductById = async (req: Request, res: Response) => {
  try {
    const parsedParams = productIdSchema.safeParse(req.params);
    if (!parsedParams.success) {
      return res.status(400).json({
        success: false,
        message: "ID inválido",
        errors: parsedParams.error.flatten().fieldErrors,
      });
    }

    const { id } = parsedParams.data;
    const result = await db.select().from(products).where(eq(products.id, id));

    if (result.length === 0) {
      return res.status(404).json({
        success: false,
        message: `Producto con ID ${id} no encontrado`,
      });
    }

    return res.status(200).json({
      success: true,
      data: result[0],
    });
  } catch (error) {
    console.error("Error al obtener producto por ID:", error);
    return res.status(500).json({
      success: false,
      message: "Error interno del servidor",
    });
  }
};

// Crear un nuevo producto
export const createProduct = async (req: Request, res: Response) => {
  try {
    const parsedBody = createProductSchema.safeParse(req.body);
    if (!parsedBody.success) {
      return res.status(400).json({
        success: false,
        message: "Errores de validación en los datos enviados",
        errors: parsedBody.error.flatten().fieldErrors,
      });
    }

    const { name, description, price, stock, sku } = parsedBody.data;

    const [newProduct] = await db
      .insert(products)
      .values({
        name,
        description: description || null,
        price: price.toFixed(2),
        stock: stock ?? 0,
        sku: sku || null,
      })
      .returning();

    return res.status(201).json({
      success: true,
      message: "Producto creado exitosamente",
      data: newProduct,
    });
  } catch (error: any) {
    console.error("Error al crear producto:", error);
    if (error?.code === "23505") {
      return res.status(400).json({
        success: false,
        message: "El código SKU ya se encuentra registrado por otro producto",
      });
    }
    return res.status(500).json({
      success: false,
      message: "Error interno del servidor al crear el producto",
    });
  }
};

// Actualizar un producto existente
export const updateProduct = async (req: Request, res: Response) => {
  try {
    const parsedParams = productIdSchema.safeParse(req.params);
    if (!parsedParams.success) {
      return res.status(400).json({
        success: false,
        message: "ID inválido",
        errors: parsedParams.error.flatten().fieldErrors,
      });
    }

    const parsedBody = updateProductSchema.safeParse(req.body);
    if (!parsedBody.success) {
      return res.status(400).json({
        success: false,
        message: "Errores de validación en la actualización",
        errors: parsedBody.error.flatten().fieldErrors,
      });
    }

    const { id } = parsedParams.data;
    const updateData: any = {
      ...parsedBody.data,
      updatedAt: new Date(),
    };

    if (parsedBody.data.price !== undefined) {
      updateData.price = parsedBody.data.price.toFixed(2);
    }

    const updated = await db
      .update(products)
      .set(updateData)
      .where(eq(products.id, id))
      .returning();

    if (updated.length === 0) {
      return res.status(404).json({
        success: false,
        message: `Producto con ID ${id} no encontrado para actualizar`,
      });
    }

    return res.status(200).json({
      success: true,
      message: "Producto actualizado exitosamente",
      data: updated[0],
    });
  } catch (error: any) {
    console.error("Error al actualizar producto:", error);
    if (error?.code === "23505") {
      return res.status(400).json({
        success: false,
        message: "El código SKU ya se encuentra registrado por otro producto",
      });
    }
    return res.status(500).json({
      success: false,
      message: "Error interno del servidor al actualizar el producto",
    });
  }
};

// Eliminar un producto
export const deleteProduct = async (req: Request, res: Response) => {
  try {
    const parsedParams = productIdSchema.safeParse(req.params);
    if (!parsedParams.success) {
      return res.status(400).json({
        success: false,
        message: "ID inválido",
        errors: parsedParams.error.flatten().fieldErrors,
      });
    }

    const { id } = parsedParams.data;
    const deleted = await db
      .delete(products)
      .where(eq(products.id, id))
      .returning();

    if (deleted.length === 0) {
      return res.status(404).json({
        success: false,
        message: `Producto con ID ${id} no encontrado para eliminar`,
      });
    }

    return res.status(200).json({
      success: true,
      message: "Producto eliminado exitosamente",
      data: deleted[0],
    });
  } catch (error) {
    console.error("Error al eliminar producto:", error);
    return res.status(500).json({
      success: false,
      message: "Error interno del servidor al eliminar el producto",
    });
  }
};
