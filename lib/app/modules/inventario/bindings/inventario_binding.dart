import 'package:get/get.dart';

import '../controllers/inventario_controller.dart';

class InventarioBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventarioController>(
      () => InventarioController(),
    );
  }
}
