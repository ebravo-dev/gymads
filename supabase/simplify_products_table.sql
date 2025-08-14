-- Script para simplificar la tabla de productos
-- Remover las columnas de imagen, SKU, código de barras y precio de costo

-- 1. Remover columna image_url (si existe)
ALTER TABLE products DROP COLUMN IF EXISTS image_url;

-- 2. Remover columna sku (si existe)
ALTER TABLE products DROP COLUMN IF EXISTS sku;

-- 3. Remover columna barcode (si existe)
ALTER TABLE products DROP COLUMN IF EXISTS barcode;

-- 4. Remover columna cost_price (si existe)
ALTER TABLE products DROP COLUMN IF EXISTS cost_price;

-- Verificar la estructura final de la tabla
-- Debería tener solo: id, name, description, category, price, stock, is_active, created_at, updated_at
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'products'
ORDER BY ordinal_position;
