-- Migración para soportar ventas de productos en la tabla ingresos
-- Agregar campos específicos para el punto de venta

-- Agregar campos para manejar ventas de productos
ALTER TABLE public.ingresos 
ADD COLUMN IF NOT EXISTS impuestos numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS monto_recibido numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS cambio numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS items_detalle jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS venta_tipo text DEFAULT 'membresia',
ADD COLUMN IF NOT EXISTS subtotal numeric DEFAULT 0;

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_ingresos_venta_tipo ON public.ingresos(venta_tipo);
CREATE INDEX IF NOT EXISTS idx_ingresos_fecha ON public.ingresos(fecha);
CREATE INDEX IF NOT EXISTS idx_ingresos_metodo_pago ON public.ingresos(metodo_pago);

-- Comentarios para documentar los nuevos campos
COMMENT ON COLUMN public.ingresos.impuestos IS 'Monto de impuestos aplicados en la venta';
COMMENT ON COLUMN public.ingresos.monto_recibido IS 'Monto recibido del cliente (especialmente para efectivo)';
COMMENT ON COLUMN public.ingresos.cambio IS 'Cambio entregado al cliente';
COMMENT ON COLUMN public.ingresos.items_detalle IS 'Detalle de productos vendidos en formato JSON';
COMMENT ON COLUMN public.ingresos.venta_tipo IS 'Tipo de venta: membresia, producto, mixto';
COMMENT ON COLUMN public.ingresos.subtotal IS 'Subtotal antes de impuestos y descuentos';

-- Actualizar los registros existentes para que tengan venta_tipo = 'membresia'
UPDATE public.ingresos 
SET venta_tipo = 'membresia' 
WHERE venta_tipo IS NULL OR venta_tipo = '';

-- Función para validar el formato de items_detalle
CREATE OR REPLACE FUNCTION validate_items_detalle() RETURNS trigger AS $$
BEGIN
  -- Validar que items_detalle sea un array válido cuando venta_tipo es 'producto'
  IF NEW.venta_tipo = 'producto' AND NEW.items_detalle IS NOT NULL THEN
    -- Verificar que sea un array
    IF jsonb_typeof(NEW.items_detalle) != 'array' THEN
      RAISE EXCEPTION 'items_detalle debe ser un array JSON válido';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger para validar items_detalle
DROP TRIGGER IF EXISTS validate_items_detalle_trigger ON public.ingresos;
CREATE TRIGGER validate_items_detalle_trigger
  BEFORE INSERT OR UPDATE ON public.ingresos
  FOR EACH ROW EXECUTE FUNCTION validate_items_detalle();

-- Función para calcular totales automáticamente
CREATE OR REPLACE FUNCTION calculate_sale_totals() RETURNS trigger AS $$
BEGIN
  -- Si es una venta de productos, calcular totales basados en items_detalle
  IF NEW.venta_tipo = 'producto' AND NEW.items_detalle IS NOT NULL THEN
    -- Calcular subtotal desde items_detalle
    SELECT COALESCE(SUM((item->>'total')::numeric), 0)
    INTO NEW.subtotal
    FROM jsonb_array_elements(NEW.items_detalle) as item;
    
    -- Si monto_base no está definido, usar subtotal
    IF NEW.monto_base IS NULL OR NEW.monto_base = 0 THEN
      NEW.monto_base = NEW.subtotal;
    END IF;
    
    -- Calcular monto_final si no está definido
    IF NEW.monto_final IS NULL OR NEW.monto_final = 0 THEN
      NEW.monto_final = NEW.monto_base + COALESCE(NEW.impuestos, 0) - COALESCE(NEW.descuento, 0);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger para cálculo automático de totales
DROP TRIGGER IF EXISTS calculate_sale_totals_trigger ON public.ingresos;
CREATE TRIGGER calculate_sale_totals_trigger
  BEFORE INSERT OR UPDATE ON public.ingresos
  FOR EACH ROW EXECUTE FUNCTION calculate_sale_totals();
