import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/data/models/ingreso_model.dart';
import 'package:gymads/app/data/services/ingreso_service.dart';

class IngresosController extends GetxController {
  final IngresoService ingresoService;

  IngresosController({required this.ingresoService});

  // Estado observable
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Datos de ingresos
  final Rx<EstadisticasIngresos> estadisticas = EstadisticasIngresos.empty().obs;
  final RxList<IngresoModel> ingresos = <IngresoModel>[].obs;
  final RxMap<String, double> datosGrafica = <String, double>{}.obs;
  
  // Filtros
  final selectedPeriodo = 'mes'.obs; // 'dia', 'semana', 'mes'
  final selectedConcepto = Rx<String?>(null);
  final selectedMetodoPago = Rx<String?>(null);
  final fechaInicio = Rx<DateTime?>(null);
  final fechaFin = Rx<DateTime?>(null);

  // Opciones para filtros
  final List<String> periodos = ['dia', 'semana', 'mes'];
  final List<String> conceptos = ['nuevo_registro', 'renovacion', 'registro'];
  final List<String> metodosPago = ['efectivo', 'tarjeta', 'transferencia'];

  @override
  void onInit() {
    super.onInit();
    // Inicializar con el mes actual
    final now = DateTime.now();
    fechaInicio.value = DateTime(now.year, now.month, 1);
    fechaFin.value = DateTime(now.year, now.month + 1, 0);
    
    // Cargar datos iniciales
    fetchEstadisticas();
    fetchIngresos();
    fetchDatosGrafica();
  }

  /// Obtiene las estadísticas de ingresos
  Future<void> fetchEstadisticas() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      print('📊 Obteniendo estadísticas de ingresos...');
      
      final stats = await ingresoService.getEstadisticas(
        fechaInicio: fechaInicio.value,
        fechaFin: fechaFin.value,
      );
      
      estadisticas.value = stats;
      print('✅ Estadísticas obtenidas: Total \$${stats.totalIngresos.toStringAsFixed(2)}');
      
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      errorMessage.value = 'Error al cargar estadísticas: $e';
      
      Get.snackbar(
        'Error',
        'Error al cargar estadísticas: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtiene la lista de ingresos
  Future<void> fetchIngresos() async {
    try {
      print('📋 Obteniendo lista de ingresos...');
      
      final listaIngresos = await ingresoService.getIngresos(
        fechaInicio: fechaInicio.value,
        fechaFin: fechaFin.value,
        concepto: selectedConcepto.value,
        metodoPago: selectedMetodoPago.value,
        limit: 50,
      );
      
      ingresos.assignAll(listaIngresos);
      print('✅ ${listaIngresos.length} ingresos obtenidos');
      
    } catch (e) {
      print('❌ Error al obtener ingresos: $e');
      errorMessage.value = 'Error al cargar ingresos: $e';
    }
  }

  /// Obtiene datos para la gráfica
  Future<void> fetchDatosGrafica() async {
    try {
      print('📈 Obteniendo datos para gráfica...');
      
      final datos = await ingresoService.getIngresosPorPeriodo(
        fechaInicio: fechaInicio.value ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
        fechaFin: fechaFin.value ?? DateTime.now(),
        agrupacion: selectedPeriodo.value,
      );
      
      datosGrafica.assignAll(datos);
      print('✅ Datos de gráfica obtenidos: ${datos.length} puntos');
      
    } catch (e) {
      print('❌ Error al obtener datos de gráfica: $e');
    }
  }

  /// Actualiza el período seleccionado y recarga datos
  void changePeriodo(String nuevoPeriodo) {
    selectedPeriodo.value = nuevoPeriodo;
    final now = DateTime.now();
    
    switch (nuevoPeriodo) {
      case 'dia':
        fechaInicio.value = DateTime(now.year, now.month, now.day);
        fechaFin.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'semana':
        final inicioSemana = now.subtract(Duration(days: now.weekday - 1));
        fechaInicio.value = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
        fechaFin.value = inicioSemana.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case 'mes':
        fechaInicio.value = DateTime(now.year, now.month, 1);
        fechaFin.value = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }
    
    refreshData();
  }

  /// Actualiza el filtro de concepto
  void changeConcepto(String? concepto) {
    selectedConcepto.value = concepto;
    fetchIngresos();
  }

  /// Actualiza el filtro de método de pago
  void changeMetodoPago(String? metodoPago) {
    selectedMetodoPago.value = metodoPago;
    fetchIngresos();
  }

  /// Establece un rango de fechas personalizado
  void setFechasPersonalizadas(DateTime inicio, DateTime fin) {
    fechaInicio.value = inicio;
    fechaFin.value = fin;
    refreshData();
  }

  /// Recarga todos los datos
  Future<void> refreshData() async {
    await Future.wait([
      fetchEstadisticas(),
      fetchIngresos(),
      fetchDatosGrafica(),
    ]);
  }

  /// Método público para refrescar datos desde otros módulos
  static Future<void> refreshIngresosGlobally() async {
    try {
      print('🔄 Iniciando refresh global de ingresos...');
      
      // Verificar si el controlador ya está registrado
      if (Get.isRegistered<IngresosController>()) {
        final controller = Get.find<IngresosController>();
        print('🔄 Controlador de ingresos encontrado, refrescando datos...');
        await controller.refreshData();
        print('✅ Datos de ingresos actualizados globalmente');
      } else {
        print('⚠️ IngresosController no está registrado aún. Los datos se actualizarán cuando se navegue a la pantalla de ingresos.');
      }
    } catch (e) {
      print('⚠️ No se pudo actualizar el controlador de ingresos: $e');
      print('📊 Error tipo: ${e.runtimeType}');
      // No lanzar excepción para no interrumpir el flujo principal
    }
  }

  /// Formatea un número como moneda
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Obtiene el color para un concepto
  Color getColorForConcepto(String concepto) {
    switch (concepto) {
      case 'nuevo_registro':
        return Colors.green;
      case 'renovacion':
        return Colors.blue;
      case 'registro':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Obtiene el color para un método de pago
  Color getColorForMetodoPago(String metodoPago) {
    switch (metodoPago) {
      case 'efectivo':
        return Colors.green;
      case 'tarjeta':
        return Colors.blue;
      case 'transferencia':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Calcula el porcentaje de crecimiento
  double calcularPorcentajeCrecimiento(double actual, double anterior) {
    if (anterior == 0) return actual > 0 ? 100 : 0;
    return ((actual - anterior) / anterior) * 100;
  }

  /// Lista filtrada de ingresos para mostrar
  List<IngresoModel> get ingresosFiltrados => ingresos;

  /// Indica si hay datos de ingresos
  bool get tieneIngresos => ingresos.isNotEmpty;

  /// Indica si hay datos para la gráfica
  bool get tieneDatosGrafica => datosGrafica.isNotEmpty;

  /// Total de ingresos del período actual
  double get totalIngresosActual => estadisticas.value.totalIngresos;

  /// Promedio de transacción
  double get promedioTransaccion => estadisticas.value.promedioTransaccion;

  /// Número total de transacciones
  int get totalTransacciones => estadisticas.value.totalTransacciones;
}
