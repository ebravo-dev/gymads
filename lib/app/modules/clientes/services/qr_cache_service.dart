import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class QrCacheService {
  static final _instance = QrCacheService._internal();
  factory QrCacheService() => _instance;
  QrCacheService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  String? _bucketName;

  void initialize() {
    _bucketName ??= dotenv.env['SUPABASE_QR_BUCKET_NAME'] ?? 'qrcodes';
  }

  String get bucketName {
    if (_bucketName == null) {
      initialize();
    }
    return _bucketName!;
  }

  /// Obtiene la imagen QR desde cache local, o la descarga de Supabase si no existe
  Future<File?> getQrImage(String userNumber, {bool forceRegenerate = false}) async {
    try {
      // Si se solicita regeneración, saltarse cache y Supabase
      if (forceRegenerate) {
        return await _generateAndCacheQr(userNumber);
      }
      
      // Verificar si existe en cache local
      final localFile = await _getLocalQrFile(userNumber);
      if (await localFile.exists()) {
        // Verificar que el archivo no esté corrupto
        try {
          final fileBytes = await localFile.readAsBytes();
          if (fileBytes.isNotEmpty) {
            return localFile;
          }
          // Si está vacío o no se puede leer, regenerar
          print('QR local corrupto o vacío, regenerando: $userNumber');
        } catch (e) {
          print('Error al leer QR local, regenerando: $e');
        }
      }

      // Si no existe localmente o está corrupto, intentar descargar de Supabase
      final downloadedFile = await _downloadQrFromSupabase(userNumber);
      if (downloadedFile != null) {
        return downloadedFile;
      }

      // Si no existe en Supabase, generar y guardar nuevo QR
      return await _generateAndCacheQr(userNumber);
    } catch (e) {
      print('Error al obtener QR: $e');
      // En caso de error, generar QR temporal
      return await _generateAndCacheQr(userNumber);
    }
  }
  
  /// Actualiza o crea un nuevo QR con bytes proporcionados externamente
  Future<File?> updateQrWithBytes(String userNumber, Uint8List qrBytes) async {
    try {
      // Guardar en cache local
      final localFile = await _getLocalQrFile(userNumber);
      await localFile.writeAsBytes(qrBytes, flush: true);

      // Verificar si ya existe en Supabase antes de subir
      final existsInSupabase = await _qrExistsInSupabase(userNumber);
      
      // Solo subir si no existe ya en Supabase
      if (!existsInSupabase) {
        await _uploadQrToSupabase(userNumber, qrBytes);
      } else {
        print('✅ QR para $userNumber ya existe en Supabase, usando versión local');
      }

      return localFile;
    } catch (e) {
      print('Error al actualizar QR con bytes externos: $e');
      return null;
    }
  }

  /// Verifica si un QR ya existe en Supabase
  Future<bool> _qrExistsInSupabase(String userNumber) async {
    try {
      final fileName = 'qr_$userNumber.png';
      
      // Utilizar headObject para verificar si el archivo existe
      // Esta función lanzará un error si el archivo no existe
      await _supabase.storage
          .from(bucketName)
          .download(fileName);
      
      // Si llegamos aquí sin excepción, el archivo existe
      return true;
    } on StorageException catch (e) {
      if (e.statusCode == '404') {
        // El archivo no existe
        return false;
      }
      
      // Para otros errores, asumimos que podría existir pero tenemos problemas de permisos
      print('Error al verificar QR en Supabase: ${e.message}');
      return false;
    } catch (e) {
      // Para errores generales, asumimos que el archivo no existe
      print('Error general al verificar QR en Supabase: $e');
      return false;
    }
  }

  /// Genera un nuevo QR, lo guarda en cache local y lo sube a Supabase
  Future<File?> _generateAndCacheQr(String userNumber) async {
    try {
      // Generar imagen QR
      final qrBytes = await _generateQrBytes(userNumber);
      
      // Guardar en cache local
      final localFile = await _getLocalQrFile(userNumber);
      await localFile.writeAsBytes(qrBytes, flush: true);
      
      // Verificar que el archivo se escribió correctamente
      if (!await localFile.exists() || (await localFile.length()) == 0) {
        print('⚠️ Error: Archivo QR no se guardó correctamente');
        // Intento alternativo de guardar el archivo
        try {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_qr_$userNumber.png');
          await tempFile.writeAsBytes(qrBytes, flush: true);
          
          if (await tempFile.exists() && (await tempFile.length()) > 0) {
            // Si el archivo temporal se guardó bien, copiar a la ubicación original
            await tempFile.copy(localFile.path);
            print('✅ QR guardado usando método alternativo');
          }
        } catch (e) {
          print('Error en guardado alternativo: $e');
        }
      }

      // Verificar si ya existe en Supabase antes de subir
      final existsInSupabase = await _qrExistsInSupabase(userNumber);
      
      // Subir a Supabase solo si el archivo local se guardó bien Y no existe en Supabase
      if (await localFile.exists() && (await localFile.length()) > 0 && !existsInSupabase) {
        await _uploadQrToSupabase(userNumber, qrBytes);
      } else if (existsInSupabase) {
        print('✅ QR para $userNumber ya existe en Supabase, usando versión local');
      }

      return localFile;
    } catch (e) {
      print('Error al generar y cachear QR: $e');
      return null;
    }
  }

  /// Genera los bytes de la imagen QR
  Future<Uint8List> _generateQrBytes(String userNumber) async {
    print('🔧 DEBUG: Generando QR para userNumber: $userNumber');
    
    // NOTA: Estos parámetros DEBEN ser exactamente iguales a los usados en 
    // QrImageView en QrDialog y también en QrDialog._generateVisualQrImage
    final qrPainter = QrPainter(
      data: userNumber,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
      color: Colors.black,
      emptyColor: Colors.white,
      gapless: false,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(512, 512); // Tamaño más grande para mejor calidad
    
    // Fondo blanco explícito para asegurar contraste
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    qrPainter.paint(canvas, size);
    
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    
    // Usar PNG como formato de imagen
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('No se pudo generar la imagen QR');
    }
    
    final qrBytes = byteData.buffer.asUint8List();
    print('✅ QR generado: ${qrBytes.length} bytes para userNumber: $userNumber');
    
    return qrBytes;
  }

  /// Obtiene la ruta del archivo QR local
  Future<File> _getLocalQrFile(String userNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    final qrDir = Directory('${directory.path}/qr_cache');
    
    if (!await qrDir.exists()) {
      await qrDir.create(recursive: true);
    }
    
    return File('${qrDir.path}/qr_$userNumber.png');
  }

  /// Descarga el QR desde Supabase
  Future<File?> _downloadQrFromSupabase(String userNumber) async {
    try {
      final fileName = 'qr_$userNumber.png';
      final response = await _supabase.storage
          .from(bucketName)
          .download(fileName);

      final localFile = await _getLocalQrFile(userNumber);
      await localFile.writeAsBytes(response);
      
      print('QR descargado exitosamente desde Supabase: $fileName');
      return localFile;
    } on StorageException catch (e) {
      if (e.statusCode == '404') {
        print('QR no encontrado en Supabase (normal en primera generación): $userNumber');
      } else {
        print('Error de Storage al descargar QR: ${e.message} (${e.statusCode})');
      }
      return null;
    } catch (e) {
      print('Error general al descargar QR: $e');
      return null;
    }
  }

  /// Sube el QR a Supabase
  Future<void> _uploadQrToSupabase(String userNumber, Uint8List qrBytes) async {
    final fileName = 'qr_$userNumber.png';
    
    try {
      // Intentamos subir el archivo al bucket directamente sin verificar primero
      // Si hay un error de permisos o bucket inexistente, lo capturaremos después
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(fileName, qrBytes, 
              fileOptions: const FileOptions(
                contentType: 'image/png',
                upsert: true,
              ));
              
      print('✅ QR subido exitosamente a Supabase: $fileName (almacenado en caché local para acceso rápido)');
    } on StorageException catch (e) {
      // Para código 403, asumimos que el QR ya está en Supabase o no tenemos permisos
      if (e.statusCode == '403' && e.message.contains('row-level security policy')) {
        // Este error ocurre cuando el bucket existe pero no tenemos permisos de inserción
        // Es normal si el usuario no es administrador pero el bucket está configurado correctamente
        print('⚠️ Permiso denegado al subir a Supabase. El QR sigue disponible localmente.');
        print('💡 Para arreglar esto, ejecuta el script: supabase/setup_qr_bucket.sql');
      } else if (e.statusCode == '404') {
        // El bucket no existe
        print('⚠️ El bucket "$bucketName" no existe en Supabase.');
        print('💡 Ejecuta el script: supabase/setup_qr_bucket.sql para crearlo');
      } else {
        print('Error de Storage al subir QR: ${e.message} (${e.statusCode})');
      }
      // No lanzamos el error para no afectar la funcionalidad local
    } catch (e) {
      // Otros errores no deberían afectar la funcionalidad local
      print('Error general al subir QR a Supabase: $e');
      print('⚠️ El QR sigue disponible localmente, pero no se sincronizó con la nube');
    }
  }

  /// Limpia el cache local de QR codes
  Future<void> clearLocalCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final qrDir = Directory('${directory.path}/qr_cache');
      
      if (await qrDir.exists()) {
        await qrDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error al limpiar cache: $e');
    }
  }

  /// Elimina un QR específico del cache local y de Supabase
  Future<void> deleteQr(String userNumber) async {
    try {
      // Eliminar de cache local
      final localFile = await _getLocalQrFile(userNumber);
      if (await localFile.exists()) {
        await localFile.delete();
      }

      // Eliminar de Supabase
      final fileName = 'qr_$userNumber.png';
      await _supabase.storage
          .from(bucketName)
          .remove([fileName]);
          
    } catch (e) {
      print('Error al eliminar QR: $e');
    }
  }

  /// Obtiene la URL pública del QR desde Supabase
  Future<String?> getQrPublicUrl(String userNumber) async {
    try {
      final fileName = 'qr_$userNumber.png';
      final response = _supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);
          
      return response;
    } catch (e) {
      print('Error al obtener URL pública: $e');
      return null;
    }
  }
}
