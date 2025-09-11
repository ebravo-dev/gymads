import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/access_log_model.dart';

class AccessLogService {
  static final _supabase = Supabase.instance.client;

  /// Registra un acceso (entrada o salida) en la base de datos
  static Future<bool> registerAccess({
    required String userId,
    required String userName,
    required String userNumber,
    required String accessType, // 'entrada' o 'salida'
    required String method, // 'qr' o 'rfid'
    required String staffUser,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 [AccessLogService] Iniciando registro de acceso...');
        print('   🆔 User ID: $userId');
        print('   👤 User Name: $userName');
        print('   🔢 User Number: $userNumber');
        print('   🚪 Access Type: $accessType');
        print('   📱 Method: $method');
        print('   👨‍💼 Staff User: $staffUser');
        print('   🕐 Time: ${DateTime.now().toIso8601String()}');
      }

      final accessData = {
        'user_id': userId,
        'user_name': userName,
        'user_number': userNumber,
        'access_type': accessType,
        'method': method,
        'staff_user': staffUser,
        'access_time': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        print('   📦 Data to insert: $accessData');
      }

      final response = await _supabase
          .from('access_logs')
          .insert(accessData)
          .select();

      if (kDebugMode) {
        print('✅ [AccessLogService] Respuesta de Supabase: ${response.toString()}');
        print('✅ [AccessLogService] Acceso registrado exitosamente');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AccessLogService] Error al registrar acceso: $e');
        print('❌ [AccessLogService] Tipo de error: ${e.runtimeType}');
        if (e is PostgrestException) {
          print('❌ [AccessLogService] PostgrestException - Message: ${e.message}');
          print('❌ [AccessLogService] PostgrestException - Details: ${e.details}');
          print('❌ [AccessLogService] PostgrestException - Hint: ${e.hint}');
          print('❌ [AccessLogService] PostgrestException - Code: ${e.code}');
        }
      }
      return false;
    }
  }

  /// Obtiene el último acceso de un usuario específico
  static Future<AccessLogModel?> getLastUserAccess(String userId) async {
    try {
      final response = await _supabase
          .from('access_logs')
          .select()
          .eq('user_id', userId)
          .order('access_time', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return AccessLogModel.fromJson(response.first);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener último acceso: $e');
      }
      return null;
    }
  }

  /// Determina si el próximo acceso debe ser entrada o salida
  static Future<String> determineAccessType(String userId) async {
    try {
      final lastAccess = await getLastUserAccess(userId);
      
      if (lastAccess == null) {
        // Si no hay registros previos, el primer acceso es entrada
        return 'entrada';
      }

      // Si el último acceso fue entrada, el siguiente debe ser salida
      // Si el último acceso fue salida, el siguiente debe ser entrada
      return lastAccess.accessType == 'entrada' ? 'salida' : 'entrada';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al determinar tipo de acceso: $e');
      }
      // En caso de error, por defecto asumimos entrada
      return 'entrada';
    }
  }

  /// Obtiene los accesos de hoy
  static Future<List<AccessLogModel>> getTodayAccesses() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('access_logs')
          .select()
          .gte('access_time', startOfDay.toIso8601String())
          .lt('access_time', endOfDay.toIso8601String())
          .order('access_time', ascending: false);

      return response
          .map<AccessLogModel>((json) => AccessLogModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener accesos de hoy: $e');
      }
      return [];
    }
  }

  /// Obtiene los accesos de un usuario en un rango de fechas
  static Future<List<AccessLogModel>> getUserAccessHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('access_logs')
          .select()
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('access_time', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('access_time', endDate.toIso8601String());
      }

      final response = await query
          .order('access_time', ascending: false)
          .limit(limit);

      return response
          .map<AccessLogModel>((json) => AccessLogModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener historial de accesos: $e');
      }
      return [];
    }
  }

  /// Obtiene estadísticas de accesos por día
  static Future<Map<String, int>> getAccessStatsByDay({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final today = DateTime.now();
      final start = startDate ?? today.subtract(const Duration(days: 7));
      final end = endDate ?? today;

      final response = await _supabase
          .from('access_logs')
          .select('access_time, access_type')
          .gte('access_time', start.toIso8601String())
          .lte('access_time', end.toIso8601String());

      final stats = <String, int>{};
      
      for (final record in response) {
        final accessTime = DateTime.parse(record['access_time']);
        final dayKey = '${accessTime.year}-${accessTime.month.toString().padLeft(2, '0')}-${accessTime.day.toString().padLeft(2, '0')}';
        
        stats[dayKey] = (stats[dayKey] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al obtener estadísticas de accesos: $e');
      }
      return {};
    }
  }

  /// Verifica si un usuario está actualmente dentro del gimnasio
  static Future<bool> isUserInside(String userId) async {
    try {
      final lastAccess = await getLastUserAccess(userId);
      
      if (lastAccess == null) {
        return false; // Si no hay registros, no está adentro
      }

      // El usuario está adentro si su último acceso fue una entrada
      return lastAccess.accessType == 'entrada';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al verificar si el usuario está adentro: $e');
      }
      return false;
    }
  }
}
