import 'package:flutter/material.dart';

/// Extensión de contexto para facilitar el acceso a las dimensiones de pantalla
extension ResponsiveContext on BuildContext {
  /// Devuelve el tamaño de la pantalla actual
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Devuelve el ancho de la pantalla
  double get screenWidth => screenSize.width;
  
  /// Devuelve la altura de la pantalla
  double get screenHeight => screenSize.height;
  
  /// Verifica si el dispositivo es una tablet (ancho > 600)
  bool get isTablet => screenWidth > 600;
  
  /// Verifica si el dispositivo es un teléfono pequeño (ancho < 360)
  bool get isSmallPhone => screenWidth < 360;
  
  /// Verifica si el dispositivo está en modo landscape
  bool get isLandscape => screenWidth > screenHeight;
  
  /// Devuelve el padding seguro para evitar notches y otros elementos
  EdgeInsets get safePadding => MediaQuery.of(this).padding;
  
  /// Calcula un valor adaptativo según el ancho de la pantalla
  double adaptiveWidth(double percentage) => screenWidth * percentage;
  
  /// Calcula un valor adaptativo según la altura de la pantalla
  double adaptiveHeight(double percentage) => screenHeight * percentage;
}

/// Extensión para ayudar con las restricciones de tamaño
extension ResponsiveConstraints on BoxConstraints {
  /// Verifica si el ancho máximo disponible corresponde a una tablet
  bool get isTablet => maxWidth > 600;
  
  /// Verifica si el ancho máximo corresponde a un teléfono pequeño
  bool get isSmallPhone => maxWidth < 360;
  
  /// Verifica si estamos en modo landscape
  bool get isLandscape => maxWidth > maxHeight;
}

/// Widget de diseño responsivo que cambia según el tamaño de pantalla
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? smallMobile;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.smallMobile,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          // Vista de escritorio
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth > 600) {
          // Vista de tablet
          return tablet ?? mobile;
        } else if (constraints.maxWidth < 360) {
          // Vista de teléfono pequeño
          return smallMobile ?? mobile;
        } else {
          // Vista móvil por defecto
          return mobile;
        }
      },
    );
  }
}

/// Widget para crear padding adaptativo según el tamaño de pantalla
class AdaptivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final EdgeInsets? smallMobilePadding;

  const AdaptivePadding({
    super.key,
    required this.child,
    required this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.smallMobilePadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        EdgeInsets padding;
        
        if (constraints.maxWidth > 1200) {
          // Padding para desktop
          padding = desktopPadding ?? tabletPadding ?? mobilePadding;
        } else if (constraints.maxWidth > 600) {
          // Padding para tablet
          padding = tabletPadding ?? mobilePadding;
        } else if (constraints.maxWidth < 360) {
          // Padding para teléfono pequeño
          padding = smallMobilePadding ?? mobilePadding;
        } else {
          // Padding móvil por defecto
          padding = mobilePadding;
        }
        
        return Padding(
          padding: padding,
          child: child,
        );
      },
    );
  }
}

/// Función para calcular un valor responsivo basado en el ancho de pantalla
double getResponsiveValue({
  required BuildContext context,
  required double defaultValue,
  double? tabletValue,
  double? desktopValue,
  double? smallPhoneValue,
}) {
  final width = MediaQuery.of(context).size.width;
  
  if (width > 1200) {
    return desktopValue ?? tabletValue ?? defaultValue;
  } else if (width > 600) {
    return tabletValue ?? defaultValue;
  } else if (width < 360) {
    return smallPhoneValue ?? defaultValue;
  } else {
    return defaultValue;
  }
}

/// Clase con valores responsive predefinidos
class ResponsiveValues {
  /// Verifica si el dispositivo es una tablet (ancho > 600)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }
  
  /// Verifica si el dispositivo es un teléfono móvil estándar
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width <= 600 && width >= 360;
  }
  
  /// Verifica si el dispositivo es un teléfono pequeño (ancho < 360)
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  /// Devuelve la altura de la pantalla
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// Devuelve el ancho de la pantalla o un valor adaptado según el tipo de dispositivo
  static double getWidth(BuildContext context, {
    double mobile = 400.0,
    double tablet = 600.0,
    double desktop = 800.0,
    double smallPhone = 300.0,
  }) {
    return getResponsiveValue(
      context: context,
      defaultValue: mobile,
      tabletValue: tablet,
      desktopValue: desktop,
      smallPhoneValue: smallPhone,
    );
  }
  
  static double getFontSize(BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
    double smallPhone = 12.0,
  }) {
    return getResponsiveValue(
      context: context,
      defaultValue: mobile,
      tabletValue: tablet,
      desktopValue: desktop,
      smallPhoneValue: smallPhone,
    );
  }
  
  static double getSpacing(BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
    double smallPhone = 12.0,
  }) {
    return getResponsiveValue(
      context: context,
      defaultValue: mobile,
      tabletValue: tablet,
      desktopValue: desktop,
      smallPhoneValue: smallPhone,
    );
  }
  
  static double getIconSize(BuildContext context, {
    double mobile = 24.0,
    double tablet = 28.0,
    double desktop = 32.0,
    double smallPhone = 20.0,
  }) {
    return getResponsiveValue(
      context: context,
      defaultValue: mobile,
      tabletValue: tablet,
      desktopValue: desktop,
      smallPhoneValue: smallPhone,
    );
  }
  
  /// Devuelve un tamaño genérico adaptado al dispositivo
  static double getSize(BuildContext context, {
    double mobile = 24.0,
    double tablet = 32.0,
    double desktop = 40.0,
    double smallPhone = 20.0,
  }) {
    return getResponsiveValue(
      context: context,
      defaultValue: mobile,
      tabletValue: tablet,
      desktopValue: desktop,
      smallPhoneValue: smallPhone,
    );
  }
}

/// Ejemplos de uso para evitar overflow en filas:
///
/// Uso de Wrap en lugar de Row:
/// ```dart
/// Wrap(
///   spacing: 16,
///   crossAxisAlignment: WrapCrossAlignment.center,
///   children: [
///     Icon(Icons.some_icon),
///     Text('Texto largo que puede desbordar'),
///     // ...otros widgets
///   ],
/// )
/// ```
///
/// Uso de Expanded con TextOverflow.ellipsis:
/// ```dart
/// Row(
///   children: [
///     Icon(Icons.some_icon),
///     const SizedBox(width: 8),
///     Expanded(
///       child: Text(
///         'Texto largo que podría causar overflow',
///         overflow: TextOverflow.ellipsis,
///       ),
///     ),
///   ],
/// )
/// ```
