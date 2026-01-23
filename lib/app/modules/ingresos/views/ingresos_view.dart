import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:gymads/core/utils/responsive_utils.dart';
import '../controllers/ingresos_controller.dart';
import '../../../core/utils/snackbar_helper.dart';

class IngresosView extends GetView<IngresosController> {
  const IngresosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Ingresos'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshData(),
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context),
            tooltip: 'Filtrar por fechas',
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  SizedBox(height: 20),
                  Text(
                    'Cargando ingresos...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
                  mobile: 16, smallPhone: 12, tablet: 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjetas de estadísticas
                  _buildStatsCards(context),

                  SizedBox(
                      height: ResponsiveValues.getSpacing(context,
                          mobile: 20, smallPhone: 16, tablet: 24)),

                  // Lista de transacciones recientes
                  _buildRecentTransactions(context),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Obx(() {
      final stats = controller.estadisticas.value;

      return ResponsiveValues.isTablet(context)
          ? Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                  context,
                  'Total Ingresos',
                  controller.formatCurrency(stats.totalIngresos),
                  Icons.attach_money,
                  AppColors.success,
                )),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildStatCard(
                  context,
                  'Transacciones',
                  stats.totalTransacciones.toString(),
                  Icons.receipt,
                  AppColors.info,
                )),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildStatCard(
                  context,
                  'Promedio',
                  controller.formatCurrency(stats.promedioTransaccion),
                  Icons.trending_up,
                  AppColors.accent,
                )),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildStatCard(
                  context,
                  'Nuevos Registros',
                  stats.registrosNuevos.toString(),
                  Icons.person_add,
                  AppColors.warning,
                )),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                      context,
                      'Total Ingresos',
                      controller.formatCurrency(stats.totalIngresos),
                      Icons.attach_money,
                      AppColors.success,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                      context,
                      'Transacciones',
                      stats.totalTransacciones.toString(),
                      Icons.receipt,
                      AppColors.info,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                      context,
                      'Promedio',
                      controller.formatCurrency(stats.promedioTransaccion),
                      Icons.trending_up,
                      AppColors.accent,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                      context,
                      'Nuevos Registros',
                      stats.registrosNuevos.toString(),
                      Icons.person_add,
                      AppColors.warning,
                    )),
                  ],
                ),
              ],
            );
    });
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: AppColors.cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
            mobile: 16, smallPhone: 12, tablet: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: ResponsiveValues.getIconSize(context,
                      mobile: 24, smallPhone: 20, tablet: 28),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    size: 16,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(
                height: ResponsiveValues.getSpacing(context,
                    mobile: 8, smallPhone: 6, tablet: 12)),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveValues.getFontSize(context,
                    mobile: 12, smallPhone: 10, tablet: 14),
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveValues.getFontSize(context,
                    mobile: 18, smallPhone: 16, tablet: 22),
                fontWeight: FontWeight.bold,
                color: AppColors.titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
            mobile: 16, smallPhone: 12, tablet: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Transacciones Recientes',
                    style: TextStyle(
                      fontSize: ResponsiveValues.getFontSize(context,
                          mobile: 18, smallPhone: 16, tablet: 20),
                      fontWeight: FontWeight.bold,
                      color: AppColors.titleColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAllTransactionsDialog(context),
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            SizedBox(
                height: ResponsiveValues.getSpacing(context,
                    mobile: 16, smallPhone: 12, tablet: 20)),
            Obx(() {
              if (!controller.tieneIngresos) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No hay transacciones registradas',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: controller.ingresos.take(5).map((ingreso) {
                  return _buildTransactionTile(context, ingreso);
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, ingreso) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
          mobile: 12, smallPhone: 10, tablet: 16)),
      decoration: BoxDecoration(
        color: AppColors.containerBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.disabled.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono del concepto
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: controller
                  .getColorForConcepto(ingreso.concepto)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForConcepto(ingreso.concepto),
              color: controller.getColorForConcepto(ingreso.concepto),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Información de la transacción
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingreso.clienteNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ingreso.conceptoDescripcion,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: controller
                            .getColorForMetodoPago(ingreso.metodoPago)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ingreso.metodoPagoDescripcion,
                        style: TextStyle(
                          fontSize: 10,
                          color: controller
                              .getColorForMetodoPago(ingreso.metodoPago),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Monto y fecha
          SizedBox(
            width: ResponsiveValues.isTablet(context) ? 120 : 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  controller.formatCurrency(ingreso.montoFinal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    fontSize: ResponsiveValues.getFontSize(context,
                        mobile: 14, smallPhone: 12, tablet: 16),
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(ingreso.fecha),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      // Asegurarnos de que las fechas sean válidas
      final initialStart = controller.fechaInicio.value ?? firstDayOfMonth;
      final initialEnd = controller.fechaFin.value ?? now;

      // Validar que las fechas no excedan los límites
      final validStart =
          initialStart.isAfter(now) ? firstDayOfMonth : initialStart;
      final validEnd = initialEnd.isAfter(now) ? now : initialEnd;

      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now, // Usar la fecha actual exacta
        initialDateRange: DateTimeRange(
          start: validStart,
          end: validEnd,
        ),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.accent, // Color principal (naranja)
                onPrimary: Colors.white, // Texto sobre el color principal
                surface: AppColors.cardBackground, // Fondo del diálogo
                onSurface: AppColors.textPrimary, // Texto sobre el fondo
              ),
              dialogBackgroundColor: AppColors.cardBackground,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent, // Color de los botones
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        controller.setFechasPersonalizadas(picked.start, picked.end);
      }
    } catch (e) {
      print('❌ Error al mostrar selector de fechas: $e');
      SnackbarHelper.error(
        'Error',
        'No se pudo abrir el selector de fechas',
      );
    }
  }

  IconData _getIconForConcepto(String concepto) {
    switch (concepto) {
      case 'nuevo_registro':
        return Icons.person_add;
      case 'renovacion':
        return Icons.refresh;
      case 'registro':
        return Icons.how_to_reg;
      default:
        return Icons.receipt;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAllTransactionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveValues.getSpacing(context,
                mobile: 16, smallPhone: 12, tablet: 40),
            vertical: ResponsiveValues.getSpacing(context,
                mobile: 24, smallPhone: 16, tablet: 40),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth:
                  ResponsiveValues.isTablet(context) ? 800 : double.infinity,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
                      mobile: 16, smallPhone: 12, tablet: 20)),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Todas las Transacciones',
                          style: TextStyle(
                            fontSize: ResponsiveValues.getFontSize(context,
                                mobile: 18, smallPhone: 16, tablet: 22),
                            fontWeight: FontWeight.bold,
                            color: AppColors.titleColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),

                // Lista de transacciones
                Flexible(
                  child: Obx(() {
                    if (!controller.tieneIngresos) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay transacciones registradas',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.all(ResponsiveValues.getSpacing(
                          context,
                          mobile: 16,
                          smallPhone: 12,
                          tablet: 20)),
                      itemCount: controller.ingresos.length,
                      itemBuilder: (context, index) {
                        final ingreso = controller.ingresos[index];
                        return _buildTransactionTile(context, ingreso);
                      },
                    );
                  }),
                ),

                // Footer con total
                Container(
                  padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
                      mobile: 16, smallPhone: 12, tablet: 20)),
                  decoration: BoxDecoration(
                    color: AppColors.containerBackground,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() => Text(
                            '${controller.ingresos.length} transacciones',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          )),
                      Obx(() => Text(
                            'Total: ${controller.formatCurrency(controller.totalIngresosActual)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                              fontSize: ResponsiveValues.getFontSize(context,
                                  mobile: 16, smallPhone: 14, tablet: 18),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
