import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/providers/supabase/supabase_api_provider.dart';
import '../../../data/repositories/user_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar el provider concreto (SupabaseApiProvider) como implementación de ApiProvider
    Get.put<ApiProvider>(
      SupabaseApiProvider(
        table: 'users', // Nombre de la tabla en Supabase
      ),
      permanent: true,
    );

    // Registrar el repositorio que usará cualquier implementación de ApiProvider
    Get.put<UserRepository>(
      UserRepository(Get.find<ApiProvider>()),
      permanent: true,
    );

    // Registrar el controlador que usará el repositorio
    Get.put<HomeController>(HomeController());
  }
}
