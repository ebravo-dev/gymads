import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/staff_profile_model.dart';
import '../../../data/providers/staff_profile_provider.dart';
import '../../../data/services/tenant_context_service.dart';
import '../../../routes/app_pages.dart';

/// Controller for authentication (login/logout)
///
/// Handles Supabase Auth login and fetches staff_profile
/// to establish tenant context before allowing access.
class AuthController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StaffProfileProvider _staffProfileProvider = StaffProfileProvider();

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // State
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool obscurePassword = true.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = null;
  }

  /// Validate form fields
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es requerido';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Login with email and password
  ///
  /// Returns true if login was successful
  Future<bool> login() async {
    clearError();

    // Validate fields
    final emailError = validateEmail(emailController.text);
    final passwordError = validatePassword(passwordController.text);

    if (emailError != null) {
      errorMessage.value = emailError;
      return false;
    }
    if (passwordError != null) {
      errorMessage.value = passwordError;
      return false;
    }

    isLoading.value = true;

    try {
      // 1. Authenticate with Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.user == null) {
        throw Exception('Error de autenticación');
      }

      print('✅ Auth successful for: ${response.user!.email}');

      // 2. Fetch staff_profile for this user
      final staffProfile = await _staffProfileProvider.getByUserId(
        response.user!.id,
      );

      if (staffProfile == null || !staffProfile.isActive) {
        // No staff profile means this user is not authorized
        await _supabase.auth.signOut();
        throw Exception(
          'Usuario no asignado a ninguna sucursal.\nContacta al administrador.',
        );
      }

      print(
          '✅ Staff profile loaded: ${staffProfile.displayName ?? staffProfile.userId}');
      print('   Gym ID: ${staffProfile.gymId}');
      print('   Branch ID: ${staffProfile.branchId}');
      print('   Role: ${staffProfile.role}');

      // 3. Set tenant context
      await TenantContextService.to.setProfile(staffProfile);

      // 4. Clear form
      emailController.clear();
      passwordController.clear();

      // 5. Navigate to home
      Get.offAllNamed(Routes.HOME);

      return true;
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      if (e.message.contains('Invalid login credentials')) {
        errorMessage.value = 'Credenciales inválidas';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage.value = 'Email no confirmado';
      } else {
        errorMessage.value = 'Error de autenticación: ${e.message}';
      }
      return false;
    } catch (e) {
      print('❌ Login error: $e');
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('⚠️ Error signing out: $e');
    }
    await TenantContextService.to.clearProfile();
    Get.offAllNamed(Routes.LOGIN);
  }

  /// Check if there's an existing session
  ///
  /// Called on app start to determine if user is already logged in
  Future<bool> checkSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        print('⚠️ No existing session');
        return false;
      }

      print('📍 Found existing session for: ${session.user.email}');

      // Verify staff_profile is still valid
      final staffProfile = await _staffProfileProvider.getByUserId(
        session.user.id,
      );

      if (staffProfile == null || !staffProfile.isActive) {
        print('⚠️ Staff profile no longer valid');
        await logout();
        return false;
      }

      // Set tenant context
      await TenantContextService.to.setProfile(staffProfile);

      print(
          '✅ Session restored for ${staffProfile.displayName ?? session.user.email}');
      return true;
    } catch (e) {
      print('❌ Error checking session: $e');
      return false;
    }
  }

  /// Get current user info
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current staff profile
  StaffProfileModel? get staffProfile => TenantContextService.to.staffProfile;

  /// Check if user is authenticated
  bool get isAuthenticated => TenantContextService.to.isAuthenticated;
}
