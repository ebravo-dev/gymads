import 'package:get/get.dart';

import '../modules/checador/bindings/checador_binding.dart';
import '../modules/checador/views/checador_view.dart';
import '../modules/clientes/bindings/clientes_binding.dart';
import '../modules/clientes/views/clientes_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/ingresos/bindings/ingresos_binding.dart';
import '../modules/ingresos/views/ingresos_view.dart';
import '../modules/inventario/bindings/inventario_binding.dart';
import '../modules/inventario/views/inventario_view.dart';
import '../modules/inventario/views/product_form_view.dart';
import '../modules/checkin/bindings/checkin_binding.dart';
import '../modules/checkin/views/checkin_view.dart';
import '../modules/rfid_checkin/bindings/rfid_checkin_binding.dart';
import '../modules/rfid_checkin/views/rfid_checkin_view.dart';
import '../modules/membresias/bindings/membresias_binding.dart';
import '../modules/membresias/views/membresias_view.dart';
import '../modules/promociones/bindings/promociones_binding.dart';
import '../modules/promociones/views/promociones_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.CHECADOR,
      page: () => const ChecadorView(),
      binding: ChecadorBinding(),
    ),
    GetPage(
      name: _Paths.CLIENTES,
      page: () => const ClientesView(),
      binding: ClientesBinding(),
    ),
    GetPage(
      name: _Paths.INVENTARIO,
      page: () => const InventarioView(),
      binding: InventarioBinding(),
    ),
    GetPage(
      name: _Paths.PRODUCT_FORM,
      page: () => const ProductFormView(),
      binding: InventarioBinding(),
    ),
    GetPage(
      name: _Paths.INGRESOS,
      page: () => const IngresosView(),
      binding: IngresosBinding(),
    ),
    GetPage(
      name: _Paths.CHECKIN,
      page: () => const CheckinView(),
      binding: CheckinBinding(),
    ),
    GetPage(
      name: _Paths.RFID_CHECKIN,
      page: () => const RfidCheckinView(),
      binding: RfidCheckinBinding(),
    ),
    GetPage(
      name: _Paths.MEMBRESIAS,
      page: () => const MembresiasView(),
      binding: MembresiasBinding(),
    ),
    GetPage(
      name: _Paths.PROMOCIONES,
      page: () => const PromocionesView(),
      binding: PromocionesBinding(),
    ),
  ];
}
