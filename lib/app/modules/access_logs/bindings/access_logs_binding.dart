import 'package:get/get.dart';
import '../controllers/access_logs_controller.dart';

class AccessLogsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccessLogsController>(
      () => AccessLogsController(),
    );
  }
}
