import 'package:get/get.dart';
import '../../../controllers/navigation_controller.dart';
import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  // Estado observable para controlar cuando se está creando un usuario
  final RxBool isCreatingUser = false.obs;

  // Lista observable de mensajes de estado
  final RxList<String> statusMessages = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Actualizar el índice de navegación cuando se inicialice la vista Home
    NavigationController.to.updateIndexFromRoute(Routes.HOME);
  }

  // Funciones para manejar las opciones del menú
  void goToCheckIns() {
    statusMessages.add('Navegando a la pantalla de Check-Ins...');
    Get.toNamed(Routes.CHECADOR);
  }

  void goToRfidCheckIn() {
    statusMessages.add('Navegando a Control de Acceso RFID...');
    Get.toNamed(Routes.RFID_CHECKIN);
  }

  void goToPaymentRegistration() {
    statusMessages.add('Navegando a Registro de Pagos...');
    Get.toNamed(Routes.INGRESOS);
  }

  void goToClientes() {
    statusMessages.add('Navegando a Gestión de Clientes...');
    Get.toNamed(Routes.CLIENTES);
  }

  void goToInventario() {
    statusMessages.add('Navegando a Inventario...');
    Get.toNamed(Routes.INVENTARIO);
  }
  
  void goToMembresias() {
    statusMessages.add('Navegando a Gestión de Membresías...');
    Get.toNamed(Routes.MEMBRESIAS);
  }

  void goToPromociones() {
    statusMessages.add('Navegando a Gestión de Promociones...');
    Get.toNamed(Routes.PROMOCIONES);
  }

  /// Limpia los mensajes de estado
  void clearMessages() {
    statusMessages.clear();
  }
}
