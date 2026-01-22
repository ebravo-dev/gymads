import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:gymads/app/bindings/initial_binding.dart';
import 'package:gymads/app/data/config/rfid_config.dart';
import 'package:gymads/app/data/services/background_rfid_service.dart';
import 'package:gymads/app/data/services/image_cache_service.dart';
import 'package:gymads/app/data/services/rfid_reader_service.dart';
import 'package:gymads/app/data/services/supabase_service.dart';
import 'package:gymads/app/modules/clientes/services/qr_cache_service.dart';
import 'package:gymads/app/routes/app_pages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// GlobalKey para acceder al ScaffoldMessenger desde cualquier parte de la app
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  // Carga las variables de entorno
  await dotenv.load(fileName: ".env");

  // Asegura la inicialización de los bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase (cliente principal) - SOLO UNA VEZ
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    debug: true,
  );
  print('Supabase inicializado correctamente');

  // Autentica al usuario administrador
  await SupabaseService.authenticate();
  
  // Verifica la conexión a la base de datos
  await SupabaseService.testDatabaseConnection();
  print('Conexión a la base de datos verificada');

  // Inicializa y registra el servicio de caché de imágenes
  final imageCacheService = ImageCacheService.instance;
  await imageCacheService.initialize();
  Get.put(imageCacheService, permanent: true);
  print('Servicio de caché de imágenes inicializado');

  // Inicializa y registra el servicio de caché de QR
  final qrCacheService = QrCacheService();
  qrCacheService.initialize();
  Get.put(qrCacheService, permanent: true);
  print('Servicio de caché de QR codes inicializado');

  // Inicializa la configuración del lector RFID
  await RfidConfig.loadConfig();
  print('Configuración RFID cargada');

  // Registra el servicio de RFID de forma perezosa
  Get.lazyPut<BackgroundRfidService>(() => BackgroundRfidService());
  print('BackgroundRfidService registrado');

  // Inicia la aplicación
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Inicia el servicio RFID después de que el primer frame se renderice
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('⚙️ Post-frame: Iniciando servicio RFID...');
      try {
        final bool connected = await RfidReaderService.startReading();
        if (connected) {
          print('✅ RFID conectado. Iniciando escaneo en segundo plano...');
          Get.find<BackgroundRfidService>().startScanning();
          print('✅ Servicio de escaneo RFID iniciado correctamente.');
        } else {
          print('⚠️ No se pudo conectar al lector RFID.');
        }
      } catch (e, stack) {
        print('❌ ERROR al iniciar servicio RFID: $e');
        print('Stack: $stack');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "Gymads",
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      initialBinding: InitialBinding(),
    );
  }
}
