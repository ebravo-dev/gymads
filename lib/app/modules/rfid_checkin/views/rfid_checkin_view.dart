import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import '../controllers/rfid_checkin_controller.dart';
import 'package:gymads/core/theme/app_colors.dart';



class RfidCheckinView extends GetView<RfidCheckinController> {
  const RfidCheckinView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso con Tarjeta'),
        centerTitle: true,
        backgroundColor: AppColors.primary,

      ),
      body: Stack(
        children: [
          _buildMainContent(),
          
          // Indicador de carga
          Obx(() => controller.isLoading.value
              ? Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink()),
          
          // Pantalla de bienvenida cuando se detecta una tarjeta
          Obx(() => controller.isShowingDialog.value
              ? _buildWelcomeScreen()
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
  


  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Control de Acceso',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Acerque la tarjeta o llavero al lector para registrar su entrada',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          
          // Animación de tarjeta RFID con ondas
          const SizedBox(height: 40),
          _buildRfidAnimation(),
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
                    style: TextStyle(color: Colors.red.shade800),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  // Construir ondas circulares (ripple) que rodean la tarjeta - versión más sutil
  Widget _buildRipple({required int delay, required Color color, double size = 120}) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        // Calcula el valor de la animación con retraso
        final delayedValue = ((controller.animationController.value * 3000) + delay) % 3000 / 3000;
        
        // Opacidad que pulsa suavemente para mejor visibilidad
        // El seno nos da un efecto de pulso más natural - reducido para más sutileza
        final pulseValue = sin(delayedValue * pi * 2).clamp(-1.0, 1.0);
        final opacity = (0.4 + (pulseValue * 0.2)).clamp(0.2, 0.6); // Más sutil
        
        // Escala con valores fijos - pulso muy ligero
        final scale = 0.98 + (pulseValue * 0.02);
        
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,  // Tamaño personalizable
              height: size, // Tamaño personalizable
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Borde más fino para efecto minimalista
                border: Border.all(
                  color: color,
                  width: 1.5,
                ),
                // Efecto de brillo sutil
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

  // Animación de tarjeta RFID con ondas - versión mejorada para visibilidad
  Widget _buildRfidAnimation() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenedor para la animación más compacto
          Container(
            height: 200,  // Tamaño reducido para un diseño más minimalista
            width: 200,   // Tamaño reducido para un diseño más minimalista
            decoration: BoxDecoration(
              // Sin fondo para mantener la transparencia total
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ondas animadas circulares rodeando la tarjeta (más pequeñas para el nuevo diseño)
                // Usamos diferentes retrasos y tamaños para crear un efecto de ondas más natural
                _buildRipple(delay: 0, color: AppColors.accent.withOpacity(0.7), size: 180), // Onda exterior
                _buildRipple(delay: 1000, color: AppColors.primary.withOpacity(0.7), size: 140), // Onda media
                _buildRipple(delay: 2000, color: AppColors.accent.withOpacity(0.7), size: 100), // Onda interior
                
                // Solo el icono de la tarjeta RFID sin fondo ni contorno
                Icon(
                  Icons.credit_card,
                  size: 80,
                  color: Colors.white, // Icono en blanco para mejor contraste con el fondo
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Texto animado con puntos suspensivos
          _buildLoadingText(),
        ],
      ),
    );
  }
  
  // Texto animado de carga con efecto de pulsado
  Widget _buildLoadingText() {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        // Dots animation for loading effect
        final dotsValue = (controller.animationController.value * 3) % 3;
        final dots = '.'.padRight(dotsValue.floor() + 1, '.');
        
        // Pulse animation for text con valores seguros
        final animValue = controller.animationController.value * pi * 2;
        // Nos aseguramos que el valor de seno esté en rango seguro
        final sinValue = sin(animValue).clamp(-1.0, 1.0);
        // Calculamos un valor de pulso seguro entre 0.95 y 1.05
        final pulseValue = 0.95 + (0.05 * sinValue);
        
        return Transform.scale(
          scale: pulseValue,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              children: [
                Icon(
                  Icons.contactless_rounded,  // Icono más apropiado para RFID
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Esperando tarjeta o llavero$dots',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,  // Texto en blanco para mejor visibilidad
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: AnimatedBuilder(
          animation: controller.animationController,
          builder: (context, child) {
            // Usamos un valor fijo para la escala inicial en lugar de depender de la animación
            // Esto evita problemas con el controlador de animación
            final scale = 1.0;
            
            // Ligero movimiento ondulante para efecto de "vivo"
            // Limitamos el efecto para evitar valores fuera de rango
            final animValue = controller.animationController.value * pi * 2;
            // Aseguramos que el valor de seno esté en un rango seguro
            final sinValue = sin(animValue).clamp(-1.0, 1.0);
            final breathingEffect = 1.0 + 0.005 * sinValue;
            
            return Transform.scale(
              scale: scale * breathingEffect,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Título de bienvenida con efecto de aparición
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      // Aseguramos que el valor de opacidad esté en rango válido
                      final safeOpacity = value.clamp(0.0, 1.0);
                      return Opacity(
                        opacity: safeOpacity,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Text(
                            '¡Bienvenido!',
                            style: TextStyle(
                              fontSize: 48,
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
                  const SizedBox(height: 32),
                  
                  // Foto del usuario con efecto de aura
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      // Aseguramos que el valor de opacidad esté en rango válido
                      final safeOpacity = value.clamp(0.0, 1.0);
                      return Opacity(
                        opacity: safeOpacity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Aura exterior
                            Container(
                              width: 270 * value,
                              height: 270 * value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            // Aura interior
                            Container(
                              width: 260 * value,
                              height: 260 * value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent.withOpacity(0.3),
                              ),
                            ),
                            // Foto
                            Container(
                              width: 250 * value,
                              height: 250 * value,
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
                                      borderRadius: BorderRadius.circular(125 * value),
                                      child: Image.network(
                                        controller.userPhotoUrl.value,
                                        width: 250 * value,
                                        height: 250 * value,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, error, _) => CircleAvatar(
                                          radius: 125 * value,
                                          child: Icon(Icons.person, size: 125 * value),
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 125 * value,
                                      backgroundColor: Colors.grey[200],
                                      child: Icon(
                                        Icons.person,
                                        size: 125 * value,
                                        color: AppColors.primary,
                                      ),
                                    )),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 24),
                  
                  // Nombre del usuario con animación de entrada
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      // Aseguramos que el valor de opacidad esté en rango válido
                      final safeOpacity = value.clamp(0.0, 1.0);
                      return Opacity(
                        opacity: safeOpacity,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Obx(() => Text(
                            controller.userName.value,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )),
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 16),
                  
                  // Tipo de membresía con animación de entrada
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      // Aseguramos que el valor de opacidad esté en rango válido
                      final safeOpacity = value.clamp(0.0, 1.0);
                      return Opacity(
                        opacity: safeOpacity,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),
                        ),
                      );
                    }
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Días restantes con animación de entrada
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1600),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      // Aseguramos que el valor de opacidad esté en rango válido
                      final safeOpacity = value.clamp(0.0, 1.0);
                      return Opacity(
                        opacity: safeOpacity,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.event_available,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Días restantes: ${controller.daysLeft.value}',
                                  style: const TextStyle(
                                    fontSize: 20,
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
            );
          }
        ),
      ),
    );
  }
}
