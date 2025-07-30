import 'package:flutter/material.dart';

/// Widget para crear layouts responsivos en toda la aplicación
/// 
/// Este widget utiliza un enfoque unificado para manejar layouts
/// responsivos en diferentes tamaños de pantalla, asegurando que
/// no haya desbordamientos.
class ResponsiveLayout extends StatelessWidget {
  /// El contenido principal que se mostrará dentro del layout responsivo
  final Widget child;
  
  /// Padding horizontal para el contenedor principal
  final double horizontalPadding;
  
  /// Padding vertical para el contenedor principal
  final double verticalPadding;
  
  /// Si debe usar SafeArea para evitar notch, cámaras, etc.
  final bool useSafeArea;
  
  /// Si debe permitir scroll en contenido (recomendado para prevenir overflow)
  final bool enableScroll;
  
  /// Si el contenido debe ocupar todo el espacio disponible
  final bool expandContent;
  
  /// Color de fondo del contenedor
  final Color? backgroundColor;

  /// Constructor principal para el layout responsivo
  const ResponsiveLayout({
    super.key,
    required this.child,
    this.horizontalPadding = 16.0,
    this.verticalPadding = 16.0,
    this.useSafeArea = true,
    this.enableScroll = true,
    this.expandContent = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: expandContent
          ? ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: useSafeArea
                    ? MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        (verticalPadding * 2)
                    : MediaQuery.of(context).size.height - (verticalPadding * 2),
              ),
              child: child,
            )
          : child,
    );

    final Widget scrollWrapper = enableScroll
        ? SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: content,
          )
        : content;

    return Container(
      color: backgroundColor,
      child: useSafeArea
          ? SafeArea(child: scrollWrapper)
          : scrollWrapper,
    );
  }
}

/// Extension para facilitar el manejo de restricciones responsivas
extension ResponsiveConstraints on BoxConstraints {
  /// Determina si el dispositivo es una tableta basado en su ancho
  bool get isTablet => maxWidth > 600;
  
  /// Determina si el dispositivo es un teléfono pequeño
  bool get isSmallPhone => maxWidth < 360;
  
  /// Calcula un tamaño de fuente adaptativo basado en el ancho
  double adaptiveFontSize(double base, {double min = 12, double max = 24}) {
    return (base * maxWidth / 400).clamp(min, max);
  }
  
  /// Calcula un valor adaptativo para espaciado o tamaños
  double adaptiveSize(double base, {double min = 8, double max = 32}) {
    return (base * maxWidth / 400).clamp(min, max);
  }
}

/// Extension para acceder a propiedades responsivas en BuildContext
extension ResponsiveContext on BuildContext {
  /// Obtiene el tamaño de la pantalla
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Obtiene el ancho de la pantalla
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Obtiene el alto de la pantalla
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Determina si el dispositivo está en orientación landscape
  bool get isLandscape => 
      MediaQuery.of(this).orientation == Orientation.landscape;
  
  /// Determina si el dispositivo es una tableta basado en su ancho
  bool get isTablet => screenWidth > 600;
  
  /// Determina si el dispositivo es un teléfono pequeño
  bool get isSmallPhone => screenWidth < 360;
  
  /// Calcula un tamaño adaptativo basado en el ancho de la pantalla
  double adaptiveSize(double size) => 
      (size * screenWidth / 400).clamp(size * 0.7, size * 1.3);
}
