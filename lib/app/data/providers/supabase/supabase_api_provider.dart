import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gymads/app/data/services/supabase_service.dart';
import 'package:gymads/app/data/providers/api_provider.dart';

/// Proveedor para interactuar con Supabase API
class SupabaseApiProvider extends ApiProvider {
  final String table;
  
  SupabaseApiProvider({required this.table}) : super(model: table);

  @override
  String get urlBase => dotenv.env['SUPABASE_URL'] ?? '';

  @override
  Future<Map<String, dynamic>> getAll({Map<String, String>? headers}) async {
    try {
      if (kDebugMode) {
        print('Obteniendo todos los registros de la tabla: $table');
      }
      
      final response = await SupabaseService.client
          .from(table)
          .select();

      if (kDebugMode) {
        print('Respuesta de Supabase (getAll): $response');
      }

      return {
        'error': false,
        'message': 'Datos obtenidos correctamente',
        'data': response
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error en getAll: $e');
        print('Response body raw: ${e.toString()}');
      }
      return {
        'error': true,
        'message': e.toString(),
        'data': null
      };
    }
  }

  @override
  Future<Map<String, dynamic>> get(String id, {Map<String, String>? headers}) async {
    try {
      final response = await SupabaseService.client
          .from(table)
          .select()
          .eq('id', id)
          .single();

      if (kDebugMode) {
        print('Respuesta de Supabase (get): $response');
      }

      return {
        'error': false,
        'message': 'Datos obtenidos correctamente',
        'data': response
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error en get: $e');
      }
      return {
        'error': true,
        'message': e.toString(),
        'data': null
      };
    }
  }

  @override
  Future<Map<String, dynamic>> add(Map<String, dynamic> data, {Map<String, String>? headers}) async {
    try {
      if (kDebugMode) {
        print('Insertando datos en tabla $table: $data');
      }
      
      final response = await SupabaseService.client
          .from(table)
          .insert(data)
          .select();

      if (kDebugMode) {
        print('Respuesta de Supabase (add): $response');
      }

      if (response.isEmpty) {
        return {
          'error': true,
          'message': 'Error al insertar datos o respuesta vacía',
          'data': null
        };
      }

      return {
        'error': false,
        'message': 'Datos añadidos correctamente',
        'data': response[0]
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error en add: $e');
      }
      return {
        'error': true,
        'message': e.toString(),
        'data': null
      };
    }
  }

  @override
  Future<Map<String, dynamic>> addDocument(String id, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    // En Supabase no se puede especificar el ID, así que agregamos el ID al objeto data
    data['id'] = id;
    return add(data, headers: headers);
  }

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    try {
      final response = await SupabaseService.client
          .from(table)
          .update(data)
          .eq('id', id)
          .select();

      if (kDebugMode) {
        print('Respuesta de Supabase (update): $response');
      }

      if (response.isEmpty) {
        return {
          'error': true,
          'message': 'Error al actualizar datos o respuesta vacía',
          'data': null
        };
      }

      return {
        'error': false,
        'message': 'Datos actualizados correctamente',
        'data': response[0]
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error en update: $e');
      }
      return {
        'error': true,
        'message': e.toString(),
        'data': null
      };
    }
  }

  @override
  Future<Map<String, dynamic>> delete(String id, {Map<String, String>? headers}) async {
    try {
      final response = await SupabaseService.client
          .from(table)
          .delete()
          .eq('id', id)
          .select();

      if (kDebugMode) {
        print('Respuesta de Supabase (delete): $response');
      }

      return {
        'error': false,
        'message': 'Datos eliminados correctamente',
        'data': response
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error en delete: $e');
      }
      return {
        'error': true,
        'message': e.toString(),
        'data': null
      };
    }
  }
}
