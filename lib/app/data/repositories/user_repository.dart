import 'package:flutter/foundation.dart';
import 'package:gymads/app/data/models/user_model.dart';
import 'package:gymads/app/data/providers/api_provider.dart';

/// Repositorio para la gestión de usuarios
/// Esta clase implementa la lógica de negocio relacionada con usuarios
/// y utiliza un ApiProvider para acceder a los datos
class UserRepository {
  final ApiProvider _apiProvider;

  UserRepository(this._apiProvider);

  /// Obtiene un usuario por su ID
  Future<UserModel?> getUserById(String id) async {
    try {
      final response = await _apiProvider.get(id);
      if (response['error'] || response['data'] == null) {
        return null;
      }

      return UserModel.fromJson(response['data']);
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener usuario: $e');
      }
      return null;
    }
  }

  /// Obtiene un usuario por su número de usuario (userNumber)
  Future<UserModel?> getUserByNumber(String userNumber) async {
    try {
      final response = await _apiProvider.getAll();

      if (response['error'] == true || response['data'] == null) {
        if (kDebugMode) {
          print('Error en la respuesta de Firebase o datos nulos');
          print('Response: $response');
        }
        return null;
      }

      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        if (kDebugMode) {
          print('Data no es un Map<String, dynamic>');
        }
        return null;
      }

      // Buscar el documento que coincida con el userNumber
      UserModel? matchedUser;
      data.forEach((docId, document) {
        if (document is Map<String, dynamic> &&
            document['fields'] is Map<String, dynamic>) {
          final fields = document['fields'] as Map<String, dynamic>;

          final docUserNumber = fields['userNumber']?['stringValue'];

          if (docUserNumber == userNumber) {
            final Map<String, dynamic> userData = {
              'id': docId,
              'accessHistory':
                  (fields['accessHistory']?['arrayValue']?['values'] ?? []).map(
                    (item) {
                      return item['stringValue'] ?? '';
                    },
                  ).toList(),
              'expirationDate': fields['expirationDate']?['stringValue'],
              'isActive': fields['isActive']?['booleanValue'] ?? true,
              'joinDate': fields['joinDate']?['stringValue'],
              'lastPaymentDate': fields['lastPaymentDate']?['stringValue'],
              'membershipType':
                  fields['membershipType']?['stringValue'] ?? 'normal',
              'name': fields['name']?['stringValue'] ?? '',
              'phone': fields['phone']?['stringValue'] ?? '',
              'photoUrl': fields['photoUrl']?['stringValue'],
              'qrCode': fields['qrCode']?['stringValue'],
              'userNumber': docUserNumber,
            };

            if (kDebugMode) {
              print('Usuario encontrado. Datos extraídos:');
              print(userData);
            }

            matchedUser = UserModel.fromJson(userData);
          }
        }
      });

      if (matchedUser == null && kDebugMode) {
        print('No se encontró ningún usuario con el número: $userNumber');
      }

      return matchedUser;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener usuario por número: $e');
      }
      return null;
    }
  }

  /// Obtiene todos los usuarios disponibles
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _apiProvider.getAll();
      if (response['error'] || response['data'] == null) {
        return [];
      }

      final Map<String, dynamic> data = response['data'];
      final List<UserModel> users = [];

      data.forEach((key, document) {
        if (document != null && document is Map<String, dynamic>) {
          if (document['fields'] != null &&
              document['fields'] is Map<String, dynamic>) {
            final fields = document['fields'] as Map<String, dynamic>;

            final Map<String, dynamic> userData = {
              'id': key,
              'accessHistory':
                  (fields['accessHistory']?['arrayValue']?['values'] ?? []).map(
                    (item) {
                      return item['stringValue'] ?? '';
                    },
                  ).toList(),
              'expirationDate': fields['expirationDate']?['stringValue'],
              'isActive': fields['isActive']?['booleanValue'] ?? true,
              'joinDate': fields['joinDate']?['stringValue'],
              'lastPaymentDate': fields['lastPaymentDate']?['stringValue'],
              'membershipType':
                  fields['membershipType']?['stringValue'] ?? 'normal',
              'name': fields['name']?['stringValue'] ?? '',
              'phone': fields['phone']?['stringValue'] ?? '',
              'photoUrl': fields['photoUrl']?['stringValue'],
              'qrCode': fields['qrCode']?['stringValue'],
              'userNumber': fields['userNumber']?['stringValue'] ?? '',
            };

            if (kDebugMode) {
              print('Procesando usuario con ID: $key');
              print('Datos extraídos: $userData');
            }

            users.add(UserModel.fromJson(userData));
          }
        }
      });

      return users;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener usuarios: $e');
      }
      return [];
    }
  }

  /// Agrega un nuevo usuario
  Future<bool> addUser(UserModel user) async {
    try {
      final response = await _apiProvider.add(user.toJson());
      return !response['error'];
    } catch (e) {
      if (kDebugMode) {
        print('Error al agregar usuario: $e');
      }
      return false;
    }
  }

  /// Agrega un usuario con ID específico
  Future<bool> addUserWithId(String id, UserModel user) async {
    try {
      final response = await _apiProvider.addDocument(id, user.toJson());
      return !response['error'];
    } catch (e) {
      if (kDebugMode) {
        print('Error al agregar usuario con ID: $e');
      }
      return false;
    }
  }

  /// Actualiza un usuario existente
  Future<bool> updateUser(String id, UserModel user) async {
    try {
      final response = await _apiProvider.update(id, user.toJson());
      return !response['error'];
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar usuario: $e');
      }
      return false;
    }
  }

  /// Elimina un usuario por su ID
  Future<bool> deleteUser(String id) async {
    try {
      final response = await _apiProvider.delete(id);
      return !response['error'];
    } catch (e) {
      if (kDebugMode) {
        print('Error al eliminar usuario: $e');
      }
      return false;
    }
  }
}
