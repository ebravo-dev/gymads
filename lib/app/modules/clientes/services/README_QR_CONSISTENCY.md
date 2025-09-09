# Guía de Consistencia QR

## Problema resuelto
Se corrigió la inconsistencia entre los códigos QR mostrados en la aplicación y los guardados en Supabase/caché local.

## Causas del problema
La inconsistencia entre los códigos QR se debía a que se utilizaban diferentes parámetros para generar el QR en:
1. `QrCacheService._generateQrBytes()`: donde se generaba y guardaba el código QR
2. `QrDialog`: donde se mostraba el QR mediante QrImageView cuando no existía en caché

## Solución implementada
Se unificaron los parámetros de generación de QR para asegurar que tanto el QR almacenado como el mostrado sean idénticos:

### Parámetros unificados:
- **data**: userNumber (identificador único del usuario)
- **version**: QrVersions.auto (determina automáticamente la versión óptima)
- **foregroundColor/color**: Colors.black
- **backgroundColor/emptyColor**: Colors.white
- **gapless**: false (importante para la consistencia visual)
- **errorCorrectionLevel**: QrErrorCorrectLevel.M (nivel medio de corrección de errores)

### Archivos modificados:
- `qr_dialog.dart`: Se añadieron los parámetros `gapless: false` y `errorCorrectionLevel: QrErrorCorrectLevel.M`
- `qr_cache_service.dart`: Ya tenía los parámetros correctos, pero se verificó su consistencia

## Verificación
Ahora el código QR generado y almacenado en Supabase/caché coincide exactamente con el mostrado en la app, asegurando:
1. Que el QR escaneado funcione correctamente 
2. Que la experiencia visual sea consistente
3. Que el QR descargado/compartido sea idéntico al mostrado

## Recomendaciones
Si se necesita modificar la generación de códigos QR en el futuro:
1. Siempre modificar ambos lugares (`QrCacheService` y `QrDialog`)
2. Mantener los mismos parámetros para asegurar la consistencia
3. No cambiar `gapless: false` ni `errorCorrectionLevel: QrErrorCorrectLevel.M` sin actualizar ambos lugares

## Parámetros técnicos
```dart
// En QrCacheService._generateQrBytes():
final qrPainter = QrPainter(
  data: userNumber,
  version: QrVersions.auto,
  color: Colors.black,
  emptyColor: Colors.white,
  gapless: false,
  errorCorrectionLevel: QrErrorCorrectLevel.M,
);

// En QrDialog:
QrImageView(
  data: widget.userNumber,
  version: QrVersions.auto,
  size: 200.0,
  foregroundColor: Colors.black,
  backgroundColor: Colors.white,
  gapless: false,
  errorCorrectionLevel: QrErrorCorrectLevel.M,
)
```

> **Nota**: La diferencia de tamaño (200 vs 512) no afecta la consistencia del patrón QR, solo su resolución.
