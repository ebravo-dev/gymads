import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CircularCameraView extends StatefulWidget {
  final Function(File) onPhotoTaken;
  final Function() onCancel;

  const CircularCameraView({
    super.key,
    required this.onPhotoTaken,
    required this.onCancel,
  });

  @override
  State<CircularCameraView> createState() => _CircularCameraViewState();
}

class _CircularCameraViewState extends State<CircularCameraView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  bool _usingFrontCamera = true; // Por defecto usar cámara frontal
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _errorMessage = null;
        _isInitialized = false;
      });

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No se encontraron cámaras disponibles');
      }

      // Seleccionar cámara (frontal por defecto)
      CameraDescription selectedCamera;
      if (_usingFrontCamera) {
        selectedCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );
      } else {
        selectedCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
      }

      await _controller?.dispose();
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al inicializar la cámara: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() {
      _usingFrontCamera = !_usingFrontCamera;
    });

    await _initializeCamera();
  }

  Future<void> _takePhoto() async {
    if (_isTakingPicture || !_isInitialized || _controller == null) return;

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final XFile photoFile = await _controller!.takePicture();

      // Crear archivo en directorio temporal
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = path.join(
        tempDir.path,
        'cliente_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final File resultFile = File(targetPath);
      await File(photoFile.path).copy(targetPath);

      if (await resultFile.exists() && mounted) {
        // Limpiar archivo temporal original
        try {
          await File(photoFile.path).delete();
        } catch (e) {
          // Ignorar errores al eliminar archivos temporales
        }

        widget.onPhotoTaken(resultFile);
      } else {
        throw Exception('No se pudo guardar la foto');
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'No se pudo tomar la foto: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Inicializando cámara...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Vista previa de la cámara a pantalla completa
        Positioned.fill(
          child: CameraPreview(_controller!),
        ),

        // Máscara circular con superposición
        Positioned.fill(
          child: CustomPaint(
            painter: CircularMaskPainter(),
          ),
        ),

        // Controles superiores
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botón cerrar
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              // Botón cambiar cámara
              if (_cameras.length > 1)
                IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
            ],
          ),
        ),

        // Instrucciones
        Positioned(
          top: 80,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Coloca la cara del cliente dentro del círculo',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Indicador de cámara activa
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _usingFrontCamera ? 'Cámara frontal' : 'Cámara trasera',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),

        // Botón de captura
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _isTakingPicture ? null : _takePhoto,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  color: _isTakingPicture
                      ? Colors.grey.withOpacity(0.5)
                      : Colors.white.withOpacity(0.3),
                ),
                child: _isTakingPicture
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error de Cámara',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _initializeCamera,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Painter para crear la máscara circular
class CircularMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    
    // Hacer el círculo adaptable al tamaño de la pantalla
    final double radius = size.width < size.height
        ? size.width * 0.35  // En orientación vertical
        : size.height * 0.35; // En orientación horizontal

    // Crear path para el círculo
    final Path circlePath = Path()
      ..addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius));

    // Crear path para toda la pantalla
    final Path screenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Restar el círculo de la pantalla para crear el agujero
    final Path maskPath = Path.combine(
      PathOperation.difference,
      screenPath,
      circlePath,
    );

    // Dibujar la máscara semitransparente
    canvas.drawPath(
      maskPath,
      Paint()..color = Colors.black.withOpacity(0.6),
    );

    // Dibujar el borde del círculo
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Añadir puntos de referencia para alinear la cara
    final Paint dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final double dotRadius = 2.5;
    final double guideRadius = radius * 0.75;

    // Puntos de guía (ojos y boca aproximadamente)
    // Punto superior (frente)
    canvas.drawCircle(
      Offset(centerX, centerY - guideRadius * 0.6),
      dotRadius,
      dotPaint,
    );

    // Puntos laterales (orejas aproximadamente)
    canvas.drawCircle(
      Offset(centerX - guideRadius * 0.8, centerY - guideRadius * 0.2),
      dotRadius,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(centerX + guideRadius * 0.8, centerY - guideRadius * 0.2),
      dotRadius,
      dotPaint,
    );

    // Punto inferior (barbilla)
    canvas.drawCircle(
      Offset(centerX, centerY + guideRadius * 0.8),
      dotRadius,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
