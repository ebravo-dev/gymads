import 'package:get/get.dart';
import 'package:gymads/app/routes/app_pages.dart';

class NavigationController extends GetxController {
  static NavigationController get to => Get.find();
  
  final RxInt _currentIndex = 0.obs;
  
  int get currentIndex => _currentIndex.value;
  
  @override
  void onInit() {
    super.onInit();
    // Escuchar cambios de ruta
    ever(_currentIndex, _updateRoute);
  }
  
  void changeTab(int index) {
    _currentIndex.value = index;
  }
  
  void _updateRoute(int index) {
    switch (index) {
      case 0:
        if (Get.currentRoute != Routes.HOME) {
          Get.offAllNamed(Routes.HOME);
        }
        break;
      case 1:
        if (Get.currentRoute != Routes.CONFIGURACION) {
          Get.offAllNamed(Routes.CONFIGURACION);
        }
        break;
    }
  }
  
  void updateIndexFromRoute(String route) {
    switch (route) {
      case Routes.HOME:
        _currentIndex.value = 0;
        break;
      case Routes.CONFIGURACION:
        _currentIndex.value = 1;
        break;
      default:
        _currentIndex.value = 0;
    }
  }
}
