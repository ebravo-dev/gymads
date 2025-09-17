import 'package:get/get.dart';
import '../views/goodbye_view.dart';

class GoodbyeController extends GetxController {
  
  /// Mostrar pantalla de despedida
  static void showGoodbye() {
    Get.to(
      () => const GoodbyeView(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    );
  }
}