import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    // Configurar el cliente con el usuario autorizado
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'ederjgb94@gmail.com',
      password: 'asdqwe123',
    );
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
