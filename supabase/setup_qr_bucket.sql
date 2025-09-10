-- Script para configurar bucket de QR codes en Supabase
-- Ejecutar este script desde la consola SQL de Supabase

-- Crear bucket para QR si no existe
INSERT INTO storage.buckets (id, name, public)
VALUES ('qrcodes', 'qrcodes', TRUE)
ON CONFLICT (id) DO UPDATE SET public = TRUE;

-- Política para permitir lectura pública de QR
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies WHERE policyname = 'QR codes son accesibles públicamente'
  ) THEN
    CREATE POLICY "QR codes son accesibles públicamente" ON storage.objects
      FOR SELECT
      USING (bucket_id = 'qrcodes');
  END IF;
END
$$;

-- Política para permitir que usuarios autenticados suban QR
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies WHERE policyname = 'Staff puede subir QR codes'
  ) THEN
    CREATE POLICY "Staff puede subir QR codes" ON storage.objects
      FOR INSERT
      WITH CHECK (bucket_id = 'qrcodes' AND auth.role() = 'authenticated');
  END IF;
END
$$;
  
-- Política para permitir que usuarios autenticados actualicen QR
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies WHERE policyname = 'Staff puede actualizar QR codes'
  ) THEN
    CREATE POLICY "Staff puede actualizar QR codes" ON storage.objects
      FOR UPDATE
      WITH CHECK (bucket_id = 'qrcodes' AND auth.role() = 'authenticated');
  END IF;
END
$$;

-- Política para permitir que usuarios autenticados eliminen QR
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies WHERE policyname = 'Staff puede eliminar QR codes'
  ) THEN
    CREATE POLICY "Staff puede eliminar QR codes" ON storage.objects
      FOR DELETE
      USING (bucket_id = 'qrcodes' AND auth.role() = 'authenticated');
  END IF;
END
$$;
