import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/providers/staff_profile_provider.dart';
import '../../../data/services/tenant_context_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/branding_service.dart';
import '../../../routes/app_pages.dart';

/// Controller for registration (creating a new gym account)
///
/// Flow:
/// 1. User fills: nombre(s), apellido paterno, apellido materno, email, password
/// 2. Fills gym name and main branch
/// 3. Optionally adds branch names
/// 4. On submit:
///    a. Creates auth.users via Supabase Auth signUp
///    b. Calls register_gym_owner RPC (creates gym → branch → staff_profile)
///    c. Navigates to email confirmation screen
class RegisterController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StaffProfileProvider _staffProfileProvider = StaffProfileProvider();

  // Form controllers — Name split into Nombre(s) + Apellidos
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final gymNameController = TextEditingController();
  final mainBranchNameController =
      TextEditingController(text: 'Sucursal Principal');

  // Optional additional branches
  final RxList<TextEditingController> additionalBranches =
      <TextEditingController>[].obs;

  // State
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxBool wantsMultipleBranches = false.obs;
  final RxInt currentStep = 0.obs;
  final RxString selectedBrandColor = '#10D5E8'.obs;
  final RxString selectedFont = 'Default'.obs;
  final RxString gymNameText = ''.obs; // reactive mirror for preview
  final RxBool hasRfidReader = false.obs;

  // Form key
  final formKey = GlobalKey<FormState>();

  /// Composed full name for display
  String get fullName {
    final parts = <String>[];
    if (firstNameController.text.trim().isNotEmpty) {
      parts.add(firstNameController.text.trim());
    }
    if (lastNameController.text.trim().isNotEmpty) {
      parts.add(lastNameController.text.trim());
    }
    return parts.join(' ');
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    gymNameController.dispose();
    mainBranchNameController.dispose();
    for (final c in additionalBranches) {
      c.dispose();
    }
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    gymNameController.addListener(() {
      gymNameText.value = gymNameController.text;
    });
  }

  // ============================================
  // STEP NAVIGATION
  // ============================================

  void nextStep() {
    if (currentStep.value < 2) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  // ============================================
  // BRANCHES
  // ============================================

  void toggleMultipleBranches(bool value) {
    wantsMultipleBranches.value = value;
    if (!value) {
      for (final c in additionalBranches) {
        c.dispose();
      }
      additionalBranches.clear();
    }
  }

  void addBranch() {
    additionalBranches.add(TextEditingController());
  }

  void removeBranch(int index) {
    if (index < additionalBranches.length) {
      additionalBranches[index].dispose();
      additionalBranches.removeAt(index);
    }
  }

  // ============================================
  // VALIDATION
  // ============================================

  void clearError() {
    errorMessage.value = null;
  }

  String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Los apellidos son requeridos';
    }
    return null;
  }

  // Materno is optional, no validation needed

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
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  String? validateGymName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre del gimnasio es requerido';
    }
    return null;
  }

  String? validateBranchName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de la sucursal es requerido';
    }
    return null;
  }

  // ============================================
  // REGISTRATION
  // ============================================

  Future<void> register() async {
    clearError();
    isLoading.value = true;

    try {
      // 1. Create auth user
      print('📝 Creating auth user...');
      final authResponse = await _supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        data: {
          'display_name': fullName,
          'first_name': firstNameController.text.trim(),
        },
      );

      if (authResponse.user == null) {
        throw Exception('Error al crear la cuenta');
      }

      final userId = authResponse.user!.id;
      print('✅ Auth user created: $userId');

      // 2. Call the register_gym_owner RPC function
      print('🏋️ Registering gym via RPC...');

      // Collect additional branch names
      final List<String> extraBranches = [];
      if (wantsMultipleBranches.value) {
        for (final bc in additionalBranches) {
          if (bc.text.trim().isNotEmpty) {
            extraBranches.add(bc.text.trim());
          }
        }
      }

      final result = await _supabase.rpc('register_gym_owner', params: {
        'p_user_id': userId,
        'p_first_name': firstNameController.text.trim(),
        'p_last_name': lastNameController.text.trim(),
        'p_gym_name': gymNameController.text.trim(),
        'p_main_branch_name': mainBranchNameController.text.trim(),
        'p_additional_branches': extraBranches,
      });

      print('✅ Gym registered: $result');

      // 3. Auto-login: fetch staff profile and set tenant context
      print('🔑 Auto-login: fetching staff profile...');
      final staffProfile = await _staffProfileProvider.getByUserId(userId);

      if (staffProfile != null && staffProfile.isActive) {
        await TenantContextService.to.setProfile(staffProfile);

        // Always set branding from registration form values
        BrandingService.to.setGymTitle(gymNameController.text.trim());
        BrandingService.to.setBrandColor(selectedBrandColor.value);
        BrandingService.to.setBrandFont(selectedFont.value);

        // Always save brand color and font to gym in DB
        try {
          await _supabase.from('gyms').update({
            'brand_color': selectedBrandColor.value,
            'brand_font': selectedFont.value,
          }).eq('id', staffProfile.gymId);
        } catch (_) {}

        // Save RFID preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rfid_enabled', hasRfidReader.value);

        print('✅ Auto-login complete! Navigating to Home...');
        Get.offAllNamed(Routes.HOME);
      } else {
        // Fallback: staff profile not ready yet, go to login
        print('⚠️ Staff profile not ready, redirecting to login');
        Get.offAllNamed(Routes.LOGIN);
      }
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      if (e.message.contains('already registered')) {
        errorMessage.value = 'Este correo ya está registrado';
      } else {
        errorMessage.value = 'Error: ${e.message}';
      }
    } catch (e) {
      print('❌ Registration error: $e');
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }
}
