import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class QrDialog extends StatelessWidget {
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

  Future<void> _openWhatsApp() async {
    final message = '''Bienvenido a Fitness Ads

tu QR de identificación: https://fitnessads.web.app/$userNumber

Total pagado: \$${totalAmount.toStringAsFixed(2)}''';

    // Codificar el mensaje para la URL
    final encodedMessage = Uri.encodeComponent(message);

    // Crear el enlace de WhatsApp con el número de teléfono y mensaje
    final whatsappUrl = 'https://wa.me/$telefono?text=$encodedMessage';

    // Abrir WhatsApp
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      Get.snackbar(
        'Error',
        'No se pudo abrir WhatsApp',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Código QR de Acceso',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  QrImageView(
                    data: userNumber,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Usuario: $userNumber',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Total pagado: \$${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openWhatsApp,
              icon: Icon(MdiIcons.whatsapp),
              label: const Text('Enviar por WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(200, 45),
              ),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
