import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/config/rfid_config.dart';
import '../../../data/services/rfid_reader_service.dart';
import '../../../data/services/tenant_context_service.dart';
import '../../../data/models/staff_profile_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../routes/app_pages.dart';

class ConfiguracionController extends GetxController {
  // Variables observables para la configuración
  final RxBool isLoading = false.obs;

  // Variables para información de cuenta (populated from TenantContextService)
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userRole = ''.obs;
  final RxString firstName = ''.obs;
  final RxString lastName = ''.obs;
  final RxString gymName = ''.obs;
  final RxString branchName = ''.obs;

  // Variables para configuración del lector RFID
  final RxBool rfidConnectionStatus = false.obs;
  final RxString connectionStatusMessage = 'Verificando conexión...'.obs;
  final RxString esp32IpAddress = ''.obs;

  // Variables para ESP32 con IP manual
  final RxBool esp32Connected = false.obs;
  final RxString esp32StatusMessage = 'ESP32 desconectado'.obs;

  // Variables para configuración de audio
  final RxBool soundEnabled = true.obs;
  final RxDouble soundVolume = 0.8.obs;

  // Variables para configuración de QR
  final RxBool qrEnabled = true.obs;
  final RxString qrCodeFormat = 'auto'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    _loadConfiguration();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // =================== USER INFO FROM SESSION ===================

  void _loadUserInfo() {
    final tenant = TenantContextService.to;
    final user = Supabase.instance.client.auth.currentUser;

    // Name
    final profile = tenant.staffProfile;
    firstName.value = profile?.firstName ?? '';
    lastName.value = profile?.lastName ?? '';
    userName.value =
        tenant.displayName ?? user?.email?.split('@').first ?? 'Usuario';
    userEmail.value = user?.email ?? '';
    userRole.value = _formatRole(profile?.role);
    gymName.value = '';
    branchName.value = '';

    // Try to load gym/branch names
    _loadGymInfo();
  }

  String _formatRole(String? role) {
    switch (role) {
      case 'owner_admin':
        return 'Dueño / Admin';
      case 'branch_staff':
        return 'Staff de Sucursal';
      default:
        return 'Admin';
    }
  }

  Future<void> _loadGymInfo() async {
    try {
      final tenant = TenantContextService.to;
      if (tenant.currentGymId != null) {
        final gymData = await Supabase.instance.client
            .from('gyms')
            .select('name')
            .eq('id', tenant.currentGymId!)
            .maybeSingle();
        if (gymData != null) {
          gymName.value = gymData['name'] as String? ?? '';
        }
      }
      if (tenant.currentBranchId != null) {
        final branchData = await Supabase.instance.client
            .from('branches')
            .select('name')
            .eq('id', tenant.currentBranchId!)
            .maybeSingle();
        if (branchData != null) {
          branchName.value = branchData['name'] as String? ?? '';
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Could not load gym/branch names: $e');
    }
  }

  // =================== UPDATE PROFILE ===================

  Future<void> updateFirstName(String value) async {
    await _updateProfileField('first_name', value);
    firstName.value = value;
    _refreshDisplayName();
  }

  Future<void> updateLastName(String value) async {
    await _updateProfileField('last_name', value);
    lastName.value = value;
    _refreshDisplayName();
  }

  Future<void> _updateProfileField(String field, String value) async {
    try {
      isLoading.value = true;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Build display_name
      String newFirst = field == 'first_name' ? value : firstName.value;
      String newLast = field == 'last_name' ? value : lastName.value;
      String displayName = '$newFirst $newLast'.trim();

      await Supabase.instance.client.from('staff_profiles').update({
        field: value,
        'display_name': displayName,
      }).eq('user_id', userId);

      // Refresh TenantContextService cache
      final profileData = await Supabase.instance.client
          .from('staff_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      await TenantContextService.to
          .setProfile(StaffProfileModel.fromJson(profileData));

      SnackbarHelper.success('Guardado', 'Información actualizada');
    } catch (e) {
      if (kDebugMode) print('❌ Error updating profile: $e');
      SnackbarHelper.error('Error', 'No se pudo actualizar: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _refreshDisplayName() {
    userName.value = '${firstName.value} ${lastName.value}'.trim();
  }

  // =================== MÉTODOS DE INICIALIZACIÓN ===================

  Future<void> _loadConfiguration() async {
    try {
      isLoading.value = true;

      // Cargar configuración desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Configuración de audio
      soundEnabled.value = prefs.getBool('sound_enabled') ?? true;
      soundVolume.value = prefs.getDouble('sound_volume') ?? 0.8;

      // Configuración de QR
      qrEnabled.value = prefs.getBool('qr_enabled') ?? true;
      qrCodeFormat.value = prefs.getString('qr_format') ?? 'auto';

      // Cargar IP manual si existe
      String? savedIP = prefs.getString('esp32_ip_manual');
      if (savedIP != null && savedIP.isNotEmpty) {
        await connectToESP32WithIP(savedIP, showNotification: false);
      }

      await RfidConfig.loadConfig();
      await _checkRfidConnection();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al cargar configuración: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // =================== MÉTODOS DE CONEXIÓN ESP32 ===================

  /// Conectar manualmente con IP específica
  Future<void> connectToESP32WithIP(String ipAddress,
      {bool showNotification = true}) async {
    try {
      isLoading.value = true;
      esp32StatusMessage.value = 'Conectando a $ipAddress...';

      final RegExp ipRegex = RegExp(
          r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
      if (!ipRegex.hasMatch(ipAddress)) {
        if (showNotification) {
          SnackbarHelper.error('Formato inválido',
              'La dirección IP no tiene un formato válido (ej: 192.168.1.100)');
        }
        return;
      }

      bool connected = await RfidConfig.setManualIP(ipAddress);

      if (connected) {
        esp32Connected.value = true;
        esp32IpAddress.value = ipAddress;
        esp32StatusMessage.value = 'ESP32 conectado: $ipAddress';

        if (showNotification) {
          SnackbarHelper.success(
              'Conectado', 'ESP32 conectado exitosamente a $ipAddress');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('esp32_ip_manual', ipAddress);
      } else {
        esp32Connected.value = false;
        esp32StatusMessage.value = 'No se pudo conectar a $ipAddress';

        if (showNotification) {
          SnackbarHelper.error('Error de conexión',
              'No se pudo conectar al ESP32 en $ipAddress.');
        }
      }
    } catch (e) {
      esp32Connected.value = false;
      esp32StatusMessage.value = 'Error: $e';

      if (showNotification) {
        SnackbarHelper.error('Error', 'Error al conectar: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtener estado del ESP32
  Future<void> getESP32Status() async {
    try {
      bool available = await RfidConfig.isESP32Available();

      if (available) {
        esp32Connected.value = true;
        esp32IpAddress.value =
            RfidConfig.getCurrentIP() ?? RfidConfig.DEFAULT_ESP32_IP;
        esp32StatusMessage.value = 'ESP32 conectado: ${esp32IpAddress.value}';
      } else {
        esp32Connected.value = false;
        esp32StatusMessage.value = 'ESP32 sin conexión WiFi';
      }
    } catch (e) {
      esp32StatusMessage.value = 'Error al obtener estado: $e';
    }
  }

  // =================== MÉTODOS DE CONFIGURACIÓN RFID ===================

  Future<void> _checkRfidConnection() async {
    try {
      bool isConfigured = RfidConfig.isConfigured;
      rfidConnectionStatus.value = isConfigured;

      if (isConfigured) {
        connectionStatusMessage.value = 'RFID configurado';
        if (RfidConfig.baseUrl != null) {
          String url = RfidConfig.baseUrl!;
          final RegExp ipRegex = RegExp(r'(\d+\.\d+\.\d+\.\d+)');
          final match = ipRegex.firstMatch(url);
          if (match != null) {
            esp32IpAddress.value = match.group(1)!;
          }
        }
      } else {
        connectionStatusMessage.value = 'RFID no configurado';
      }
    } catch (e) {
      rfidConnectionStatus.value = false;
      connectionStatusMessage.value = 'Error al verificar RFID: $e';
    }
  }

  /// Probar conexión RFID
  Future<void> testRfidConnection() async {
    try {
      isLoading.value = true;
      connectionStatusMessage.value = 'Probando conexión...';

      String? cardUid = await RfidReaderService.checkForCard();

      if (cardUid != null) {
        rfidConnectionStatus.value = true;
        connectionStatusMessage.value = 'RFID conectado - Tarjeta detectada';
        SnackbarHelper.success('Conexión exitosa',
            'El lector RFID está funcionando correctamente');
      } else if (RfidConfig.isConfigured) {
        rfidConnectionStatus.value = true;
        connectionStatusMessage.value = 'RFID conectado - Sin tarjeta';
        SnackbarHelper.info('Conexión OK',
            'El lector RFID está conectado pero no hay tarjeta presente');
      } else {
        rfidConnectionStatus.value = false;
        connectionStatusMessage.value = 'RFID no configurado';
        SnackbarHelper.info(
            'Sin configurar', 'El lector RFID no está configurado');
      }
    } catch (e) {
      rfidConnectionStatus.value = false;
      connectionStatusMessage.value = 'Error: $e';
      SnackbarHelper.error('Error', 'Error al probar conexión: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // =================== MÉTODOS DE CONFIGURACIÓN ===================

  /// Guardar configuración de audio
  Future<void> saveAudioConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', soundEnabled.value);
      await prefs.setDouble('sound_volume', soundVolume.value);
      SnackbarHelper.success('Guardado', 'Configuración de audio guardada');
    } catch (e) {
      SnackbarHelper.error(
          'Error', 'Error al guardar configuración de audio: $e');
    }
  }

  /// Guardar configuración de QR
  Future<void> saveQRConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('qr_enabled', qrEnabled.value);
      await prefs.setString('qr_format', qrCodeFormat.value);
      SnackbarHelper.success('Guardado', 'Configuración de QR guardada');
    } catch (e) {
      SnackbarHelper.error('Error', 'Error al guardar configuración de QR: $e');
    }
  }

  // =================== MÉTODOS PARA NAVEGACIÓN DE CONFIGURACIÓN ===================

  /// Abrir configuración de cuenta — navega a CuentaView
  void openAccountSettings() {
    Get.toNamed(Routes.CUENTA);
  }

  /// Abrir configuración de aplicación
  void openAppSettings() {
    Get.dialog(
      AlertDialog(
        title: const Text('Configuración de Aplicación'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Esta funcionalidad será implementada próximamente.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // =================== LOGOUT ===================

  /// Cerrar sesión con confirmación
  void logout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          '¿Estás seguro que deseas cerrar la sesión?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // close dialog
              await _performLogout();
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      isLoading.value = true;

      // Sign out from Supabase
      await Supabase.instance.client.auth.signOut();

      // Clear tenant context
      await TenantContextService.to.clearProfile();

      // Navigate to login
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      if (kDebugMode) print('❌ Error during logout: $e');
      SnackbarHelper.error('Error', 'Error al cerrar sesión: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
