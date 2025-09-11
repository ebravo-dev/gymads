import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthUtils {
  static final _supabase = Supabase.instance.client;

  /// Obtiene el email del usuario autenticado actual
  static String? getCurrentUserEmail() {
    final user = _supabase.auth.currentUser;
    return user?.email;
  }

  /// Obtiene el ID del usuario autenticado actual
  static String? getCurrentUserId() {
    final user = _supabase.auth.currentUser;
    return user?.id;
  }

  /// Obtiene el nombre del usuario autenticado actual desde los metadatos
  static String? getCurrentUserName() {
    final user = _supabase.auth.currentUser;
    if (user?.userMetadata != null) {
      return user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'];
    }
    return user?.email?.split('@').first; // Fallback al email sin dominio
  }

  /// Verifica si hay un usuario autenticado
  static bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Obtiene la información completa del usuario actual
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Obtiene un identificador del staff actual (email o nombre)
  static String getStaffIdentifier() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('⚠️ [AuthUtils] No hay usuario autenticado');
      return 'unknown';
    }
    
    if (kDebugMode) {
      print('👤 [AuthUtils] Usuario autenticado encontrado:');
      print('   🆔 ID: ${user.id}');
      print('   📧 Email: ${user.email}');
      print('   📋 Metadata: ${user.userMetadata}');
    }
    
    // Priorizar nombre completo, luego email
    final name = user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
    if (name != null && name.toString().isNotEmpty) {
      if (kDebugMode) {
        print('   ✅ [AuthUtils] Usando nombre: $name');
      }
      return name.toString();
    }
    
    if (kDebugMode) {
      print('   ✅ [AuthUtils] Usando email: ${user.email ?? 'unknown'}');
    }
    
    return user.email ?? 'unknown';
  }
}
