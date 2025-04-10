import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? controller;
  List<CameraDescription> cameras = [];

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
      // Inicializar con la cámara trasera
      controller = CameraController(
        cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.high,
      );
      await controller?.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('Error al inicializar la cámara: $e');
      }
    }
  }

  Future<File?> takePhoto() async {
    if (controller?.value.isInitialized ?? false) {
      try {
        final XFile photo = await controller!.takePicture();

        // Crear un directorio temporal para la foto
        final Directory tempDir = await getTemporaryDirectory();
        final String tempPath = tempDir.path;
        final File photoFile = File(
          '$tempPath/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        // Copiar la foto al directorio temporal
        await File(photo.path).copy(photoFile.path);

        return photoFile;
      } catch (e) {
        if (kDebugMode) {
          print('Error al tomar la foto: $e');
        }
        return null;
      }
    }
    return null;
  }

  void dispose() {
    controller?.dispose();
  }
}
