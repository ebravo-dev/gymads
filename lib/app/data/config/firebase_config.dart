abstract class FirebaseConfig {
  // Nombre del proyecto en Firebase
  static const String ID_PROJECT = 'gymads-1f6e6';

  // Listado de nombres de modelos (colecciones en Firebase)
  static const List<String> MODELS = [
    'users', // Usuarios
    'memberships', // Membresías
    'payments', // Pagos
    'promotions', // Promociones
    'checkins', // Registros de acceso
  ];
}
