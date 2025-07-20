import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/routes/app_pages.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // ✅ Ya no hacemos login automático aquí
  // El login se manejará en la pantalla de autenticación
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
