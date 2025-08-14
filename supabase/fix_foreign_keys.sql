-- Script para eliminar las restricciones de foreign key que impiden eliminar usuarios
-- Esto permitirá eliminar usuarios incluso si tienen registros en otras tablas

-- 1. Eliminar las restricciones existentes
ALTER TABLE public.ingresos DROP CONSTRAINT IF EXISTS ingresos_cliente_id_fkey;
ALTER TABLE public.access_logs DROP CONSTRAINT IF EXISTS access_logs_user_id_fkey;
ALTER TABLE public.payments DROP CONSTRAINT IF EXISTS payments_user_id_fkey;

-- 2. Volver a crear las restricciones con ON DELETE SET NULL
-- Esto hará que cuando se elimine un usuario, los campos relacionados se pongan en NULL
-- en lugar de impedir la eliminación

-- Para la tabla ingresos
ALTER TABLE public.ingresos 
ADD CONSTRAINT ingresos_cliente_id_fkey 
FOREIGN KEY (cliente_id) REFERENCES public.users(id) 
ON DELETE SET NULL;

-- Para la tabla access_logs
ALTER TABLE public.access_logs 
ADD CONSTRAINT access_logs_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) 
ON DELETE SET NULL;

-- Para la tabla payments
ALTER TABLE public.payments 
ADD CONSTRAINT payments_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) 
ON DELETE SET NULL;

-- 3. También modificar las restricciones de promociones para evitar problemas similares
ALTER TABLE public.ingresos DROP CONSTRAINT IF EXISTS ingresos_promocion_id_fkey;
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_current_promotion_id_fkey;

-- Volver a crear con SET NULL
ALTER TABLE public.ingresos 
ADD CONSTRAINT ingresos_promocion_id_fkey 
FOREIGN KEY (promocion_id) REFERENCES public.promotions(id) 
ON DELETE SET NULL;

ALTER TABLE public.users 
ADD CONSTRAINT users_current_promotion_id_fkey 
FOREIGN KEY (current_promotion_id) REFERENCES public.promotions(id) 
ON DELETE SET NULL;

-- Comentario: 
-- Con estos cambios, cuando elimines un usuario:
-- - Los registros en 'ingresos' mantendrán el nombre del cliente pero cliente_id será NULL
-- - Los registros en 'access_logs' mantendrán el nombre de usuario pero user_id será NULL  
-- - Los registros en 'payments' mantendrán la información pero user_id será NULL
-- 
-- Esto preserva el historial financiero y de accesos mientras permite eliminar usuarios.
