import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  // Construir onda animada
  Widget _buildWave({required int delay, required double size}) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        // Ajustar el valor para que sea entre 0 y 1 considerando el retraso
        final delayedValue = ((controller.animationController.value * 1000) + delay) % 2000 / 2000;
        // Escalar de 0.4 a 1.0 para un efecto mejor
        final scale = 0.4 + (delayedValue * 0.6);
        
        return Opacity(
          opacity: (1.0 - delayedValue).clamp(0.0, 0.7),
          child: Container(
            width: size,
            height: 4,  // Altura fija para crear efecto wifi
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: AppColors.accent,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  // Animación de tarjeta RFID con ondas
  Widget _buildRfidAnimation() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenedor para la animación
          SizedBox(
            height: 260,
            width: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ondas de señal animadas (como las del WiFi)
                Positioned(
                  top: 10,
                  child: Column(
                    children: [
                      _buildWave(delay: 0, size: 100),
                      const SizedBox(height: 10),
                      _buildWave(delay: 600, size: 80),
                      const SizedBox(height: 10),
                      _buildWave(delay: 1200, size: 60),
                    ],
                  ),
                ),
                
                // Tarjeta RFID con efecto de llave
                Positioned(
                  bottom: 10,
                  child: Container(
                    height: 120,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Borde separador
                        Positioned(
                          top: 40,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            color: Colors.grey[800],
                          ),
                        ),
                        
                        // Llave RFID
                        Row(
                          children: [
                            // Cabeza de la llave
                            Container(
                              width: 60,
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 35,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Patrón de la llave
                            Expanded(
                              child: Center(
                                child: CustomPaint(
                                  size: const Size(100, 50),
                                  painter: KeyPatternPainter(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
  
  // Texto animado de carga
  Widget _buildLoadingText() {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        final dots = '.'.padRight(
          ((controller.animationController.value * 3) % 3 + 1).toInt(), 
          '.'
        );
        return Text(
          'Esperando tarjeta$dots',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título de bienvenida
            Text(
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
            const SizedBox(height: 32),
            
            // Foto del usuario
            Container(
              width: 250,
              height: 250,
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
                      borderRadius: BorderRadius.circular(125),
                      child: Image.network(
                        controller.userPhotoUrl.value,
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, error, _) => const CircleAvatar(
                          radius: 125,
                          child: Icon(Icons.person, size: 125),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 125,
                      backgroundColor: Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        size: 125,
                        color: AppColors.primary,
                      ),
                    )),
            ),
            const SizedBox(height: 24),
            
            // Nombre del usuario
            Obx(() => Text(
              controller.userName.value,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            )),
            const SizedBox(height: 16),
            
            // Tipo de membresía
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
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
            
            const SizedBox(height: 16),
            
            // Días restantes con icono
            Obx(() => Row(
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
            )),
          ],
        ),
      ),
    );
  }
}
