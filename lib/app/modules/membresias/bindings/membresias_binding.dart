import 'package:get/get.dart';
import '../controllers/membresias_controller.dart';
import '../../../data/providers/membership_type_provider.dart';

class MembresiasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MembershipTypeProvider>(
      () => MembershipTypeProvider(),
    );
    
    Get.lazyPut<MembresiasController>(
      () => MembresiasController(
        membershipProvider: Get.find<MembershipTypeProvider>(),
      ),
    );
  }
}
