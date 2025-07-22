import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gymads/app/data/config/rfid_config.dart';
import 'package:gymads/app/data/config/supabase_client.dart';
import 'package:gymads/app/data/services/rfid_reader_service.dart';
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
    
    // Verificar conexión a la base de datos
    await SupabaseService.testDatabaseConnection();
    print('Conexión a la base de datos verificada');
    
    // Intentar conectar con el lector RFID al inicio
    bool rfidConnected = await RfidReaderService.startReading();
    if (rfidConnected) {
      print('Lector RFID inicializado correctamente');
    } else {
      print('Advertencia: No se pudo conectar con el lector RFID');
      print('La aplicación funcionará en modo de simulación para lectura RFID');
      print('URL RFID configurada: ${RfidConfig.baseUrl}');
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
    ),
  );
}
