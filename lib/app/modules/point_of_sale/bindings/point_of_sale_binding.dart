import 'package:get/get.dart';
import '../controllers/point_of_sale_controller.dart';

class PointOfSaleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PointOfSaleController>(
      () => PointOfSaleController(),
    );
  }
}
