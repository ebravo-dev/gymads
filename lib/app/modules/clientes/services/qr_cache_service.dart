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
  Future<File?> getQrImage(String userNumber) async {
    try {
      // Verificar si existe en cache local
      final localFile = await _getLocalQrFile(userNumber);
      if (await localFile.exists()) {
        return localFile;
      }

      // Si no existe localmente, intentar descargar de Supabase
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

  /// Genera un nuevo QR, lo guarda en cache local y lo sube a Supabase
  Future<File?> _generateAndCacheQr(String userNumber) async {
    try {
      // Generar imagen QR
      final qrBytes = await _generateQrBytes(userNumber);
      
      // Guardar en cache local
      final localFile = await _getLocalQrFile(userNumber);
      await localFile.writeAsBytes(qrBytes);

      // Subir a Supabase
      await _uploadQrToSupabase(userNumber, qrBytes);

      return localFile;
    } catch (e) {
      print('Error al generar y cachear QR: $e');
      return null;
    }
  }

  /// Genera los bytes de la imagen QR
  Future<Uint8List> _generateQrBytes(String userNumber) async {
    final qrPainter = QrPainter(
      data: userNumber,
      version: QrVersions.auto,
      color: Colors.black,
      emptyColor: Colors.white,
    );

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(400, 400);
    
    qrPainter.paint(canvas, size);
    
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
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
    try {
      final fileName = 'qr_$userNumber.png';
      
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(fileName, qrBytes, 
              fileOptions: const FileOptions(
                contentType: 'image/png',
                upsert: true,
              ));
              
      print('QR subido exitosamente a Supabase: $fileName');
    } on StorageException catch (e) {
      if (e.statusCode == '403') {
        print('⚠️ Sin permisos para subir QR a Supabase. Verifica las políticas del bucket.');
        print('💡 Ejecuta el archivo: supabase/setup_qr_bucket.sql');
      } else {
        print('Error de Storage al subir QR: ${e.message} (${e.statusCode})');
      }
      // No lanzamos el error para no afectar la funcionalidad local
    } catch (e) {
      print('Error general al subir QR a Supabase: $e');
      // No lanzamos el error para no afectar la funcionalidad local
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
