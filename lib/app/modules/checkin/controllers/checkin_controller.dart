import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CheckinController extends GetxController {
  final isScanning = true.obs;
  final scanMessage = ''.obs;
  final userName = ''.obs;
  final daysLeft = 0.obs;
  final isShowingDialog = false.obs;

  void onDetect(BarcodeCapture capture) async {
    if (isShowingDialog.value) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue == null) continue;
      
      // TODO: Aquí irá la lógica para verificar el QR con Firebase
      // Por ahora simulamos datos de prueba
      userName.value = "Usuario de Prueba";
      daysLeft.value = 15;
      
      isShowingDialog.value = true;
      
      // Mostrar el diálogo por 4 segundos
      await Future.delayed(const Duration(seconds: 4));
      Get.back(); // Cierra el diálogo
      isShowingDialog.value = false;
    }
  }
}