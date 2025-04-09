import 'package:get/get.dart';
import 'package:gymads/app/data/providers/firebase/firebase_api_provider.dart';
import 'package:gymads/app/data/repositories/user_repository.dart';

import '../controllers/clientes_controller.dart';

class ClientesBinding extends Bindings {
  @override
  void dependencies() {
    // Inyectar el provider para Firebase (o cualquier otra API que estés usando)
    Get.lazyPut<FirebaseApiProvider>(
      () => FirebaseApiProvider(
        idProject:
            'gymads-app', // ID del proyecto Firebase (reemplaza con tu ID real)
        model: 'users', // Colección 'users' en Firestore
      ),
    );

    // Inyectar el repositorio de usuarios
    Get.lazyPut<UserRepository>(
      () => UserRepository(Get.find<FirebaseApiProvider>()),
    );

    // Inyectar el controlador de clientes
    Get.lazyPut<ClientesController>(
      () => ClientesController(userRepository: Get.find<UserRepository>()),
    );
  }
}
