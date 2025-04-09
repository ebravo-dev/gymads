import 'package:get/get.dart';

import '../controllers/checador_controller.dart';

class ChecadorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChecadorController>(
      () => ChecadorController(),
    );
  }
}
