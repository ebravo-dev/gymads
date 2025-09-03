-- Modificar la tabla ingresos para permitir cliente_id NULL para ventas de productos
-- Esto permite ventas directas sin necesidad de un cliente específico

-- Remover la restricción NOT NULL de cliente_id si existe
ALTER TABLE public.ingresos 
ALTER COLUMN cliente_id DROP NOT NULL;

-- Actualizar la restricción de clave foránea para permitir NULL
-- Esto se hace automáticamente ya que las FK permiten NULL por defecto

-- Crear un índice parcial para mejorar el rendimiento en consultas con cliente_id NULL
CREATE INDEX IF NOT EXISTS idx_ingresos_venta_tipo_cliente_null 
ON public.ingresos (venta_tipo, fecha) 
WHERE cliente_id IS NULL;

-- Crear un índice para ventas de productos
CREATE INDEX IF NOT EXISTS idx_ingresos_venta_tipo_producto 
ON public.ingresos (venta_tipo, fecha) 
WHERE venta_tipo = 'producto';

-- Comentario explicativo
COMMENT ON COLUMN public.ingresos.cliente_id IS 'ID del cliente. Puede ser NULL para ventas directas de productos sin cliente específico';
