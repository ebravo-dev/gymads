import 'package:get/get.dart';
import 'package:gymads/app/data/providers/supabase/supabase_api_provider.dart';
import 'package:gymads/app/data/repositories/user_repository.dart';
import 'package:gymads/app/data/providers/membership_type_provider.dart';
import 'package:gymads/app/data/providers/promotion_provider.dart';
import 'package:gymads/app/data/services/promotion_service.dart';

import '../controllers/clientes_controller.dart';

class ClientesBinding extends Bindings {
  @override
  void dependencies() {
    // Inyectar el provider para Supabase
    Get.lazyPut<SupabaseApiProvider>(
      () => SupabaseApiProvider(
        table: 'users', // Tabla 'users' en Supabase
      ),
    );

    // Inyectar el repositorio de usuarios
    Get.lazyPut<UserRepository>(
      () => UserRepository(Get.find<SupabaseApiProvider>()),
    );

    // Inyectar el provider de tipos de membresía
    Get.lazyPut<MembershipTypeProvider>(
      () => MembershipTypeProvider(),
    );

    // Inyectar el provider de promociones
    Get.lazyPut<PromotionProvider>(
      () => PromotionProvider(
        SupabaseApiProvider(table: 'promotions'),
      ),
    );

    // Inyectar el servicio de promociones
    Get.lazyPut<PromotionService>(
      () => PromotionService(Get.find<PromotionProvider>()),
    );

    // Inyectar el controlador de clientes
    Get.lazyPut<ClientesController>(
      () => ClientesController(
        userRepository: Get.find<UserRepository>(),
        membershipProvider: Get.find<MembershipTypeProvider>(),
      ),
    );
  }
}
