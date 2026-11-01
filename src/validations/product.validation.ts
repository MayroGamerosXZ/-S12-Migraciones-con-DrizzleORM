import { z } from "zod";

export const createProductSchema = z.object({
  name: z
    .string()
    .trim()
    .min(1, "El nombre es obligatorio")
    .max(255, "El nombre no puede exceder 255 caracteres"),
  description: z.string().trim().optional(),
  price: z
    .number()
    .positive("El precio debe ser un número positivo"),
  stock: z
    .number()
    .int("El stock debe ser un número entero")
    .nonnegative("El stock no puede ser negativo")
    .default(0),
  sku: z
    .string()
    .trim()
    .min(3, "El SKU debe tener al menos 3 caracteres")
    .max(50, "El SKU no puede exceder 50 caracteres")
    .optional(),
});

export const updateProductSchema = createProductSchema.partial().refine(
  (data) => Object.keys(data).length > 0,
  { message: "Debe proporcionar al menos un campo para actualizar" }
);

export const productIdSchema = z.object({
  id: z
    .string()
    .regex(/^\d+$/, "El ID debe ser un número entero positivo")
    .transform((val) => parseInt(val, 10)),
});

export type CreateProductInput = z.infer<typeof createProductSchema>;
export type UpdateProductInput = z.infer<typeof updateProductSchema>;
