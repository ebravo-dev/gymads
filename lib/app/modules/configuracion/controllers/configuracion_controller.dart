import 'package:get/get.dart';
import '../../../controllers/navigation_controller.dart';
import '../../../routes/app_pages.dart';

class ConfiguracionController extends GetxController {
  // Variables observables para la configuración
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Actualizar el índice de navegación cuando se inicialice la vista Configuración
    NavigationController.to.updateIndexFromRoute(Routes.CONFIGURACION);
  }

  @override
  void onReady() {
    super.onReady();
    // Llamadas que necesiten que la vista esté lista
  }

  @override
  void onClose() {
    super.onClose();
    // Limpieza de recursos
  }
}
