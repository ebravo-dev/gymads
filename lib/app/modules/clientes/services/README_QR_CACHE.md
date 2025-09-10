# Sistema de Cache de QR Codes

## 📋 Descripción
El sistema de cache de QR codes permite almacenar las imágenes QR tanto localmente en el dispositivo como en Supabase Storage, evitando regenerarlas constantemente y mejorando el rendimiento.

## 🏗️ Arquitectura

### QrCacheService
- **Singleton**: Instancia única para toda la aplicación
- **Cache local**: Guarda imágenes en el directorio de documentos de la app
- **Backup en Supabase**: Sincroniza con el bucket `qrcodes`
- **Fallback**: Si no encuentra cache, genera una nueva imagen QR

### Flujo de Trabajo
1. **Verificación local**: Busca la imagen QR en cache local
2. **Descarga de Supabase**: Si no existe localmente, la descarga del storage
3. **Generación nueva**: Si no existe en ningún lado, genera y guarda nueva imagen
4. **Sincronización**: Sube automáticamente a Supabase para backup

## 🔧 Configuración

### Variables de Entorno (.env)
```env
SUPABASE_QR_BUCKET_NAME=qrcodes
```

### Inicialización (main.dart)
```dart
QrCacheService().initialize();
```

## 📱 Uso en QrDialog

El `QrDialog` ahora:
- Muestra un spinner mientras carga la imagen
- Usa la imagen cacheada si está disponible
- Genera y cachea nueva imagen si es necesario
- Mantiene tema oscuro consistente

### Estados del QR
- **Cargando**: Muestra CircularProgressIndicator
- **Imagen cacheada**: Muestra imagen desde File
- **Fallback**: Genera QR en tiempo real con QrImageView

## 🗂️ Estructura de Archivos

```
lib/
└── app/
    └── modules/
        └── clientes/
            └── services/
                └── qr_cache_service.dart
```

## 🎯 Beneficios

1. **Rendimiento**: No regenera QR en cada apertura del diálogo
2. **Consistencia**: Mismo QR siempre para cada usuario
3. **Offline**: Funciona sin conexión una vez cacheado
4. **Backup**: Sincronizado en Supabase para múltiples dispositivos
5. **Escalabilidad**: Evita saturar el servidor con generación de QR

## 🛠️ Métodos Principales

### QrCacheService
- `getQrImage(userNumber)`: Obtiene imagen QR (cache o nueva)
- `clearLocalCache()`: Limpia cache local
- `deleteQr(userNumber)`: Elimina QR específico
- `getQrPublicUrl(userNumber)`: URL pública del QR en Supabase

### Gestión Automática
- Cache local en: `{AppDocuments}/qr_cache/qr_{userNumber}.png`
- Storage remoto: `qrcodes/qr_{userNumber}.png`
- Eliminación automática al borrar usuario
