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

  /// Obtiene todos los usuarios disponibles
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _apiProvider.getAll();
      if (response['error'] || response['data'] == null) {
        return [];
      }

      final Map<String, dynamic> data = response['data'];
      final List<UserModel> users = [];

      data.forEach((key, value) {
        value['id'] = key;
        users.add(UserModel.fromJson(value));
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
