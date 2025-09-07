import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gymads/app/modules/clientes/services/qr_cache_service.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QrDialog extends StatefulWidget {
  final String nombre;
  final String telefono;
  final String userNumber;
  final double totalAmount;

  const QrDialog({
    super.key,
    required this.nombre,
    required this.telefono,
    required this.userNumber,
    required this.totalAmount,
  });

  @override
  State<QrDialog> createState() => _QrDialogState();
}

class _QrDialogState extends State<QrDialog> {
  final QrCacheService _qrCacheService = QrCacheService();
  File? _qrImageFile;
  bool _isLoading = true;
  bool _isSharingQr = false;

  @override
  void initState() {
    super.initState();
    _loadQrImage();
  }

  Future<void> _loadQrImage() async {
    try {
      final qrFile = await _qrCacheService.getQrImage(widget.userNumber);
      
      if (mounted) {
        setState(() {
          _qrImageFile = qrFile;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar imagen QR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadQr() async {
    if (_isSharingQr) return; // Evitar múltiples toques
    
    setState(() {
      _isSharingQr = true;
    });
    
    try {
      // Obtener el archivo QR de la caché o generarlo si no existe
      File? qrFile;
      
      // Si ya tenemos el archivo cacheado, lo usamos
      if (_qrImageFile != null) {
        qrFile = _qrImageFile;
      } else {
        // Si no, intentamos obtenerlo del cache service
        qrFile = await _qrCacheService.getQrImage(widget.userNumber);
      }

      if (qrFile == null || !await qrFile.exists()) {
        Get.snackbar(
          'Error',
          'No se pudo generar el código QR',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }

      // Crear nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'QR_${widget.nombre.replaceAll(' ', '_')}_${widget.userNumber}_$timestamp.png';
      
      // Crear archivo temporal en el directorio de cache para compartir
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      
      // Copiar el archivo QR al archivo temporal
      await qrFile.copy(tempFile.path);
      
      if (!await tempFile.exists()) {
        throw Exception('No se pudo crear el archivo temporal');
      }
      
      // Usar share_plus para compartir el archivo
      final result = await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Código QR de GymAds',
        text: 'Código QR de ${widget.nombre}',
      );
      
      if (result.status == ShareResultStatus.success) {
        Get.snackbar(
          'QR Compartido',
          'Código QR compartido exitosamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        // Manejar error de compartir silenciosamente
        print('Compartir QR: ${result.status}');
      }
    } catch (e) {
      print('Error al compartir QR: $e');
      Get.snackbar(
        'Error',
        'No se pudo compartir el código QR. Intenta nuevamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharingQr = false;
        });
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final message = '''Bienvenido a Fitness Ads

tu QR de identificación: https://fitnessads.web.app/${widget.userNumber}

Total pagado: \$${widget.totalAmount.toStringAsFixed(2)}''';

    // Codificar el mensaje para la URL
    final encodedMessage = Uri.encodeComponent(message);

    // Crear el enlace de WhatsApp con el número de teléfono y mensaje
    final whatsappUrl = 'https://wa.me/${widget.telefono}?text=$encodedMessage';

    // Abrir WhatsApp
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      Get.snackbar(
        'Error',
        'No se pudo abrir WhatsApp',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Código QR de Acceso',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.titleColor,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // QR Code Widget
                  _isLoading
                      ? Container(
                          width: 200,
                          height: 200,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : _qrImageFile != null
                          ? Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: FileImage(_qrImageFile!),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : QrImageView(
                              data: widget.userNumber,
                              version: QrVersions.auto,
                              size: 200.0,
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                            ),
                  const SizedBox(height: 12),
                  Text(
                    widget.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Usuario: ${widget.userNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total pagado: \$${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Botones de acción
            Row(
              children: [
                // Botón de WhatsApp
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openWhatsApp,
                    icon: Icon(
                      MdiIcons.whatsapp,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón de descarga
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadQr,
                    icon: _isSharingQr 
                        ? SizedBox(
                            width: 16, 
                            height: 16, 
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.download_outlined,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isSharingQr ? 'Procesando...' : 'Descargar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Botón de cerrar
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Cerrar',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
