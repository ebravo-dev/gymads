-- Crear tabla de ingresos para el módulo de gestión financiera
CREATE TABLE public.ingresos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  cliente_id uuid,
  cliente_nombre text NOT NULL,
  concepto text NOT NULL, -- 'registro', 'renovacion', 'producto', etc.
  tipo_membresia text NOT NULL,
  monto_base numeric NOT NULL,
  cuota_registro numeric DEFAULT 0,
  promocion_id uuid,
  promocion_nombre text,
  descuento numeric DEFAULT 0,
  monto_final numeric NOT NULL,
  metodo_pago text NOT NULL, -- 'efectivo', 'transferencia', 'tarjeta'
  fecha timestamp with time zone DEFAULT now(),
  periodo_inicio timestamp with time zone,
  periodo_fin timestamp with time zone,
  notas text,
  usuario_staff text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ingresos_pkey PRIMARY KEY (id),
  CONSTRAINT ingresos_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.users(id),
  CONSTRAINT ingresos_promocion_id_fkey FOREIGN KEY (promocion_id) REFERENCES public.promotions(id)
);

-- Índices para mejorar el rendimiento de consultas
CREATE INDEX idx_ingresos_fecha ON public.ingresos(fecha);
CREATE INDEX idx_ingresos_cliente_id ON public.ingresos(cliente_id);
CREATE INDEX idx_ingresos_concepto ON public.ingresos(concepto);
CREATE INDEX idx_ingresos_metodo_pago ON public.ingresos(metodo_pago);
CREATE INDEX idx_ingresos_usuario_staff ON public.ingresos(usuario_staff);
CREATE INDEX idx_ingresos_promocion_id ON public.ingresos(promocion_id);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at en ingresos
CREATE TRIGGER update_ingresos_updated_at 
    BEFORE UPDATE ON public.ingresos 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Políticas de seguridad RLS (Row Level Security)
ALTER TABLE public.ingresos ENABLE ROW LEVEL SECURITY;

-- Política para permitir lectura a usuarios autenticados
CREATE POLICY "Permitir lectura de ingresos a usuarios autenticados"
ON public.ingresos FOR SELECT
TO authenticated
USING (true);

-- Política para permitir inserción a usuarios autenticados
CREATE POLICY "Permitir inserción de ingresos a usuarios autenticados"
ON public.ingresos FOR INSERT
TO authenticated
WITH CHECK (true);

-- Política para permitir actualización a usuarios autenticados
CREATE POLICY "Permitir actualización de ingresos a usuarios autenticados"
ON public.ingresos FOR UPDATE
TO authenticated
USING (true);

-- Política para permitir eliminación a usuarios autenticados (solo para casos especiales)
CREATE POLICY "Permitir eliminación de ingresos a usuarios autenticados"
ON public.ingresos FOR DELETE
TO authenticated
USING (true);

-- Comentarios para documentar la tabla
COMMENT ON TABLE public.ingresos IS 'Tabla para registrar todos los ingresos del gimnasio';
COMMENT ON COLUMN public.ingresos.concepto IS 'Tipo de ingreso: registro, renovacion, producto, etc.';
COMMENT ON COLUMN public.ingresos.monto_base IS 'Monto base antes de descuentos';
COMMENT ON COLUMN public.ingresos.cuota_registro IS 'Cuota de registro cuando aplique';
COMMENT ON COLUMN public.ingresos.descuento IS 'Monto del descuento aplicado';
COMMENT ON COLUMN public.ingresos.monto_final IS 'Monto final cobrado al cliente';
COMMENT ON COLUMN public.ingresos.metodo_pago IS 'Método de pago utilizado';
COMMENT ON COLUMN public.ingresos.usuario_staff IS 'Usuario del staff que procesó el pago';
