-- Migration: Eliminar tipo de acceso 'salida' y dejar solo 'entrada'
-- Fecha: 2025-10-21
-- Descripción: Simplifica el sistema de registro de accesos para solo registrar entradas

-- Paso 1: Actualizar todos los registros de 'salida' a 'entrada'
-- IMPORTANTE: Esto debe ejecutarse ANTES del constraint CHECK
UPDATE public.access_logs SET access_type = 'entrada' WHERE access_type = 'salida';

-- Paso 2: Agregar constraint CHECK para permitir solo 'entrada'
ALTER TABLE public.access_logs
DROP CONSTRAINT IF EXISTS access_logs_access_type_check;

ALTER TABLE public.access_logs
ADD CONSTRAINT access_logs_access_type_check 
CHECK (access_type = 'entrada');

-- Paso 3: Actualizar el valor por defecto (ya está como 'entrada' pero lo confirmamos)
ALTER TABLE public.access_logs
ALTER COLUMN access_type SET DEFAULT 'entrada'::text;

-- Paso 4: Hacer el campo NOT NULL para asegurar consistencia
ALTER TABLE public.access_logs
ALTER COLUMN access_type SET NOT NULL;

-- Comentarios descriptivos
COMMENT ON COLUMN public.access_logs.access_type IS 'Tipo de acceso - Solo permite entrada (sin salidas)';
COMMENT ON CONSTRAINT access_logs_access_type_check ON public.access_logs IS 'Asegura que solo se registren entradas';
