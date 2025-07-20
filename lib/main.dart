import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gymads/app/data/config/supabase_client.dart';
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
  } catch (e) {
    print('Error al inicializar Supabase: $e');
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
