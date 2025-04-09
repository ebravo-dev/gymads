import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/providers/firebase/firebase_api_provider.dart';
import '../../../data/repositories/user_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar el provider concreto (FirebaseApiProvider) como implementación de ApiProvider
    // Si en el futuro quieres cambiar a otro proveedor, solo debes modificar esta línea
    Get.put<ApiProvider>(
      FirebaseApiProvider(
        model: 'users', // Nombre de la colección en Firebase
        idProject: 'gymads-1f6e6',
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
