import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gymads/app/data/config/rfid_config.dart';
import 'package:gymads/app/data/services/supabase_service.dart';
import 'package:gymads/app/data/services/rfid_reader_service.dart';
import 'package:gymads/app/data/services/image_cache_service.dart';
import 'package:gymads/app/modules/clientes/services/qr_cache_service.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  try {
    // Inicializar Supabase usando nuestro servicio configurado
    await SupabaseService.initialize();
    print('Supabase inicializado correctamente');
    
    // Inicializar servicio de caché de imágenes
    await ImageCacheService.instance.initialize();
    print('Servicio de caché de imágenes inicializado');
    
    // Inicializar servicio de caché de QR codes
    QrCacheService().initialize();
    print('Servicio de caché de QR codes inicializado');
    
    // Verificar conexión a la base de datos
    await SupabaseService.testDatabaseConnection();
    print('Conexión a la base de datos verificada');
    
    // Cargar configuración de RFID primero
    print('⚙️ Intentando cargar configuración RFID...');
    await RfidConfig.loadConfig();
    print('🌐 URL RFID configurada: ${RfidConfig.baseUrl}');
    
    // Intentar conectar con el lector RFID al inicio
    print('🔄 Intentando conectar al ESP32...');
    bool rfidConnected = await RfidReaderService.startReading();
    if (rfidConnected) {
      print('✅ Lector RFID conectado correctamente');
      print('📡 IP del ESP32: ${RfidConfig.getCurrentIP() ?? RfidConfig.DEFAULT_ESP32_IP}');
    } else {
      print('⚠️  Advertencia: No se pudo conectar con el lector RFID');
      print('🔧 Verificar que el ESP32 esté encendido en IP: ${RfidConfig.DEFAULT_ESP32_IP}');
      print('🔧 Verificar que ambos dispositivos estén en la misma red WiFi');
      print('🔧 Verificar que el firewall no esté bloqueando la conexión');
      print('📱 La aplicación funcionará en modo de simulación para lectura RFID');
    }
  } catch (e) {
    print('Error en inicialización: $e');
  }
  
  runApp(
    GetMaterialApp(
      title: "GymAds - Gestión de Gimnasio",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
    ),
  );
}
