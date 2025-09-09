# Script de Validación de QR Codes

## Checklist de Pruebas

### ✅ 1. Compilación y Ejecución
- [x] Eliminar dependencia `image_gallery_saver`
- [x] Actualizar SDK de Android a 35
- [x] Compilación exitosa sin errores
- [x] Aplicación se ejecuta sin crashes

### 🔄 2. Creación de Cliente
**Pasos a seguir:**
1. Abrir aplicación
2. Ir a sección "Clientes"
3. Crear nuevo cliente
4. Verificar que se muestre QR dialog
5. Observar logs de pre-generación

**Logs esperados:**
```
🔧 DEBUG: Pre-generando QR para nuevo cliente: [CODIGO]
🔧 DEBUG: Solicitando QR para userNumber: [CODIGO]
🔧 DEBUG: Generando nuevo QR para userNumber: [CODIGO]
✅ QR generado: [X] bytes para userNumber: [CODIGO]
✅ QR guardado en cache local: [PATH] ([X] bytes)
✅ QR pre-generado exitosamente para: [CODIGO]
```

### 🔄 3. Calidad del QR
**Verificaciones:**
- [ ] QR se muestra claramente en dialog
- [ ] Resolución nítida (512x512)
- [ ] Contraste adecuado (negro sobre blanco)
- [ ] Bordes definidos
- [ ] Sin pixelado excesivo

### 🔄 4. Funcionalidad de Descarga
**Pasos:**
1. En QR dialog, tocar "Descargar"
2. Verificar que se muestre selector de compartir
3. Elegir "Guardar en galería" o "Archivos"
4. Confirmar que archivo se guarda correctamente

**Logs esperados:**
```
✅ QR compartido exitosamente
```

### 🔄 5. Escaneo de QR
**Validación crítica:**
1. Usar cualquier app de escáner QR
2. Escanear el QR generado
3. Verificar que detecta el código del usuario
4. Confirmar que el código coincide con `userNumber`

**Resultado esperado:**
- QR debe ser detectado inmediatamente
- Debe mostrar el código alfanumérico del usuario (ej: "P8Z9E")
- No debe mostrar errores de formato

### 🔄 6. Sincronización Supabase
**Verificaciones:**
1. Crear cliente → Verificar que QR se sube a Supabase
2. Borrar cache local → Verificar que QR se descarga de Supabase
3. Usar botón "Regenerar QR" → Verificar que se actualiza en Supabase

**Logs esperados:**
```
✅ QR subido exitosamente a Supabase: qr_[CODIGO].png
✅ QR descargado exitosamente desde Supabase: qr_[CODIGO].png ([X] bytes)
```

### 🔄 7. Casos Edge
**Probar:**
- [ ] Sin conexión a internet
- [ ] QR cache corrupto
- [ ] Regenerar QR múltiples veces
- [ ] QR de cliente existente vs nuevo

## Comandos de Debug

### Limpiar cache para pruebas
```bash
# Hot reload para aplicar cambios
r

# Hot restart para reset completo  
R

# Ver logs en tiempo real
# (ya visible en terminal)
```

### Verificar archivos QR en dispositivo
```dart
// En el código, agregar prints para ver rutas:
print('QR cache directory: ${qrDir.path}');
print('QR file path: ${localFile.path}');
```

## Resultados Esperados

### ✅ Éxito
- QR se genera en <2 segundos
- QR es escaneable por cualquier app
- Archivo se guarda/comparte correctamente
- Cache funciona local y remotamente
- Logs muestran proceso completo sin errores

### ❌ Falla - Investigar
- QR no se detecta por escáner
- Errores en logs de generación
- Archivos no se guardan
- Sincronización Supabase falla

## Acciones si hay Problemas

1. **QR no escaneable:**
   - Verificar configuración QrPainter
   - Aumentar nivel de corrección de errores
   - Verificar contraste y resolución

2. **Errores de cache:**
   - Limpiar cache local
   - Verificar permisos de escritura
   - Regenerar QR

3. **Problemas Supabase:**
   - Verificar conectividad
   - Revisar políticas de bucket
   - Validar configuración .env

---
*Ejecutar este checklist después de cada cambio significativo*
