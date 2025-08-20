import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import '../controllers/rfid_checkin_controller.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:gymads/core/utils/responsive_utils.dart';

class RfidCheckinView extends GetView<RfidCheckinController> {
  const RfidCheckinView({super.key});

  @override
  Widget build(BuildContext context) {
    // Determinar si es una tableta basado en el ancho de la pantalla
    final bool isTabletSize = MediaQuery.of(context).size.width > 600;
    
    // Determinar si es un teléfono pequeño
    final bool isSmallPhone = MediaQuery.of(context).size.width < 360;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso con Tarjeta'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Mostrar advertencia si no está conectado, sino mostrar contenido principal
            Obx(() => controller.isRfidConnected.value
                ? _buildMainContent(context, isTabletSize, isSmallPhone)
                : _buildConnectionWarning(context, isTabletSize, isSmallPhone)),
            
            // Indicador de carga
            Obx(() => controller.isLoading.value
                ? Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink()),
            
            // Pantalla de bienvenida cuando se detecta una tarjeta
            Obx(() => controller.isShowingDialog.value
                ? _buildWelcomeScreen(context, isTabletSize, isSmallPhone)
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMainContent(BuildContext context, bool isTabletSize, bool isSmallPhone) {
    // Calculamos padding adaptativo según el tamaño de pantalla
    final paddingValue = ResponsiveValues.getSpacing(context,
      mobile: 24,
      smallPhone: 16,
      tablet: 32
    );
    
    final padding = EdgeInsets.all(paddingValue);
    
    // Tamaños de texto responsivos
    final titleSize = ResponsiveValues.getFontSize(context,
      mobile: 24,
      smallPhone: 20,
      tablet: 32
    );
    
    final subtitleSize = ResponsiveValues.getFontSize(context,
      mobile: 18,
      smallPhone: 16,
      tablet: 22
    );

    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Control de Acceso',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallPhone ? 12 : 16),
          Text(
            'Acerque la tarjeta o llavero al lector para registrar su entrada',
            style: TextStyle(fontSize: subtitleSize),
            textAlign: TextAlign.center,
          ),
          
          // Añadimos espacio adaptativo
          SizedBox(height: ResponsiveValues.getSpacing(context,
            mobile: 40,
            smallPhone: 30,
            tablet: 60
          )),
          
          // Animación de tarjeta RFID con ondas
          _buildRfidAnimation(context, isTabletSize, isSmallPhone),
          
          const Spacer(),
          
          // Mensajes de error
          Obx(() => controller.errorMessage.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: isTabletSize
                          ? 18.0
                          : (isSmallPhone ? 14.0 : 16.0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  // Construir ondas circulares (ripple) que rodean la tarjeta
  Widget _buildRipple({
    required BuildContext context,
    required int delay, 
    required Color color,
    required bool isTabletSize,
    required bool isSmallPhone,
    double? size,
  }) {
    // Tamaño adaptativo según el tamaño de pantalla
    final rippleSize = size ?? (isTabletSize
        ? 180.0
        : (isSmallPhone ? 100.0 : 120.0));
    
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        // Calcula el valor de la animación con retraso
        final delayedValue = ((controller.animationController.value * 3000) + delay) % 3000 / 3000;
        
        // Opacidad que pulsa suavemente para mejor visibilidad
        final pulseValue = sin(delayedValue * pi * 2).clamp(-1.0, 1.0);
        final opacity = (0.4 + (pulseValue * 0.2)).clamp(0.2, 0.6);
        
        // Escala con valores fijos - pulso muy ligero
        final scale = 0.98 + (pulseValue * 0.02);
        
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: rippleSize,
              height: rippleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Animación de tarjeta RFID con ondas
  Widget _buildRfidAnimation(BuildContext context, bool isTabletSize, bool isSmallPhone) {
    // Tamaños responsivos
    final containerSize = isTabletSize
        ? 280.0
        : (isSmallPhone ? 170.0 : 200.0);
    
    final iconSize = isTabletSize
        ? 120.0
        : (isSmallPhone ? 64.0 : 80.0);
    
    final rippleOuterSize = containerSize * 0.9;
    final rippleMiddleSize = containerSize * 0.7;
    final rippleInnerSize = containerSize * 0.5;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenedor para la animación
          Container(
            height: containerSize,
            width: containerSize,
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ondas animadas circulares
                _buildRipple(
                  context: context,
                  delay: 0, 
                  color: AppColors.accent.withOpacity(0.7),
                  size: rippleOuterSize,
                  isTabletSize: isTabletSize,
                  isSmallPhone: isSmallPhone,
                ),
                _buildRipple(
                  context: context,
                  delay: 1000, 
                  color: AppColors.primary.withOpacity(0.7),
                  size: rippleMiddleSize,
                  isTabletSize: isTabletSize,
                  isSmallPhone: isSmallPhone,
                ),
                _buildRipple(
                  context: context,
                  delay: 2000, 
                  color: AppColors.accent.withOpacity(0.7),
                  size: rippleInnerSize,
                  isTabletSize: isTabletSize,
                  isSmallPhone: isSmallPhone,
                ),
                
                // Icono de la tarjeta RFID
                Icon(
                  Icons.credit_card,
                  size: iconSize,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Texto animado con puntos suspensivos
          _buildLoadingText(context, isTabletSize, isSmallPhone),
        ],
      ),
    );
  }
  
  // Texto animado de carga con efecto de pulsado
  Widget _buildLoadingText(BuildContext context, bool isTabletSize, bool isSmallPhone) {
    // Tamaño de texto adaptativo
    final textSize = isTabletSize
        ? 22.0
        : (isSmallPhone ? 16.0 : 18.0);
    
    // Tamaño de icono adaptativo
    final iconSize = isTabletSize
        ? 28.0
        : (isSmallPhone ? 20.0 : 24.0);

    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        // Dots animation for loading effect
        final dotsValue = (controller.animationController.value * 3) % 3;
        final dots = '.'.padRight(dotsValue.floor() + 1, '.');
        
        // Pulse animation for text con valores seguros
        final animValue = controller.animationController.value * pi * 2;
        final sinValue = sin(animValue).clamp(-1.0, 1.0);
        final pulseValue = 0.95 + (0.05 * sinValue);
        
        return Transform.scale(
          scale: pulseValue,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTabletSize ? 28 : 20, 
              vertical: isTabletSize ? 16 : 12
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.contactless_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
                SizedBox(width: isSmallPhone ? 6 : 10),
                Flexible(
                  child: Text(
                    'Esperando tarjeta o llavero$dots',
                    style: TextStyle(
                      fontSize: textSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeScreen(BuildContext context, bool isTabletSize, bool isSmallPhone) {
    // Tamaños responsivos para pantalla de bienvenida
    final titleSize = isTabletSize
        ? 60.0
        : (isSmallPhone ? 36.0 : 48.0);
    
    final nameSize = isTabletSize
        ? 42.0
        : (isSmallPhone ? 28.0 : 36.0);
    
    final infoTextSize = isTabletSize
        ? 24.0
        : (isSmallPhone ? 18.0 : 20.0);
    
    // Tamaño del círculo con foto
    final photoSize = isTabletSize
        ? 320.0
        : (isSmallPhone ? 180.0 : 250.0);

    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: AnimatedBuilder(
          animation: controller.animationController,
          builder: (context, child) {
            // Valor fijo para la escala
            final scale = 1.0;
            
            // Ligero movimiento ondulante
            final animValue = controller.animationController.value * pi * 2;
            final sinValue = sin(animValue).clamp(-1.0, 1.0);
            final breathingEffect = 1.0 + 0.005 * sinValue;
            
            return Transform.scale(
              scale: scale * breathingEffect,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isTabletSize ? 40 : 24
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Título de bienvenida con efecto de aparición
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          final safeOpacity = value.clamp(0.0, 1.0);
                          return Opacity(
                            opacity: safeOpacity,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Text(
                                '¡Bienvenido!',
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                      SizedBox(height: isTabletSize ? 40 : 32),
                      
                      // Foto del usuario con efecto de aura
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          final safeOpacity = value.clamp(0.0, 1.0);
                          return Opacity(
                            opacity: safeOpacity,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Aura exterior
                                Container(
                                  width: (photoSize + 20) * value,
                                  height: (photoSize + 20) * value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                // Aura interior
                                Container(
                                  width: (photoSize + 10) * value,
                                  height: (photoSize + 10) * value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent.withOpacity(0.3),
                                  ),
                                ),
                                // Foto
                                Container(
                                  width: photoSize * value,
                                  height: photoSize * value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.5),
                                        spreadRadius: 5,
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                  child: Obx(() => controller.userPhotoUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(photoSize/2 * value),
                                          child: Image.network(
                                            controller.userPhotoUrl.value,
                                            width: photoSize * value,
                                            height: photoSize * value,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, error, _) => CircleAvatar(
                                              radius: photoSize/2 * value,
                                              child: Icon(Icons.person, size: photoSize/2 * value),
                                            ),
                                          ),
                                        )
                                      : CircleAvatar(
                                          radius: photoSize/2 * value,
                                          backgroundColor: Colors.grey[200],
                                          child: Icon(
                                            Icons.person,
                                            size: photoSize/2 * value,
                                            color: AppColors.primary,
                                          ),
                                        )),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                      SizedBox(height: isSmallPhone ? 20 : 24),
                      
                      // Nombre del usuario con animación de entrada
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutQuart,
                        builder: (context, value, child) {
                          final safeOpacity = value.clamp(0.0, 1.0);
                          return Opacity(
                            opacity: safeOpacity,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Obx(() => Text(
                                controller.userName.value,
                                style: TextStyle(
                                  fontSize: nameSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              )),
                            ),
                          );
                        }
                      ),
                      SizedBox(height: isSmallPhone ? 12 : 16),
                      
                      // Tipo de membresía con animación de entrada
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1400),
                        curve: Curves.easeOutQuart,
                        builder: (context, value, child) {
                          final safeOpacity = value.clamp(0.0, 1.0);
                          return Opacity(
                            opacity: safeOpacity,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Obx(() => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTabletSize ? 28 : 20, 
                                  vertical: isTabletSize ? 12 : 8
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  controller.membershipType.value.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: isTabletSize
                                        ? 22.0
                                        : (isSmallPhone ? 16.0 : 18.0),
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )),
                            ),
                          );
                        }
                      ),
                      
                      SizedBox(height: isSmallPhone ? 12 : 16),
                      
                      // Días restantes con animación de entrada
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1600),
                        curve: Curves.easeOutQuart,
                        builder: (context, value, child) {
                          final safeOpacity = value.clamp(0.0, 1.0);
                          return Opacity(
                            opacity: safeOpacity,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Obx(() => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTabletSize ? 20 : 16, 
                                  vertical: isTabletSize ? 12 : 8
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_available,
                                      color: Colors.white,
                                      size: isTabletSize
                                          ? 28.0
                                          : (isSmallPhone ? 20.0 : 24.0),
                                    ),
                                    SizedBox(width: isSmallPhone ? 6 : 8),
                                    Text(
                                      'Días restantes: ${controller.daysLeft.value}',
                                      style: TextStyle(
                                        fontSize: infoTextSize,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
  
  // Pantalla de advertencia cuando el ESP32 no está conectado
  Widget _buildConnectionWarning(BuildContext context, bool isTabletSize, bool isSmallPhone) {
    final paddingValue = ResponsiveValues.getSpacing(context,
      mobile: 24,
      smallPhone: 16,
      tablet: 32
    );
    
    final titleSize = ResponsiveValues.getFontSize(context,
      mobile: 28,
      smallPhone: 24,
      tablet: 36
    );
    
    final subtitleSize = ResponsiveValues.getFontSize(context,
      mobile: 18,
      smallPhone: 16,
      tablet: 22
    );
    
    final buttonTextSize = ResponsiveValues.getFontSize(context,
      mobile: 16,
      smallPhone: 14,
      tablet: 20
    );

    return Container(
      padding: EdgeInsets.all(paddingValue),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono de advertencia animado
          AnimatedBuilder(
            animation: controller.animationController,
            builder: (context, child) {
              final animValue = controller.animationController.value * pi * 2;
              final sinValue = sin(animValue).clamp(-1.0, 1.0);
              final pulseValue = 0.95 + (0.05 * sinValue);
              
              return Transform.scale(
                scale: pulseValue,
                child: Container(
                  padding: EdgeInsets.all(isTabletSize ? 32 : 24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.wifi_off,
                    size: isTabletSize ? 80 : (isSmallPhone ? 50 : 64),
                    color: Colors.orange,
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: isTabletSize ? 40 : 32),
          
          // Título de advertencia
          Text(
            'Lector RFID Desconectado',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isTabletSize ? 24 : 16),
          
          // Mensaje de estado
          Obx(() => Text(
            controller.connectionStatusMessage.value,
            style: TextStyle(
              fontSize: subtitleSize,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          )),
          
          SizedBox(height: isTabletSize ? 16 : 12),
          
          // Mensaje de descripción
          Text(
            'El sistema no puede detectar el lector RFID ESP32.\nVerifica que esté conectado a WiFi y funcionando correctamente.',
            style: TextStyle(
              fontSize: ResponsiveValues.getFontSize(context,
                mobile: 16,
                smallPhone: 14,
                tablet: 18
              ),
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isTabletSize ? 48 : 32),
          
          // Botones de acción
          Column(
            children: [
              // Botón reintentar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.retryConnection,
                  icon: Icon(
                    Icons.refresh,
                    size: isTabletSize ? 24 : 20,
                  ),
                  label: Text(
                    'Reintentar Conexión',
                    style: TextStyle(
                      fontSize: buttonTextSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isTabletSize ? 18 : 16
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              
              SizedBox(height: isTabletSize ? 16 : 12),
              
              // Botón configurar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.goToRfidConfiguration,
                  icon: Icon(
                    Icons.settings,
                    size: isTabletSize ? 24 : 20,
                    color: Colors.orange,
                  ),
                  label: Text(
                    'Configurar Lector RFID',
                    style: TextStyle(
                      fontSize: buttonTextSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange, width: 2),
                    padding: EdgeInsets.symmetric(
                      vertical: isTabletSize ? 18 : 16
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isTabletSize ? 32 : 24),
          
          // Información adicional
          Container(
            padding: EdgeInsets.all(isTabletSize ? 20 : 16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: isTabletSize ? 24 : 20,
                ),
                SizedBox(width: isTabletSize ? 12 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                          fontSize: ResponsiveValues.getFontSize(context,
                            mobile: 16,
                            smallPhone: 14,
                            tablet: 18
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'El lector RFID ESP32 debe estar conectado a WiFi para funcionar. Ve a Configuración para verificar la conexión.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: ResponsiveValues.getFontSize(context,
                            mobile: 14,
                            smallPhone: 12,
                            tablet: 16
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
