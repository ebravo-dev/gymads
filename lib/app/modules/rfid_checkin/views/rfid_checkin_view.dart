import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import '../controllers/rfid_checkin_controller.dart';
import 'package:gymads/core/theme/app_colors.dart';

// Painter personalizado para el patrón de la llave
class KeyPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    
    // Patrón de llave (como una onda con dientes)
    final double startX = 0;
    final double endX = size.width;
    final double midY = size.height / 2;
    
    path.moveTo(startX, midY);
    
    // Primer diente
    path.lineTo(size.width * 0.2, midY);
    path.lineTo(size.width * 0.3, midY - 15);
    path.lineTo(size.width * 0.4, midY);
    
    // Segundo diente
    path.lineTo(size.width * 0.5, midY);
    path.lineTo(size.width * 0.6, midY + 15);
    path.lineTo(size.width * 0.7, midY);
    
    // Final recto
    path.lineTo(endX, midY);
    
    // Dibujar el patrón
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RfidCheckinView extends GetView<RfidCheckinController> {
  const RfidCheckinView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso con Tarjeta'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        actions: [
          // Botón de configuración para cambiar IP del lector RFID
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showRfidConfigDialog(context),
            tooltip: 'Configurar lector RFID',
          ),
        ],
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
  
  // Diálogo para configurar la dirección IP del lector RFID
  void _showRfidConfigDialog(BuildContext context) {
    final TextEditingController ipController = TextEditingController(
      text: controller.getReaderIpAddress(),
    );
    
    Get.dialog(
      AlertDialog(
        title: const Text('Configurar Lector RFID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configura la dirección IP del lector RFID:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'Dirección IP',
                hintText: 'Ej: 192.168.1.100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nota: Asegúrate de que el dispositivo está en la misma red.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newIp = ipController.text.trim();
              if (newIp.isNotEmpty) {
                controller.updateReaderIpAddress(newIp);
                Get.back();
                Get.snackbar(
                  'Configuración actualizada',
                  'Dirección IP del lector RFID actualizada a: $newIp',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Guardar'),
          ),
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
            'Acerque la tarjeta al lector para registrar su entrada',
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
          
          const SizedBox(height: 16),
          
          // Botón para simular lectura (solo en desarrollo)
          ElevatedButton.icon(
            onPressed: () {
              final random = DateTime.now().millisecondsSinceEpoch.toString();
              controller.checkAccessByRfid(random);
            },
            icon: const Icon(Icons.contactless),
            label: const Text('Simular Lectura RFID'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Construir ondas circulares (ripple) con mejor visibilidad
  Widget _buildRipple({required int delay, required Color color}) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        // Calcula el valor de la animación con retraso
        final delayedValue = ((controller.animationController.value * 3000) + delay) % 3000 / 3000;
        
        // Opacidad que se desvanece más lentamente para mejor visibilidad
        // Usamos un rango más amplio para que sea más visible (0.2 a 0.9)
        final opacity = (1.0 - delayedValue * 0.8).clamp(0.2, 0.9);
        
        // Escala que crece desde el centro, con un tamaño inicial mayor
        final scale = 0.4 + (delayedValue * 0.6);
        
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 120,  // Tamaño más grande para mejor visibilidad
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Usamos un borde más grueso para mejor visibilidad
                border: Border.all(
                  color: color,
                  width: 3,
                ),
                // Añadimos un efecto de brillo para mejorar la visibilidad
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
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
          // Contenedor para la animación con fondo oscuro para mejor contraste
          Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              // Fondo más oscuro para mejor contraste con las ondas
              color: Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ondas animadas circulares con colores muy visibles
                // Usamos colores más brillantes y contrastantes
                _buildRipple(delay: 0, color: Colors.white.withOpacity(0.9)),
                _buildRipple(delay: 1000, color: AppColors.accent),
                _buildRipple(delay: 2000, color: Colors.white.withOpacity(0.7)),
                
                // Tarjeta RFID centrada (icono mejorado)
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.credit_card,
                    size: 40,
                    color: AppColors.primary,
                  ),
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
        // Calculamos un valor de pulso seguro entre 0.9 y 1.1
        final pulseValue = 0.95 + (0.05 * sinValue);
        
        return Transform.scale(
          scale: pulseValue,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tap_and_play,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Esperando tarjeta$dots',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
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
