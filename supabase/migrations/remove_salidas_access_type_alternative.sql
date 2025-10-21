-- Migration ALTERNATIVA: Mantener registros históricos de 'salida' pero prevenir nuevos
-- Fecha: 2025-10-21
-- Descripción: Permite que los registros históricos de 'salida' permanezcan, 
--              pero solo permite nuevos registros de tipo 'entrada'

-- OPCIÓN A: Constraint que permite 'entrada' y 'salida' (mantiene históricos)
-- pero tu aplicación solo creará 'entrada' de ahora en adelante
ALTER TABLE public.access_logs
DROP CONSTRAINT IF EXISTS access_logs_access_type_check;

ALTER TABLE public.access_logs
ADD CONSTRAINT access_logs_access_type_check 
CHECK (access_type IN ('entrada', 'salida'));

-- Actualizar el valor por defecto a 'entrada'
ALTER TABLE public.access_logs
ALTER COLUMN access_type SET DEFAULT 'entrada'::text;

-- Hacer el campo NOT NULL
ALTER TABLE public.access_logs
ALTER COLUMN access_type SET NOT NULL;

-- OPCIÓN B: Si quieres ser más estricto y REALMENTE prevenir 'salida' en el futuro,
-- puedes usar una función trigger que solo permita 'salida' si es un UPDATE, no un INSERT

CREATE OR REPLACE FUNCTION prevent_new_salidas()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.access_type = 'salida' THEN
    RAISE EXCEPTION 'No se permiten nuevos registros de tipo salida';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Descomenta para activar el trigger
-- DROP TRIGGER IF EXISTS prevent_salidas_trigger ON public.access_logs;
-- CREATE TRIGGER prevent_salidas_trigger
-- BEFORE INSERT ON public.access_logs
-- FOR EACH ROW
-- EXECUTE FUNCTION prevent_new_salidas();

COMMENT ON COLUMN public.access_logs.access_type IS 'Tipo de acceso - entrada o salida (histórico). Solo se crean nuevas entradas.';
