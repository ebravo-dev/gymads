import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get storageUrl => dotenv.env['SUPABASE_STORAGE_URL'] ?? '';
  static String get accessKeyId => dotenv.env['SUPABASE_ACCESS_KEY_ID'] ?? '';
  static String get bucketName =>
      dotenv.env['SUPABASE_BUCKET_NAME'] ?? 'clientes';
  static String get baseStorageUrl => '$storageUrl/object/public/$bucketName';
}
