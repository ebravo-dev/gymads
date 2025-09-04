import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

/// Servicio para manejar la reproducción de audio en la aplicación
class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  /// Reproduce el sonido de bienvenida cuando un usuario escanea exitosamente
  static Future<void> playWelcomeSound() async {
    try {
      if (kDebugMode) {
        print('🔊 Reproduciendo sonido de bienvenida...');
      }
      
      // Cargar el archivo de audio de bienvenida
      await _audioPlayer.setAsset('assets/audio/welcome.mp3');
      
      // Configurar volumen a 80%
      await _audioPlayer.setVolume(0.8);
      
      // Configurar velocidad normal
      await _audioPlayer.setSpeed(1.0);
      
      // Reproducir desde el inicio
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      
      if (kDebugMode) {
        print('✅ Sonido de bienvenida reproducido correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al reproducir sonido de bienvenida: $e');
        print('📊 Tipo de error: ${e.runtimeType}');
      }
    }
  }
  
  /// Reproduce un sonido de error
  static Future<void> playErrorSound() async {
    try {
      if (kDebugMode) {
        print('🔊 Reproduciendo sonido de error...');
      }
      
      // Cargar el archivo de audio de bienvenida (usado como error)
      await _audioPlayer.setAsset('assets/audio/welcome.mp3');
      
      // Configurar para error (volumen más bajo y velocidad más lenta)
      await _audioPlayer.setVolume(0.6); // Más bajo para error
      await _audioPlayer.setSpeed(0.7); // Más lento para indicar error
      
      // Reproducir desde el inicio
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      
      // Resetear la velocidad y volumen después de un momento
      Future.delayed(const Duration(milliseconds: 800), () async {
        try {
          await _audioPlayer.setSpeed(1.0);
          await _audioPlayer.setVolume(0.8);
        } catch (e) {
          if (kDebugMode) print('Error al resetear configuración de audio: $e');
        }
      });
      
      if (kDebugMode) {
        print('✅ Sonido de error reproducido correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al reproducir sonido de error: $e');
        print('📊 Tipo de error: ${e.runtimeType}');
      }
    }
  }
  
  /// Reproduce el sonido de acceso denegado cuando el usuario no está registrado
  static Future<void> playDeniedSound() async {
    try {
      if (kDebugMode) {
        print('🔊 Reproduciendo sonido de acceso denegado...');
      }
      
      // Cargar el archivo de audio de denegado
      await _audioPlayer.setAsset('assets/audio/denegado.mp3');
      
      // Configurar volumen a 85%
      await _audioPlayer.setVolume(0.85);
      
      // Configurar velocidad normal
      await _audioPlayer.setSpeed(1.0);
      
      // Reproducir desde el inicio
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      
      if (kDebugMode) {
        print('✅ Sonido de acceso denegado reproducido correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al reproducir sonido de acceso denegado: $e');
        print('📊 Tipo de error: ${e.runtimeType}');
      }
    }
  }
  
  /// Reproduce un sonido de éxito con configuración específica
  static Future<void> playSuccessSound() async {
    try {
      if (kDebugMode) {
        print('🔊 Reproduciendo sonido de éxito...');
      }
      
      // Cargar el archivo de audio de bienvenida
      await _audioPlayer.setAsset('assets/audio/welcome.mp3');
      
      // Configurar para éxito (velocidad más rápida)
      await _audioPlayer.setVolume(0.8);
      await _audioPlayer.setSpeed(1.2); // Más rápido para indicar éxito
      
      // Reproducir desde el inicio
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      
      // Resetear la velocidad después de un momento
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          await _audioPlayer.setSpeed(1.0);
        } catch (e) {
          if (kDebugMode) print('Error al resetear velocidad de audio: $e');
        }
      });
      
      if (kDebugMode) {
        print('✅ Sonido de éxito reproducido correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al reproducir sonido de éxito: $e');
        print('📊 Tipo de error: ${e.runtimeType}');
      }
    }
  }
  
  /// Detiene cualquier audio que se esté reproduciendo
  static Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      if (kDebugMode) {
        print('🔇 Audio detenido');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al detener audio: $e');
      }
    }
  }
  
  /// Libera los recursos del reproductor de audio
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      if (kDebugMode) {
        print('🗑️ Recursos de audio liberados');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al liberar recursos de audio: $e');
      }
    }
  }
  
  /// Configura el volumen del audio
  static Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      if (kDebugMode) {
        print('🔊 Volumen configurado a: ${(volume * 100).toInt()}%');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al configurar volumen: $e');
      }
    }
  }
}
