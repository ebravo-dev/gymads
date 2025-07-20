import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/providers/supabase/supabase_api_provider.dart';
import '../../../data/repositories/user_repository.dart';
import '../controllers/rfid_checkin_controller.dart';

class RfidCheckinBinding extends Bindings {
  @override
  void dependencies() {
    // Usar el ApiProvider si ya está registrado, si no, crear uno nuevo
    if (!Get.isPrepared<ApiProvider>()) {
      Get.put<ApiProvider>(
        SupabaseApiProvider(
          table: 'users',
        ),
        permanent: true,
      );
    }

    // Usar el UserRepository si ya está registrado, si no, crear uno nuevo
    if (!Get.isPrepared<UserRepository>()) {
      Get.put<UserRepository>(
        UserRepository(Get.find<ApiProvider>()),
        permanent: true,
      );
    }

    Get.lazyPut<RfidCheckinController>(
      () => RfidCheckinController(userRepository: Get.find<UserRepository>()),
    );
  }
}
