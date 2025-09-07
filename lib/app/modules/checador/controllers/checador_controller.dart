import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/image_cache_service.dart';
import '../../../data/services/rfid_reader_service.dart';
import '../../../data/config/rfid_config.dart';
import 'package:flutter/foundation.dart';

class ChecadorController extends GetxController {
  final UserRepository userRepository;

  ChecadorController({required this.userRepository});

  final isShowingDialog = false.obs;
  final userName = ''.obs;
  final daysLeft = 0.obs;
  final userPhotoUrl = ''.obs;
  final membershipType = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Estados de membresía para control de LEDs (igual que en RFID)
  static const String membershipActive = "ACTIVE";
  static const String membershipExpiring = "EXPIRING";
  static const String membershipExpired = "EXPIRED";
  static const String membershipNotFound = "NOT_FOUND";
  static const int expiringWarningDays = 5; // Advertir cuando quedan 5 días o menos

  @override
  void onInit() {
    super.onInit();
    _initializeImageCache();
  }
  
  // Inicializar servicio de caché de imágenes
  Future<void> _initializeImageCache() async {
    try {
      await ImageCacheService.instance.initialize();
      if (kDebugMode) {
        print('✅ Servicio de caché de imágenes inicializado en checador');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inicializando caché de imágenes: $e');
      }
    }
  }

  Future<void> onDetect(BarcodeCapture capture) async {
    if (isShowingDialog.value || isLoading.value) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      String? userNumber = barcode.rawValue?.trim();
      if (userNumber == null || userNumber.isEmpty) continue;

      if (kDebugMode) {
        print('🔍 Escaneando userNumber: |$userNumber|');
      }

      isLoading.value = true;
      errorMessage.value = '';

      try {
        if (kDebugMode) {
          print('🔍 Buscando usuario en la base de datos...');
        }

        final UserModel? user = await userRepository.getUserByNumber(
          userNumber,
        );

        if (user == null) {
          if (kDebugMode) {
            print('❌ Usuario no encontrado para el número: $userNumber');
          }
          errorMessage.value = 'Usuario no registrado con número: $userNumber';
          // Reproducir sonido de acceso denegado cuando NO está registrado
          AudioService.playDeniedSound();
          
          // Enviar estado al ESP32 para LEDs rojos EN SEGUNDO PLANO
          _sendMembershipStatusToESP32(userNumber, membershipNotFound);
          
          // Mantener el mensaje de error visible por 3 segundos
          await Future.delayed(const Duration(seconds: 3));
          errorMessage.value = '';
          continue;
        }

        if (kDebugMode) {
          print('✅ Usuario encontrado: ${user.name}');
          print('ℹ️ Estado activo: ${user.isActive}');
          print('ℹ️ Días restantes: ${user.daysRemaining}');
        }

        // Verificar si la membresía está activa
        if (!user.isActive) {
          if (kDebugMode) {
            print('⚠️ Membresía inactiva para usuario: ${user.name}');
          }
          errorMessage.value = 'Membresía inactiva para ${user.name}';
          // Reproducir sonido de acceso denegado (membresía inactiva)
          AudioService.playDeniedSound();
          
          // Enviar estado al ESP32 para LEDs rojos EN SEGUNDO PLANO
          _sendMembershipStatusToESP32(userNumber, membershipExpired);
          
          // Mantener el mensaje de error visible por 3 segundos
          await Future.delayed(const Duration(seconds: 3));
          errorMessage.value = '';
          continue;
        }

        // Verificar si la membresía no ha expirado
        if (user.daysRemaining <= 0) {
          if (kDebugMode) {
            print('⚠️ Membresía vencida para usuario: ${user.name}');
          }
          errorMessage.value = 'Membresía vencida para ${user.name}';
          // Reproducir sonido de acceso denegado (membresía vencida)
          AudioService.playDeniedSound();
          
          // Enviar estado al ESP32 para LEDs rojos EN SEGUNDO PLANO
          _sendMembershipStatusToESP32(userNumber, membershipExpired);
          
          // Mantener el mensaje de error visible por 3 segundos
          await Future.delayed(const Duration(seconds: 3));
          errorMessage.value = '';
          continue;
        }

        if (kDebugMode) {
          print('✅ Acceso autorizado para: ${user.name}');
        }

        // Precargar imagen del usuario ANTES de mostrar el diálogo
        if (user.id != null && user.photoUrl != null && user.photoUrl!.isNotEmpty) {
          try {
            await ImageCacheService.instance.getUserImage(
              user.id!, 
              user.photoUrl, 
              isThumbnail: false // Usar imagen de tamaño completo para el diálogo
            );
            if (kDebugMode) {
              print('✅ Imagen precargada para: ${user.name}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error precargando imagen: $e');
            }
          }
        }

        // Actualizar datos para mostrar
        userName.value = user.name;
        daysLeft.value = user.daysRemaining;
        userPhotoUrl.value = user.photoUrl ?? '';
        membershipType.value = user.membershipType;

        // Reproducir sonido de bienvenida
        AudioService.playWelcomeSound();

        // Mostrar el diálogo INMEDIATAMENTE
        isShowingDialog.value = true;

        // Registrar el acceso en segundo plano DESPUÉS de mostrar el diálogo
        if (user.id != null) {
          _registerAccessInBackground(user);
        }

        // Determinar estado de membresía para LEDs y enviar en segundo plano
        String membershipStatus;
        if (user.daysRemaining <= expiringWarningDays) {
          membershipStatus = membershipExpiring; // LED amarillo
        } else {
          membershipStatus = membershipActive; // LED verde
        }

        // Enviar estado al ESP32 para control de LEDs EN SEGUNDO PLANO
        _sendMembershipStatusToESP32(userNumber, membershipStatus);

        // Cerrar el diálogo después de 4 segundos
        await Future.delayed(const Duration(seconds: 4));
        isShowingDialog.value = false;
        
        // Limpiar mensaje de error al completar exitosamente
        errorMessage.value = '';
        
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error al procesar el acceso: $e');
          print('❌ Stack trace: ${StackTrace.current}');
        }
        errorMessage.value = 'Error de conexión. Intenta de nuevo.';
        
        // Mantener el mensaje de error visible por 3 segundos
        await Future.delayed(const Duration(seconds: 3));
        errorMessage.value = '';
      } finally {
        isLoading.value = false;
      }
    }
  }
  
  // Registrar acceso en segundo plano para no bloquear la UI
  void _registerAccessInBackground(UserModel user) {
    Future(() async {
      try {
        final updatedUser = user.addAccessRecord();
        if (user.id != null) {
          await userRepository.updateUser(user.id!, updatedUser);
          if (kDebugMode) {
            print('✅ Registro de acceso guardado en segundo plano para: ${user.name}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error al registrar acceso en segundo plano: $e');
        }
      }
    });
  }

  // Enviar estado de membresía al ESP32 para control de LEDs
  void _sendMembershipStatusToESP32(String userNumber, String status) {
    Future(() async {
      try {
        if (RfidConfig.isConfigured) {
          await RfidReaderService.sendMembershipStatus(userNumber, status);
          if (kDebugMode) {
            print('✅ Estado de membresía enviado al ESP32: $userNumber -> $status');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ ESP32 no configurado, no se pueden controlar LEDs');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error enviando estado al ESP32: $e');
        }
      }
    });
  }
}
