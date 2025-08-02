-- Script para agregar campos de promociones a la tabla users
-- Ejecutar en Supabase Query Editor

-- Agregar campos para promociones aplicadas
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS current_promotion_id uuid,
ADD COLUMN IF NOT EXISTS current_promotion_name text,
ADD COLUMN IF NOT EXISTS promotion_discount_amount numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS promotion_applied_date timestamp with time zone,
ADD COLUMN IF NOT EXISTS promotion_expires_date timestamp with time zone;

-- Agregar clave foránea para relacionar con promociones
ALTER TABLE public.users 
ADD CONSTRAINT users_current_promotion_id_fkey 
FOREIGN KEY (current_promotion_id) REFERENCES public.promotions(id);

-- Crear índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_users_current_promotion_id ON public.users(current_promotion_id);
CREATE INDEX IF NOT EXISTS idx_users_promotion_expires_date ON public.users(promotion_expires_date);

-- Comentarios para documentar los nuevos campos
COMMENT ON COLUMN public.users.current_promotion_id IS 'ID de la promoción actualmente aplicada al usuario';
COMMENT ON COLUMN public.users.current_promotion_name IS 'Nombre de la promoción aplicada (para histórico)';
COMMENT ON COLUMN public.users.promotion_discount_amount IS 'Monto de descuento aplicado por la promoción';
COMMENT ON COLUMN public.users.promotion_applied_date IS 'Fecha cuando se aplicó la promoción';
COMMENT ON COLUMN public.users.promotion_expires_date IS 'Fecha cuando expira la promoción para el usuario';
