# Migración: Eliminación de Salidas

## Contexto
Se ha eliminado toda la funcionalidad de "salidas" del sistema. Ahora solo se registran **entradas**.

## Archivos de Migración

### 1. `remove_salidas_access_type.sql` (RECOMENDADO)
**Elimina completamente las salidas del sistema**

#### ¿Qué hace?
- ✅ Convierte TODOS los registros históricos de 'salida' a 'entrada' (opcional, comentado)
- ✅ Agrega un constraint CHECK que SOLO permite 'entrada'
- ✅ Establece 'entrada' como valor por defecto
- ✅ Hace el campo `access_type` NOT NULL

#### ¿Cuándo usar?
Úsalo si quieres **un sistema completamente limpio** donde:
- Solo existan registros de entrada
- Los datos históricos de salidas se conviertan a entradas
- Sea IMPOSIBLE insertar salidas accidentalmente

#### Cómo aplicar:
```sql
-- Ejecuta en tu consola SQL de Supabase:
-- 1. Si quieres convertir registros históricos, descomenta la línea de UPDATE
-- 2. Ejecuta todo el script
```

---

### 2. `remove_salidas_access_type_alternative.sql`
**Mantiene los registros históricos pero previene nuevos**

#### ¿Qué hace?
- ✅ Permite que los registros históricos de 'salida' permanezcan
- ✅ El constraint permite 'entrada' y 'salida' (para los históricos)
- ✅ Incluye un trigger opcional que PREVIENE nuevas inserciones de 'salida'
- ✅ Los registros de salida solo pueden existir como datos históricos

#### ¿Cuándo usar?
Úsalo si quieres **mantener el histórico intacto** donde:
- Los datos históricos permanecen sin cambios
- Los reportes históricos pueden seguir mostrando entradas y salidas
- Pero el sistema solo permitirá crear nuevas entradas

#### Cómo aplicar:
```sql
-- Ejecuta en tu consola SQL de Supabase:
-- 1. Ejecuta el script básico (permitirá entrada y salida)
-- 2. OPCIONAL: Descomenta y ejecuta el trigger si quieres prevención estricta
```

---

## Recomendación

### Usa `remove_salidas_access_type.sql` si:
- ✅ No necesitas los datos históricos de salidas
- ✅ Quieres reportes y estadísticas más simples
- ✅ Prefieres un sistema "limpio" desde cero

### Usa `remove_salidas_access_type_alternative.sql` si:
- ✅ Necesitas mantener el histórico exacto
- ✅ Tienes auditorías o reportes que requieren ver las salidas pasadas
- ✅ Quieres migrar gradualmente

---

## Impacto en la Aplicación

### Cambios ya realizados en Flutter:
- ✅ `rfid_checkin_controller.dart` - Solo registra entradas
- ✅ `checador_controller.dart` - Solo registra entradas
- ✅ `access_logs_view.dart` - Muestra solo estadísticas de entradas
- ✅ `access_logs_controller.dart` - Calcula solo estadísticas de entradas

### Código de base de datos que ya no se usa:
- `AccessLogService.determineAccessType()` - Ya no se llama
- `AccessLogService.isUserInside()` - Ya no se llama
- `AccessLogService.getUsersCurrentlyInside()` - Ya no se llama

Estos métodos todavía existen en el código pero ya no se invocan. Puedes eliminarlos si lo deseas.

---

## Pasos para Aplicar la Migración

1. **Decide qué migración usar** (lee las recomendaciones arriba)

2. **Haz un backup de tu base de datos**
   ```sql
   -- En Supabase SQL Editor, exporta la tabla access_logs
   -- Dashboard > Table Editor > access_logs > ... > Export to CSV
   ```

3. **Aplica la migración**
   - Ve a: Supabase Dashboard > SQL Editor
   - Copia el contenido del archivo de migración que elegiste
   - Pega y ejecuta

4. **Verifica**
   ```sql
   -- Verifica que el constraint se aplicó
   SELECT constraint_name, check_clause 
   FROM information_schema.check_constraints 
   WHERE constraint_schema = 'public' 
   AND constraint_name = 'access_logs_access_type_check';
   
   -- Verifica registros (si usaste la primera migración)
   SELECT access_type, COUNT(*) 
   FROM access_logs 
   GROUP BY access_type;
   ```

5. **Prueba en la app**
   - Registra una entrada por RFID
   - Registra una entrada por QR
   - Verifica que se guarden correctamente en la base de datos

---

## Rollback (Por si acaso)

Si necesitas revertir los cambios:

```sql
-- Eliminar el constraint
ALTER TABLE public.access_logs
DROP CONSTRAINT IF EXISTS access_logs_access_type_check;

-- Eliminar el trigger (si lo activaste)
DROP TRIGGER IF EXISTS prevent_salidas_trigger ON public.access_logs;
DROP FUNCTION IF EXISTS prevent_new_salidas();

-- Permitir NULL en access_type (si quieres volver al estado original)
ALTER TABLE public.access_logs
ALTER COLUMN access_type DROP NOT NULL;
```

---

## Notas Adicionales

- El campo `access_type` seguirá existiendo en la tabla
- Los registros nuevos siempre tendrán `access_type = 'entrada'`
- Si en el futuro necesitas reactivar salidas, solo hay que:
  1. Revertir la migración de base de datos
  2. Revertir los cambios en los controladores Flutter
