import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

/// Widget optimizado para mostrar imágenes de usuarios con caché automático
/// 
/// Características:
/// - Caché automático en disco y memoria
/// - Placeholder mientras carga
/// - Manejo de errores con avatar por defecto
/// - Compresión y optimización transparente
class CachedUserImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool isCircular;
  final String? userName;
  final BoxFit fit;
  final Color? backgroundColor;

  const CachedUserImage({
    super.key,
    required this.imageUrl,
    this.size = 50.0,
    this.isCircular = true,
    this.userName,
    this.fit = BoxFit.cover,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay URL, mostrar avatar por defecto
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildDefaultAvatar();
    }

    // Retornar directamente CachedNetworkImage con imageBuilder optimizado
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) {
        // Usar Container con DecorationImage para mantener proporciones
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircular ? null : BorderRadius.circular(8),
            image: DecorationImage(
              image: imageProvider,
              fit: fit,
              alignment: Alignment.center, // Centrar la imagen
            ),
          ),
        );
      },
      placeholder: (context, url) => _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) {
        if (kDebugMode) {
          print('❌ Error cargando imagen: $url - $error');
        }
        return _buildDefaultAvatar();
      },
      // Configuración de caché optimizada
      cacheKey: imageUrl,
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 800,
      memCacheWidth: 400,
      memCacheHeight: 400,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  /// Placeholder mientras se carga la imagen
  Widget _buildLoadingPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(8),
        color: backgroundColor ?? Colors.grey[300],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  /// Avatar por defecto cuando no hay imagen
  Widget _buildDefaultAvatar() {
    // Obtener iniciales del nombre si está disponible
    String initials = '?';
    if (userName != null && userName!.isNotEmpty) {
      final names = userName!.trim().split(' ');
      if (names.length >= 2) {
        initials = '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        initials = userName![0].toUpperCase();
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(8),
        color: backgroundColor ?? Colors.grey[400],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Widget para mostrar imagen de perfil de usuario con borde opcional
class UserProfileImage extends StatelessWidget {
  final String? imageUrl;
  final String? userName;
  final double size;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;

  const UserProfileImage({
    super.key,
    required this.imageUrl,
    this.userName,
    this.size = 100.0,
    this.showBorder = true,
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = CachedUserImage(
      imageUrl: imageUrl,
      userName: userName,
      size: size,
      isCircular: true,
    );

    if (!showBorder) {
      return imageWidget;
    }

    return Container(
      width: size + (borderWidth * 2),
      height: size + (borderWidth * 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: imageWidget,
      ),
    );
  }
}

/// Widget para thumbnail pequeño de usuario (para listas)
class UserThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? userName;
  final double size;

  const UserThumbnail({
    super.key,
    required this.imageUrl,
    this.userName,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return CachedUserImage(
      imageUrl: imageUrl,
      userName: userName,
      size: size,
      isCircular: true,
    );
  }
}
