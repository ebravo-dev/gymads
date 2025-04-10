import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/supabase_client.dart';

class StorageProvider {
  Future<String?> uploadUserPhoto(File photoFile, String userId) async {
    try {
      var urlPhoto =
          await SupabaseService.uploadUserPhoto(photoFile.path, userId);
      if (kDebugMode) {
        print('URL de la foto: $urlPhoto');
      }
      return urlPhoto;
    } catch (e) {
      if (kDebugMode) {
        print('Error al subir la foto: $e');
      }
      return null;
    }
  }

  Future<bool> deleteUserPhoto(String photoUrl) async {
    try {
      return await SupabaseService.deleteUserPhoto(photoUrl);
    } catch (e) {
      if (kDebugMode) {
        print('Error al eliminar la foto: $e');
      }
      return false;
    }
  }
}
