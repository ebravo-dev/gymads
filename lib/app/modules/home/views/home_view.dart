import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../data/services/branding_service.dart';
import '../../../data/services/tenant_context_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';
import '../widgets/button_menu_widget.dart';
import '../widgets/background_welcome_dialog.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Utilizamos las funciones de valores responsivos
    final bool isTabletSize = MediaQuery.of(context).size.width > 600;
    final bool isSmallPhone = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        systemOverlayStyle: context.theme.platform == TargetPlatform.iOS
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              )
            : const SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.black,
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
        centerTitle: true,
        toolbarHeight: isTabletSize ? 170 : 150,
        title: Obx(() {
          final gymName = BrandingService.to.gymTitle.value.toUpperCase();
          final brandColor = BrandingService.to.brandColor;
          final baseFontSize = ResponsiveValues.getFontSize(context,
              mobile: 34, smallPhone: 26, tablet: 40);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  gymName,
                  maxLines: 1,
                  style: BrandingService.to.getFontStyle(
                    fontSize: baseFontSize *
                        BrandingService.fontSizeMultiplier(
                            BrandingService.to.brandFontName.value),
                    color: brandColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Powered by GYMONE',
                style: TextStyle(
                  fontSize: ResponsiveValues.getFontSize(context,
                      mobile: 10, smallPhone: 9, tablet: 12),
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 2,
                ),
              ),
            ],
          );
        }),
        // Botón de configuración y logout
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              onPressed: () => Get.toNamed(Routes.CONFIGURACION),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
                horizontal: ResponsiveValues.getSpacing(context,
                    mobile: 8, smallPhone: 6, tablet: 12),
                vertical: 0),
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
                        horizontal: ResponsiveValues.getSpacing(context,
                            mobile: 16, smallPhone: 12, tablet: 24),
                        vertical: ResponsiveValues.getSpacing(context,
                            mobile: 18, smallPhone: 14, tablet: 24),
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: ResponsiveValues.getSpacing(context,
                            mobile: 16, smallPhone: 12, tablet: 24),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.getGreeting(),
                            style: TextStyle(
                              fontSize: ResponsiveValues.getFontSize(context,
                                  mobile: 18, smallPhone: 16, tablet: 20),
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                              shadows: const [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bienvenido ${(TenantContextService.to.firstName ?? TenantContextService.to.displayName ?? "").split(" ").first}',
                            style: TextStyle(
                              fontSize: ResponsiveValues.getFontSize(context,
                                  mobile: 26, smallPhone: 24, tablet: 30),
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
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Menú de opciones
                    Container(
                      padding: EdgeInsets.all(isSmallPhone ? 12 : 16),
                      margin: EdgeInsets.fromLTRB(isSmallPhone ? 12 : 16, 0,
                          isSmallPhone ? 12 : 16, 16),
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
                        mainAxisSpacing: ResponsiveValues.getSpacing(context,
                            mobile: 16, smallPhone: 12, tablet: 24),
                        crossAxisSpacing: ResponsiveValues.getSpacing(context,
                            mobile: 16, smallPhone: 12, tablet: 24),
                        padding: EdgeInsets.all(ResponsiveValues.getSpacing(
                            context,
                            mobile: 8,
                            smallPhone: 6,
                            tablet: 12)),
                        // Establecer childAspectRatio para controlar la altura
                        childAspectRatio: isSmallPhone ? 0.85 : 0.95,
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

                          // Opción de Inventario
                          ButtonMenuWidget(
                            icon: Icons.inventory,
                            label: 'Inventario',
                            description: 'Mis productos',
                            color: Colors.green.shade300,
                            onTap: controller.goToInventario,
                          ),

                          // Opción de Punto de Venta
                          ButtonMenuWidget(
                            icon: Icons.point_of_sale,
                            label: 'Vender',
                            description: 'Ventas y facturación',
                            color: Colors.blue.shade300,
                            onTap: controller.goToPointOfSale,
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

                          // Opción de Membresías
                          ButtonMenuWidget(
                            icon: Icons.card_membership,
                            label: 'Membresías',
                            description: 'Tipos de membresía',
                            color: Colors.purple.shade300,
                            onTap: controller.goToMembresias,
                          ),

                          // Opción de Promociones
                          ButtonMenuWidget(
                            icon: Icons.local_offer,
                            label: 'Promociones',
                            description: 'Descuentos y ofertas',
                            color: Colors.orange.shade300,
                            onTap: controller.goToPromociones,
                          ),

                          // Opción de Entradas y Salidas
                          ButtonMenuWidget(
                            icon: Icons.assessment,
                            label: 'Entradas',
                            description: 'Historial de accesos',
                            color: Colors.teal.shade300,
                            onTap: controller.goToAccessLogs,
                          ),
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
      // Diálogo de bienvenida RFID en segundo plano
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const BackgroundWelcomeDialog(),
    );
  }
}
