import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:gymads/core/utils/responsive_utils.dart';
import '../controllers/ingresos_controller.dart';

class IngresosView extends GetView<IngresosController> {
  const IngresosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos'),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
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
                // Filtros y período
                _buildFilters(context),
                
                SizedBox(height: ResponsiveValues.getSpacing(context,
                    mobile: 20, smallPhone: 16, tablet: 24)),
                
                // Tarjetas de estadísticas
                _buildStatsCards(context),
                
                SizedBox(height: ResponsiveValues.getSpacing(context,
                    mobile: 20, smallPhone: 16, tablet: 24)),
                
                // Gráfica de ingresos
                _buildIncomeChart(context),
                
                SizedBox(height: ResponsiveValues.getSpacing(context,
                    mobile: 20, smallPhone: 16, tablet: 24)),
                
                // Lista de transacciones recientes
                _buildRecentTransactions(context),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
            mobile: 16, smallPhone: 12, tablet: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: TextStyle(
                fontSize: ResponsiveValues.getFontSize(context,
                    mobile: 18, smallPhone: 16, tablet: 20),
                fontWeight: FontWeight.bold,
                color: AppColors.titleColor,
              ),
            ),
            
            SizedBox(height: ResponsiveValues.getSpacing(context,
                mobile: 16, smallPhone: 12, tablet: 20)),
            
            // Selector de período
            Obx(() => Wrap(
                  spacing: ResponsiveValues.getSpacing(context,
                      mobile: 8, smallPhone: 6, tablet: 12),
                  children: controller.periodos.map((periodo) {
                    final isSelected = controller.selectedPeriodo.value == periodo;
                    return FilterChip(
                      label: Text(periodo.capitalize!),
                      selected: isSelected,
                      onSelected: (selected) {
                        try {
                          if (selected) controller.changePeriodo(periodo);
                        } catch (e) {
                          print('❌ Error al cambiar período: $e');
                          Get.snackbar(
                            'Error',
                            'Error al cambiar período',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                      selectedColor: AppColors.accent.withOpacity(0.3),
                      checkmarkColor: AppColors.accent,
                    );
                  }).toList(),
                )),
            
            SizedBox(height: ResponsiveValues.getSpacing(context,
                mobile: 12, smallPhone: 8, tablet: 16)),
            
            // Filtros adicionales
            if (ResponsiveValues.isTablet(context))
              Row(
                children: [
                  Expanded(child: _buildConceptoFilter()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetodoPagoFilter()),
                ],
              )
            else
              Column(
                children: [
                  _buildConceptoFilter(),
                  const SizedBox(height: 12),
                  _buildMetodoPagoFilter(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptoFilter() {
    return Obx(() => DropdownButtonFormField<String?>(
          value: controller.selectedConcepto.value,
          decoration: const InputDecoration(
            labelText: 'Filtrar por concepto',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos los conceptos'),
            ),
            ...controller.conceptos.map((concepto) {
              return DropdownMenuItem<String?>(
                value: concepto,
                child: Text(_getConceptoDisplayName(concepto)),
              );
            }),
          ],
          onChanged: (value) {
            try {
              controller.changeConcepto(value);
            } catch (e) {
              print('❌ Error en filtro de concepto: $e');
            }
          },
        ));
  }

  Widget _buildMetodoPagoFilter() {
    return Obx(() => DropdownButtonFormField<String?>(
          value: controller.selectedMetodoPago.value,
          decoration: const InputDecoration(
            labelText: 'Filtrar por método de pago',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos los métodos'),
            ),
            ...controller.metodosPago.map((metodo) {
              return DropdownMenuItem<String?>(
                value: metodo,
                child: Text(metodo.capitalize!),
              );
            }),
          ],
          onChanged: (value) {
            try {
              controller.changeMetodoPago(value);
            } catch (e) {
              print('❌ Error en filtro de método de pago: $e');
            }
          },
        ));
  }

  Widget _buildStatsCards(BuildContext context) {
    return Obx(() {
      final stats = controller.estadisticas.value;
      
      return ResponsiveValues.isTablet(context)
          ? Row(
              children: [
                Expanded(child: _buildStatCard(
                  context,
                  'Total Ingresos',
                  controller.formatCurrency(stats.totalIngresos),
                  Icons.attach_money,
                  AppColors.success,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(
                  context,
                  'Transacciones',
                  stats.totalTransacciones.toString(),
                  Icons.receipt,
                  AppColors.info,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(
                  context,
                  'Promedio',
                  controller.formatCurrency(stats.promedioTransaccion),
                  Icons.trending_up,
                  AppColors.accent,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(
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
                    Expanded(child: _buildStatCard(
                      context,
                      'Total Ingresos',
                      controller.formatCurrency(stats.totalIngresos),
                      Icons.attach_money,
                      AppColors.success,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(
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
                    Expanded(child: _buildStatCard(
                      context,
                      'Promedio',
                      controller.formatCurrency(stats.promedioTransaccion),
                      Icons.trending_up,
                      AppColors.accent,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            
            SizedBox(height: ResponsiveValues.getSpacing(context,
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

  Widget _buildIncomeChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
            mobile: 16, smallPhone: 12, tablet: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gráfica de Ingresos',
                  style: TextStyle(
                    fontSize: ResponsiveValues.getFontSize(context,
                        mobile: 18, smallPhone: 16, tablet: 20),
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleColor,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Selector de tipo de gráfica
                _buildChartTypeSelector(),
              ],
            ),
            
            SizedBox(height: ResponsiveValues.getSpacing(context,
                mobile: 20, smallPhone: 16, tablet: 24)),
            
            Obx(() {
              if (!controller.tieneDatosGrafica) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay datos para mostrar en la gráfica',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Seleccionar el tipo de gráfica a mostrar
              switch (controller.selectedChartType.value) {
                case 'barras':
                  return _buildBarChart(context);
                case 'pastel':
                  return _buildPieChart(context);
                case 'lineas':
                  return _buildLineChart(context);
                default:
                  return _buildBarChart(context);
              }
            }),
          ],
        ),
      ),
    );
  }

  // Gráfica de barras
  Widget _buildBarChart(BuildContext context) {
    final datos = controller.datosGrafica;
    if (datos.isEmpty) {
      return const SizedBox(height: 200);
    }

    final maxValue = datos.values.reduce((a, b) => a > b ? a : b);
    final entries = datos.entries.toList();

    // Lista de colores para las barras
    final List<Color> barColors = [
      Colors.orange.shade600,
      Colors.deepOrange.shade500,
      Colors.orange.shade700,
      Colors.amber.shade600,
      Colors.deepOrange.shade600,
      Colors.orange.shade500,
      Colors.amber.shade700,
      Colors.deepOrange.shade400,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gráfica de barras
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final height = maxValue > 0 ? (entry.value / maxValue) * 180 : 0;
              final colorIndex = index % barColors.length;
              
              return Container(
                width: 60,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Valor
                    Text(
                      controller.formatCurrency(entry.value),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Barra
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 30,
                      height: height.toDouble(),
                      decoration: BoxDecoration(
                        color: barColors[colorIndex],
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            barColors[colorIndex],
                            barColors[colorIndex].withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Etiqueta
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Leyenda
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Total: ${controller.formatCurrency(controller.totalIngresosActual)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // Gráfica de pastel
  Widget _buildPieChart(BuildContext context) {
    final datos = controller.getDatosPastel();
    if (datos.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text("No hay datos para mostrar")));
    }

    final entries = datos.entries.toList();
    final total = controller.getTotalPastel();
    final colores = controller.getColoresPastel();
    
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          // Gráfica de pastel
          SizedBox(
            height: 200,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Segmentos del pastel
                  ...List.generate(entries.length, (index) {
                    final entry = entries[index];
                    final percentage = entry.value / total;
                    final colorIndex = index % colores.length;
                    
                    // Ángulo de inicio y fin del segmento
                    final startAngle = index > 0 
                        ? entries.sublist(0, index).fold(0.0, (prev, e) => prev + (e.value / total) * 2 * pi) 
                        : 0.0;
                    
                    return CustomPaint(
                      size: const Size(200, 200),
                      painter: PieChartPainter(
                        color: colores[colorIndex],
                        startAngle: startAngle,
                        sweepAngle: percentage * 2 * pi,
                        percentage: percentage,
                      ),
                    );
                  }),
                  
                  // Círculo interior
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        controller.formatCurrency(total),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Leyenda
          const SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: List.generate(entries.length, (index) {
                  final entry = entries[index];
                  final colorIndex = index % colores.length;
                  final percentage = ((entry.value / total) * 100).toStringAsFixed(1);
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: colores[colorIndex],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_getConceptoDisplayName(entry.key)} (${percentage}%)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gráfica de líneas
  Widget _buildLineChart(BuildContext context) {
    final datos = controller.getDatosLinea();
    if (datos.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text("No hay datos para mostrar")));
    }

    final entries = datos.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key)); // Ordenar por fecha/clave
    
    final maxValue = datos.values.reduce((a, b) => a > b ? a : b);
    final dataPoints = entries.map((e) => e.value).toList();
    final labels = entries.map((e) => e.key).toList();
    
    return SizedBox(
      height: 250,
      child: Column(
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Total: ${controller.formatCurrency(controller.totalIngresosActual)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          
          // Gráfica de líneas
          Expanded(
            child: CustomPaint(
              size: Size(double.infinity, 200),
              painter: LineChartPainter(
                dataPoints: dataPoints,
                labels: labels,
                maxValue: maxValue,
                lineColor: Colors.orange.shade600,
              ),
            ),
          ),
          
          // Etiquetas del eje X
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final width = MediaQuery.of(context).size.width / (entries.length > 6 ? 6 : entries.length);
                return SizedBox(
                  width: width,
                  child: Center(
                    child: Text(
                      entries[index].key,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Selector de tipo de gráfica
  Widget _buildChartTypeSelector() {
    return Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Barras'),
                selected: controller.selectedChartType.value == 'barras',
                onSelected: (selected) {
                  if (selected) controller.changeChartType('barras');
                },
                selectedColor: Colors.orange.shade100,
                labelStyle: TextStyle(
                  color: controller.selectedChartType.value == 'barras'
                      ? Colors.orange.shade700
                      : AppColors.textSecondary,
                  fontWeight: controller.selectedChartType.value == 'barras'
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Pastel'),
                selected: controller.selectedChartType.value == 'pastel',
                onSelected: (selected) {
                  if (selected) controller.changeChartType('pastel');
                },
                selectedColor: Colors.blue.shade100,
                labelStyle: TextStyle(
                  color: controller.selectedChartType.value == 'pastel'
                      ? Colors.blue.shade700
                      : AppColors.textSecondary,
                  fontWeight: controller.selectedChartType.value == 'pastel'
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Líneas'),
                selected: controller.selectedChartType.value == 'lineas',
                onSelected: (selected) {
                  if (selected) controller.changeChartType('lineas');
                },
                selectedColor: Colors.green.shade100,
                labelStyle: TextStyle(
                  color: controller.selectedChartType.value == 'lineas'
                      ? Colors.green.shade700
                      : AppColors.textSecondary,
                  fontWeight: controller.selectedChartType.value == 'lineas'
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildRecentTransactions(BuildContext context) {
    return Card(
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
                  onPressed: () {
                    // TODO: Navegar a vista completa de transacciones
                  },
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            
            SizedBox(height: ResponsiveValues.getSpacing(context,
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
              color: controller.getColorForConcepto(ingreso.concepto).withOpacity(0.2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: controller.getColorForMetodoPago(ingreso.metodoPago).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ingreso.metodoPagoDescripcion,
                        style: TextStyle(
                          fontSize: 10,
                          color: controller.getColorForMetodoPago(ingreso.metodoPago),
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
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: controller.fechaInicio.value ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
        end: controller.fechaFin.value ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      controller.setFechasPersonalizadas(picked.start, picked.end);
    }
  }

  String _getConceptoDisplayName(String concepto) {
    switch (concepto) {
      case 'nuevo_registro':
        return 'Nuevo Registro';
      case 'renovacion':
        return 'Renovación';
      case 'registro':
        return 'Solo Registro';
      default:
        return concepto;
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
}

// Custom painters para gráficas
class PieChartPainter extends CustomPainter {
  final Color color;
  final double startAngle;
  final double sweepAngle;
  final double percentage;

  PieChartPainter({
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
    required this.percentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Dibujar segmento del pastel
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      paint,
    );
    
    // Dibujar borde blanco
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) => 
      color != oldDelegate.color || 
      startAngle != oldDelegate.startAngle || 
      sweepAngle != oldDelegate.sweepAngle ||
      percentage != oldDelegate.percentage;
}

class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;
  final double maxValue;
  final Color lineColor;

  LineChartPainter({
    required this.dataPoints,
    required this.labels,
    required this.maxValue,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty || maxValue <= 0) return;
    
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    
    // Dibujar líneas de guía horizontales
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Dibujar 5 líneas de guía horizontales
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (size.height * i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    final path = Path();
    
    // Calculamos el ancho de cada punto en el eje X
    final pointWidth = size.width / (dataPoints.length - 1 > 0 ? dataPoints.length - 1 : 1);
    
    // Iniciamos el path
    bool isFirstPoint = true;
    List<Offset> points = [];
    
    for (int i = 0; i < dataPoints.length; i++) {
      final value = dataPoints[i];
      final x = i * pointWidth;
      final y = size.height - (value / maxValue * size.height * 0.9);
      final point = Offset(x, y);
      
      points.add(point);
      
      if (isFirstPoint) {
        path.moveTo(x, y);
        isFirstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }
    
    // Dibujar la línea
    canvas.drawPath(path, paint);
    
    // Dibujar los puntos
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
    }
    
    // Dibujar área bajo la curva
    if (points.isNotEmpty) {
      final areaPaint = Paint()
        ..color = lineColor.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      
      final areaPath = Path()..addPath(path, Offset.zero);
      areaPath.lineTo(points.last.dx, size.height);
      areaPath.lineTo(points.first.dx, size.height);
      areaPath.lineTo(points.first.dx, points.first.dy);
      
      canvas.drawPath(areaPath, areaPaint);
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) => 
      dataPoints != oldDelegate.dataPoints || 
      labels != oldDelegate.labels || 
      maxValue != oldDelegate.maxValue ||
      lineColor != oldDelegate.lineColor;
}
