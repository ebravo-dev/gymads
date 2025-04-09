import 'package:get/get.dart';

import '../controllers/ingresos_controller.dart';

class IngresosBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IngresosController>(
      () => IngresosController(),
    );
  }
}
