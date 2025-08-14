-- Script para actualizar la tabla promotions
-- Ejecutar en el Query Editor de Supabase

-- Agregar nuevos campos para casos de uso específicos
ALTER TABLE public.promotions 
ADD COLUMN IF NOT EXISTS applies_to text[] DEFAULT '{}', -- Qué aplica: ['registration', 'membership', 'both']
ADD COLUMN IF NOT EXISTS day_of_week integer, -- Día de la semana (0=domingo, 6=sábado) para promociones por día
ADD COLUMN IF NOT EXISTS time_start time, -- Hora de inicio para promociones por hora
ADD COLUMN IF NOT EXISTS time_end time, -- Hora de fin para promociones por hora
ADD COLUMN IF NOT EXISTS membership_types text[] DEFAULT '{}', -- Tipos de membresía que aplican
ADD COLUMN IF NOT EXISTS max_uses integer, -- Máximo número de veces que se puede usar
ADD COLUMN IF NOT EXISTS current_uses integer DEFAULT 0, -- Veces que se ha usado
ADD COLUMN IF NOT EXISTS conditions jsonb DEFAULT '{}'; -- Condiciones adicionales en formato JSON

-- Actualizar la descripción de discount_type para ser más claro
COMMENT ON COLUMN public.promotions.discount_type IS 'Tipo de descuento: percentage, fixed_amount, free_registration, free_membership';

-- Actualizar discount_value para que sea más flexible
COMMENT ON COLUMN public.promotions.discount_value IS 'Valor del descuento. Para percentage: 0-100, para fixed_amount: cantidad en pesos, para free_*: 0';

-- Agregar comentarios a los nuevos campos
COMMENT ON COLUMN public.promotions.applies_to IS 'Array que indica a qué aplica: registration, membership, both';
COMMENT ON COLUMN public.promotions.day_of_week IS 'Día de la semana (0=domingo, 1=lunes, ..., 6=sábado). NULL para todos los días';
COMMENT ON COLUMN public.promotions.time_start IS 'Hora de inicio para promociones por horario';
COMMENT ON COLUMN public.promotions.time_end IS 'Hora de fin para promociones por horario';
COMMENT ON COLUMN public.promotions.membership_types IS 'Array de tipos de membresía que aplican. Vacío para todos';
COMMENT ON COLUMN public.promotions.max_uses IS 'Máximo número de usos de la promoción. NULL para ilimitado';
COMMENT ON COLUMN public.promotions.current_uses IS 'Número actual de usos de la promoción';
COMMENT ON COLUMN public.promotions.conditions IS 'Condiciones adicionales en JSON';

-- Insertar promociones de ejemplo
INSERT INTO public.promotions (
  name, 
  description, 
  discount_type, 
  discount_value, 
  applies_to, 
  day_of_week, 
  is_active,
  start_date,
  end_date
) VALUES 
(
  'Sábados sin registro',
  'Los sábados no se cobra tarifa de registro, solo la membresía',
  'free_registration',
  0,
  ARRAY['registration'],
  6, -- Sábado
  true,
  now(),
  null -- Sin fecha de fin
),
(
  'Descuento estudiantes',
  '15% de descuento en membresías para estudiantes',
  'percentage',
  15,
  ARRAY['membership'],
  null, -- Todos los días
  true,
  now(),
  null
),
(
  '3x2 en membresías',
  'Paga 2 meses y obtén 3 meses de membresía',
  'fixed_amount',
  0, -- Se calcula dinámicamente
  ARRAY['membership'],
  null,
  true,
  now(),
  null
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_promotions_active ON public.promotions(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_promotions_dates ON public.promotions(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_promotions_day_of_week ON public.promotions(day_of_week) WHERE day_of_week IS NOT NULL;
