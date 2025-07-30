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
    // Determinar si es una tableta basado en el ancho de la pantalla
    final bool isTabletSize = MediaQuery.of(context).size.width > 600;
    
    // Determinar si es un teléfono pequeño
    final bool isSmallPhone = MediaQuery.of(context).size.width < 360;
    
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
                  fontSize: isSmallPhone ? 32 : 38,
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
        toolbarHeight: isTabletSize ? 170 : 150,
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Adaptamos el diseño al espacio disponible
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Encabezado con imagen de fondo
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallPhone ? 12 : 16,
                        vertical: isSmallPhone ? 14 : 18,
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: isSmallPhone ? 12 : 16,
                        vertical: 0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Bienvenido Admin',
                            style: TextStyle(
                              fontSize: isSmallPhone ? 20 : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
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
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallPhone ? 12 : 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
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
                      padding: EdgeInsets.all(isSmallPhone ? 12 : 16),
                      margin: EdgeInsets.fromLTRB(
                        isSmallPhone ? 12 : 16, 
                        0, 
                        isSmallPhone ? 12 : 16, 
                        16
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      // GridView adaptativo según el tamaño de pantalla
                      child: GridView.count(
                        crossAxisCount: isTabletSize ? 3 : 2,
                        mainAxisSpacing: isSmallPhone ? 12 : 16,
                        crossAxisSpacing: isSmallPhone ? 12 : 16,
                        padding: EdgeInsets.all(isSmallPhone ? 6 : 8),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
