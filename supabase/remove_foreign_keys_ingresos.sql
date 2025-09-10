-- Migración para eliminar las foreign keys de la tabla ingresos
-- Fecha: 2025-09-03
-- Descripción: Elimina las referencias UUID para hacer la tabla ingresos independiente

-- 1. Eliminar las foreign key constraints
ALTER TABLE public.ingresos 
DROP CONSTRAINT IF EXISTS ingresos_cliente_id_fkey;

ALTER TABLE public.ingresos 
DROP CONSTRAINT IF EXISTS ingresos_promocion_id_fkey;

-- 2. Modificar las columnas UUID para que sean opcionales/nullables
ALTER TABLE public.ingresos 
ALTER COLUMN cliente_id DROP NOT NULL;

ALTER TABLE public.ingresos 
ALTER COLUMN promocion_id DROP NOT NULL;

-- 3. Actualizar registros existentes que tengan UUIDs para preservar la información
-- Los campos de texto (cliente_nombre, promocion_nombre) ya contienen la información necesaria

-- 4. Opcional: Agregar índices en los campos de texto para mejorar performance
CREATE INDEX IF NOT EXISTS idx_ingresos_cliente_nombre ON public.ingresos(cliente_nombre);
CREATE INDEX IF NOT EXISTS idx_ingresos_promocion_nombre ON public.ingresos(promocion_nombre);
CREATE INDEX IF NOT EXISTS idx_ingresos_fecha ON public.ingresos(fecha);
CREATE INDEX IF NOT EXISTS idx_ingresos_venta_tipo ON public.ingresos(venta_tipo);

-- 5. Comentarios para documentar los cambios
COMMENT ON COLUMN public.ingresos.cliente_id IS 'UUID opcional del cliente - solo para referencia, no constraint';
COMMENT ON COLUMN public.ingresos.promocion_id IS 'UUID opcional de la promoción - solo para referencia, no constraint';
COMMENT ON COLUMN public.ingresos.cliente_nombre IS 'Nombre del cliente - campo principal para identificación';
COMMENT ON COLUMN public.ingresos.promocion_nombre IS 'Nombre de la promoción aplicada - campo principal para reportes';
