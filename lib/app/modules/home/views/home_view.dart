import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/home_controller.dart';
import '../widgets/button_menu_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'ADS\nFITNESS',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.titleColor,
                  fontSize: 38,
                  letterSpacing: 5,
                ),
              ),
            ),
          ],
        ),

        systemOverlayStyle:
            context.theme.platform == TargetPlatform.iOS
                ? const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                )
                : const SystemUiOverlayStyle(
                  systemNavigationBarColor: Colors.black,
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                ),

        centerTitle: false,
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        toolbarHeight: 150,
      ),
      body: Container(
        // Agregando SafeArea para evitar problemas con el notch o la barra de navegación
        color: AppColors.backgroundColor,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Usando LayoutBuilder para adaptar el diseño al espacio disponible
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                // Agregando scroll para evitar overflow
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Usar tamaño mínimo necesario
                    children: [
                      // Encabezado con imagen de fondo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Bienvenido Admin',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('Abrir Administrativo'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Menú de opciones
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        // Cambiando el GridView por un envoltorio más flexible
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          padding: const EdgeInsets.all(8),
                          // Importante: establecer shrinkWrap a true para evitar problemas de altura
                          shrinkWrap: true,
                          // Desactivar el scroll propio del GridView ya que usamos SingleChildScrollView
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // Opción de Check-ins
                            ButtonMenuWidget(
                              icon: Icons.qr_code_scanner,
                              label: 'Checador',
                              description: 'Control de acceso',
                              color: Colors.cyan.shade300,
                              onTap: controller.goToCheckIns,
                            ),
                            
                            // Opción de Check-in con RFID
                            ButtonMenuWidget(
                              icon: Icons.contactless,
                              label: 'RFID',
                              description: 'Acceso con tarjeta',
                              color: Colors.indigo.shade300,
                              onTap: controller.goToRfidCheckIn,
                            ),

                            // Opción de Inventario
                            ButtonMenuWidget(
                              icon: Icons.inventory,
                              label: 'Inventario',
                              description: 'Mis productos',
                              color: Colors.green.shade300,
                              onTap: controller.goToInventario,
                            ),
                            
                            // Opción de Registrar Pago
                            ButtonMenuWidget(
                              icon: Icons.attach_money,
                              label: 'Ingresos',
                              description: 'Registro de pago',
                              color: Colors.amber.shade300,
                              onTap: controller.goToPaymentRegistration,
                            ),
                            
                            // Opción de Clientes
                            ButtonMenuWidget(
                              icon: Icons.person_add,
                              label: 'Clientes',
                              description: 'Gestión de clientes',
                              color: Colors.green.shade300,
                              onTap: controller.goToClientes,
                            ),

                            // Espacio para futuras opciones
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
