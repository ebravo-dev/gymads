import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL'] ?? '',
        anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      );

      // Configurar el cliente con el usuario autorizado
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: dotenv.env['SUPABASE_USER'] ?? '',
        password: dotenv.env['SUPABASE_PASSWORD'] ?? '',
      );

      if (response.user == null) {
        throw Exception('No se pudo autenticar el usuario');
      }

      if (kDebugMode) {
        print('Usuario autenticado: ${response.user?.email}');
        // Verificar rol y permisos
        print('Session: ${response.session?.toJson()}');
      }

      // Verificar conexión a la base de datos
      await testDatabaseConnection();
    } catch (e) {
      if (kDebugMode) {
        print('Error al inicializar Supabase: $e');
      }
      rethrow;
    }
  }

  /// Método para verificar la conexión a la base de datos Supabase
  static Future<void> testDatabaseConnection() async {
    try {
      // 1. Verificar sesión actual
      final session = await client.auth.currentSession;
      if (kDebugMode) {
        print('Token JWT: ${session?.accessToken}');
        print('Usuario actual: ${session?.user.email}');
      }

      // 2. Verificar permisos
      final perms = await client
          .rpc('check_permissions')
          .single();
      
      if (kDebugMode) {
        print('Permisos actuales: $perms');
      }

      // 3. Intentar una consulta simple
      final response = await client
          .from('users')
          .select('count')
          .single();

      if (kDebugMode) {
        print('Consulta exitosa: $response');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error al probar la conexión: $e');
        if (e is PostgrestException) {
          print('Código de error: ${e.code}');
          print('Detalles: ${e.details}');
          print('Hint: ${e.hint}');
        }
        // Imprimir la traza completa para debugging
        print(e.toString());
      }
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<String?> uploadUserPhoto(String filePath, String userId) async {
    try {
      const bucketName = 'clientes';
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}${filePath.substring(filePath.lastIndexOf('.'))}';

      await client.storage.from(bucketName).upload(fileName, File(filePath));

      return client.storage.from(bucketName).getPublicUrl(fileName);
    } catch (e) {
      if (kDebugMode) {
        print('Error al subir la foto: $e');
      }
      return null;
    }
  }

  static Future<bool> deleteUserPhoto(String photoUrl) async {
    try {
      const bucketName = 'clientes';
      final fileName = photoUrl.split('/').last;
      await client.storage.from(bucketName).remove([fileName]);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error al eliminar la foto: $e');
      }
      return false;
    }
  }
}
