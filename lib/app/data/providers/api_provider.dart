import 'dart:async';

/// Clase abstracta que define la interfaz para todos los proveedores de API
abstract class ApiProvider {
  final String model;
  String get urlBase;

  ApiProvider({required this.model});

  /// Obtiene todos los documentos de una colección
  Future<Map<String, dynamic>> getAll({Map<String, String>? headers});

  /// Obtiene un documento específico por su ID
  Future<Map<String, dynamic>> get(String id, {Map<String, String>? headers});

  /// Añade un nuevo documento a la colección con ID generado automáticamente
  Future<Map<String, dynamic>> add(
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  });

  /// Añade un documento con un ID específico
  Future<Map<String, dynamic>> addDocument(
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  });

  /// Actualiza un documento existente por su ID
  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  });

  /// Elimina un documento por su ID
  Future<Map<String, dynamic>> delete(
    String id, {
    Map<String, String>? headers,
  });
}
