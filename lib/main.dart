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
  // await Supabase.initialize(
  //   url: dotenv.env['SUPABASE_URL'] ?? '',
  //   anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  // );

  await Supabase.initialize(
    url: 'https://hizdsbhzxgdfjchenjem.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpemRzYmh6eGdkZmpjaGVuamVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5Njc1MTMsImV4cCI6MjA2ODU0MzUxM30.2-k9qLi7ufwIR33RC-PnF2p8jh5Q1uAtXiUMO1UT-VA',
    // debug: true,
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
