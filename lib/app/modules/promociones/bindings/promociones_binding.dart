import 'package:get/get.dart';
import 'package:gymads/app/data/providers/promotion_provider.dart';
import 'package:gymads/app/data/providers/supabase/supabase_api_provider.dart';
import 'package:gymads/app/modules/promociones/controllers/promociones_controller.dart';

class PromocionesBinding extends Bindings {
  @override
  void dependencies() {
    // Provider para promociones usando Supabase
    Get.lazyPut<PromotionProvider>(
      () => PromotionProvider(
        SupabaseApiProvider(table: 'promotions'),
      ),
    );

    // Controlador de promociones
    Get.lazyPut<PromocionesController>(
      () => PromocionesController(
        promotionProvider: Get.find<PromotionProvider>(),
      ),
    );
  }
}
