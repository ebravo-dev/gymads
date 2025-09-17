import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/models/access_log_model.dart';
import '../../../data/services/access_log_service.dart';

class AccessLogsController extends GetxController {
  // Estados reactivos
  final isLoading = false.obs;
  final accessLogs = <AccessLogModel>[].obs;
  final errorMessage = ''.obs;
  
  // Estadísticas
  final totalEntries = 0.obs;
  final totalExits = 0.obs;
  final totalQrAccesses = 0.obs;
  final totalRfidAccesses = 0.obs;
  final usersCurrentlyInside = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadAccessLogs();
  }

  /// Cargar logs de acceso desde Supabase
  Future<void> loadAccessLogs() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      if (kDebugMode) {
        print('📊 Cargando logs de acceso desde Supabase...');
      }

      final logs = await AccessLogService.getAllAccessLogs();
      
      if (logs != null && logs.isNotEmpty) {
        accessLogs.value = logs;
        calculateStatistics();
        
        if (kDebugMode) {
          print('✅ ${logs.length} logs de acceso cargados exitosamente');
        }
      } else if (logs != null && logs.isEmpty) {
        // Caso donde la consulta fue exitosa pero no hay datos
        accessLogs.clear();
        errorMessage.value = '';
        
        if (kDebugMode) {
          print('ℹ️ No se encontraron logs de acceso en la base de datos');
        }
      } else {
        // Caso donde hubo un error en la consulta
        errorMessage.value = 'No se pudieron cargar los logs de acceso';
        accessLogs.clear();
        
        if (kDebugMode) {
          print('❌ Error: No se pudieron cargar los logs');
        }
      }
    } catch (e) {
      errorMessage.value = 'Error al cargar logs: ${e.toString()}';
      accessLogs.clear();
      
      if (kDebugMode) {
        print('❌ Excepción al cargar logs: $e');
      }
      
      // Mostrar snackbar de error
      Get.snackbar(
        'Error',
        'No se pudieron cargar los registros de acceso: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Calcular estadísticas
  void calculateStatistics() {
    final logs = accessLogs;
    
    totalEntries.value = logs.where((log) => log.accessType == 'entrada').length;
    totalExits.value = logs.where((log) => log.accessType == 'salida').length;
    totalQrAccesses.value = logs.where((log) => log.method == 'qr').length;
    totalRfidAccesses.value = logs.where((log) => log.method == 'rfid').length;
    
    // Calcular usuarios actualmente dentro
    calculateUsersInside();
  }

  /// Calcular usuarios actualmente dentro del gimnasio
  Future<void> calculateUsersInside() async {
    try {
      final users = await AccessLogService.getUsersCurrentlyInside();
      usersCurrentlyInside.value = users?.length ?? 0;
      
      if (kDebugMode) {
        print('👥 Usuarios actualmente dentro: ${usersCurrentlyInside.value}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error calculando usuarios dentro: $e');
      }
      usersCurrentlyInside.value = 0;
    }
  }

  /// Refrescar datos
  Future<void> refreshData() async {
    await loadAccessLogs();
  }

  /// Obtener estadísticas formateadas para mostrar
  Map<String, String> getFormattedStats() {
    return {
      'totalEntries': totalEntries.value.toString(),
      'totalExits': totalExits.value.toString(),
      'totalQr': totalQrAccesses.value.toString(),
      'totalRfid': totalRfidAccesses.value.toString(),
      'usersInside': usersCurrentlyInside.value.toString(),
      'totalLogs': accessLogs.length.toString(),
    };
  }
}
