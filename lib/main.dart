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
    url: 'https://ndaczglktyfoequrdbkl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5kYWN6Z2xrdHlmb2VxdXJkYmtsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM0NTU2NTYsImV4cCI6MjA1OTAzMTY1Nn0.J45cOZAeF2ozU4yYcPg9yph3p3D1QCbwyBGc7Lf3sx4',
    // debug: true,
  );

  await Supabase.instance.client.auth.signInWithPassword(
    email: 'ederjgb94@gmail.com',
    password: 'asdqwe123',
  );
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
