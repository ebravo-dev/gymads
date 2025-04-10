# Este archivo define las políticas de seguridad para el bucket 'users'
# Ejecuta estas políticas en el editor SQL de Supabase

-- Permitir acceso al usuario autorizado
CREATE POLICY "Usuario autorizado puede administrar archivos"
ON storage.objects FOR ALL
USING (auth.uid()::text = '8037aa52-0185-421f-a97f-bc0eec0288a9');

-- Permitir acceso público de lectura a los archivos
CREATE POLICY "Acceso público de lectura"
ON storage.objects FOR SELECT
USING (bucket_id = 'users');

-- Habilitar RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
