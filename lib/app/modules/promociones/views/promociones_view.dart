import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/modules/promociones/controllers/promociones_controller.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:gymads/core/utils/responsive_utils.dart';
import 'package:gymads/app/core/utils/snackbar_helper.dart';

class PromocionesView extends GetView<PromocionesController> {
  const PromocionesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Promociones'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              print('🔄 Actualizando lista manualmente...');
              await controller.fetchPromociones();
            },
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
            tooltip: 'Agregar promoción',
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          // Mostrar indicador de carga
          if (controller.isLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  SizedBox(height: 20),
                  Text(
                    'Cargando promociones...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Barra de búsqueda y filtros
              _buildSearchAndFilters(context),

              // Lista de promociones
              Expanded(
                child: _buildPromotionsList(context),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
          mobile: 16, smallPhone: 12, tablet: 24)),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.all(ResponsiveValues.getSpacing(context,
          mobile: 16, smallPhone: 12, tablet: 24)),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Buscar promoción...',
              hintStyle: const TextStyle(color: AppColors.textHint),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.containerBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) => controller.searchQuery.value = value,
          ),

          SizedBox(
              height: ResponsiveValues.getSpacing(context,
                  mobile: 12, smallPhone: 8, tablet: 16)),

          // Filtros
          Obx(() => Wrap(
                spacing: ResponsiveValues.getSpacing(context,
                    mobile: 8, smallPhone: 6, tablet: 12),
                children: [
                  FilterChip(
                    label: const Text('Solo activas',
                        style: TextStyle(color: AppColors.textPrimary)),
                    selected: controller.showOnlyActive.value,
                    onSelected: (selected) {
                      controller.showOnlyActive.value = selected;
                    },
                    backgroundColor: AppColors.containerBackground,
                    selectedColor: AppColors.accent.withOpacity(0.3),
                    checkmarkColor: AppColors.accent,
                  ),
                  FilterChip(
                    label: const Text('Solo válidas',
                        style: TextStyle(color: AppColors.textPrimary)),
                    selected: controller.showOnlyValid.value,
                    onSelected: (selected) {
                      controller.showOnlyValid.value = selected;
                    },
                    backgroundColor: AppColors.containerBackground,
                    selectedColor: AppColors.accent.withOpacity(0.3),
                    checkmarkColor: AppColors.accent,
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildPromotionsList(BuildContext context) {
    return Obx(() {
      final filteredPromociones = controller.filteredPromociones;

      if (filteredPromociones.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: ResponsiveValues.getIconSize(context,
                    mobile: 80, smallPhone: 60, tablet: 100),
                color: AppColors.textSecondary,
              ),
              SizedBox(
                  height: ResponsiveValues.getSpacing(context,
                      mobile: 20, smallPhone: 16, tablet: 24)),
              Text(
                controller.promociones.isEmpty
                    ? 'No hay promociones registradas'
                    : 'No hay resultados para tu búsqueda',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: filteredPromociones.length,
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index) {
          final promocion = filteredPromociones[index];
          return _buildPromotionCard(context, promocion);
        },
      );
    });
  }

  Widget _buildPromotionCard(BuildContext context, promocion) {
    return Card(
      color: AppColors.cardBackground,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveValues.getSpacing(context,
            mobile: 16, smallPhone: 12, tablet: 24),
        vertical: ResponsiveValues.getSpacing(context,
            mobile: 8, smallPhone: 6, tablet: 12),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
            mobile: 16, smallPhone: 12, tablet: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con nombre y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    promocion.name,
                    style: TextStyle(
                      fontSize: ResponsiveValues.getFontSize(context,
                          mobile: 18, smallPhone: 16, tablet: 20),
                      fontWeight: FontWeight.bold,
                      color: AppColors.titleColor,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de estado activo/inactivo
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: promocion.isActive
                            ? AppColors.success
                            : AppColors.disabled,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        promocion.isActive ? 'Activa' : 'Inactiva',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Indicador de validez actual
                    if (promocion.isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: promocion.isCurrentlyValid
                              ? AppColors.info
                              : AppColors.warning,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          promocion.isCurrentlyValid
                              ? 'Válida'
                              : 'Fuera de horario',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Descripción del descuento
            Text(
              promocion.discountDescription,
              style: TextStyle(
                fontSize: ResponsiveValues.getFontSize(context,
                    mobile: 16, smallPhone: 14, tablet: 18),
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),

            if (promocion.description != null) ...[
              const SizedBox(height: 8),
              Text(
                promocion.description!,
                style: TextStyle(
                  fontSize: ResponsiveValues.getFontSize(context,
                      mobile: 14, smallPhone: 12, tablet: 16),
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Información adicional
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                // Aplica a
                if (promocion.appliesTo.isNotEmpty)
                  _buildInfoChip(
                    context,
                    Icons.label_outline,
                    'Aplica a: ${promocion.appliesTo.join(", ")}',
                  ),

                // Día de la semana
                if (promocion.dayOfWeekName != null)
                  _buildInfoChip(
                    context,
                    Icons.calendar_today,
                    promocion.dayOfWeekName!,
                  ),

                // Horario
                if (promocion.timeStart != null && promocion.timeEnd != null)
                  _buildInfoChip(
                    context,
                    Icons.access_time,
                    '${promocion.timeStart} - ${promocion.timeEnd}',
                  ),

                // Máximo de usos
                if (promocion.maxUses != null)
                  _buildInfoChip(
                    context,
                    Icons.confirmation_number,
                    '${promocion.currentUses}/${promocion.maxUses} usos',
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ResponsiveValues.isTablet(context)) ...[
                  // Versión completa para tablet/desktop
                  TextButton.icon(
                    onPressed: () => _showEditDialog(context, promocion),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.info,
                    ),
                  ),

                  const SizedBox(width: 8),

                  TextButton.icon(
                    onPressed: () => controller.togglePromotionStatus(
                        promocion.id!, !promocion.isActive),
                    icon: Icon(
                      promocion.isActive ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(promocion.isActive ? 'Desactivar' : 'Activar'),
                    style: TextButton.styleFrom(
                      foregroundColor: promocion.isActive
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),

                  const SizedBox(width: 8),

                  TextButton.icon(
                    onPressed: () =>
                        _showDeleteConfirmation(context, promocion),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Eliminar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ] else ...[
                  // Versión compacta para móvil (solo iconos)
                  IconButton(
                    onPressed: () => _showEditDialog(context, promocion),
                    icon: const Icon(Icons.edit, size: 20),
                    color: AppColors.info,
                    tooltip: 'Editar',
                  ),

                  IconButton(
                    onPressed: () => controller.togglePromotionStatus(
                        promocion.id!, !promocion.isActive),
                    icon: Icon(
                      promocion.isActive ? Icons.pause : Icons.play_arrow,
                      size: 20,
                    ),
                    color: promocion.isActive
                        ? AppColors.warning
                        : AppColors.success,
                    tooltip: promocion.isActive ? 'Desactivar' : 'Activar',
                  ),

                  IconButton(
                    onPressed: () =>
                        _showDeleteConfirmation(context, promocion),
                    icon: const Icon(Icons.delete, size: 20),
                    color: AppColors.error,
                    tooltip: 'Eliminar',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: ResponsiveValues.getIconSize(context,
              mobile: 16, smallPhone: 14, tablet: 18),
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveValues.getFontSize(context,
                mobile: 12, smallPhone: 10, tablet: 14),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    // Limpiar formulario y resetear estado
    controller.clearForm();

    // Pequeño delay para asegurar que el estado se actualice
    Future.delayed(const Duration(milliseconds: 50), () {
      _showPromotionDialog(context, isEditing: false);
    });
  }

  void _showEditDialog(BuildContext context, promocion) {
    controller.setupFormForEdit(promocion);
    _showPromotionDialog(context, isEditing: true, promocion: promocion);
  }

  void _showPromotionDialog(BuildContext context,
      {required bool isEditing, promocion}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth:
                ResponsiveValues.isTablet(context) ? 600 : double.infinity,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              Text(
                isEditing ? 'Editar Promoción' : 'Nueva Promoción',
                style: TextStyle(
                  fontSize: ResponsiveValues.getFontSize(context,
                      mobile: 20, smallPhone: 18, tablet: 24),
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),

              const SizedBox(height: 20),

              // Formulario (implementar en un widget separado)
              Expanded(
                child: SingleChildScrollView(
                  child: _buildPromotionForm(context),
                ),
              ),

              const SizedBox(height: 20),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () =>
                        _savePromotion(context, isEditing, promocion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isEditing ? 'Actualizar' : 'Crear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nombre
        TextFormField(
          controller: controller.nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la promoción',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        // Descripción
        TextFormField(
          controller: controller.descripcionController,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),

        const SizedBox(height: 16),

        // Tipo de descuento
        Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedDiscountType.value,
              decoration: const InputDecoration(
                labelText: 'Tipo de descuento',
                border: OutlineInputBorder(),
              ),
              items: controller.discountTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(controller.getDiscountTypeDescription(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectedDiscountType.value = value;
                }
              },
            )),

        const SizedBox(height: 16),

        // Valor del descuento
        TextFormField(
          controller: controller.discountValueController,
          decoration: InputDecoration(
            labelText: controller.selectedDiscountType.value == 'percentage'
                ? 'Porcentaje (0-100)'
                : 'Cantidad en pesos',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 16),

        // Aplica a (checkboxes)
        const Text('Aplica a:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Obx(() => Wrap(
              children: controller.appliesToOptions.map((option) {
                return CheckboxListTile(
                  title: Text(option),
                  value: controller.selectedAppliesTo.contains(option),
                  onChanged: (checked) {
                    if (checked == true) {
                      controller.selectedAppliesTo.add(option);
                    } else {
                      controller.selectedAppliesTo.remove(option);
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                );
              }).toList(),
            )),

        const SizedBox(height: 16),

        // Día de la semana
        Obx(() => DropdownButtonFormField<int?>(
              value: controller.selectedDayOfWeek.value,
              decoration: const InputDecoration(
                labelText: 'Día específico (opcional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos los días'),
                ),
                ...controller.daysOfWeek.asMap().entries.map((entry) {
                  return DropdownMenuItem<int?>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }),
              ],
              onChanged: (value) {
                controller.selectedDayOfWeek.value = value;
              },
            )),

        const SizedBox(height: 16),

        // Estado activo
        Obx(() => SwitchListTile(
              title: const Text('Promoción activa'),
              value: controller.isActiveForm.value,
              onChanged: (value) {
                controller.isActiveForm.value = value;
              },
            )),
      ],
    );
  }

  void _savePromotion(BuildContext context, bool isEditing, promocion) async {
    if (!controller.validateForm()) return;

    try {
      final promotionModel = controller.createPromotionFromForm();

      bool success;
      if (isEditing) {
        print('🔄 Editando promoción...');
        success =
            await controller.updatePromocion(promocion.id!, promotionModel);
      } else {
        print('🔄 Creando nueva promoción...');
        success = await controller.createPromocion(promotionModel);
      }

      if (success) {
        print('✅ Operación exitosa, cerrando diálogo...');
        // Cerrar el diálogo de forma segura
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error en _savePromotion: $e');
      SnackbarHelper.error('Error', 'Error inesperado: $e');
    }
  }

  void _showDeleteConfirmation(BuildContext context, promocion) {
    Get.defaultDialog(
      title: 'Eliminar Promoción',
      middleText: '¿Estás seguro de que deseas eliminar "${promocion.name}"?',
      textConfirm: 'Eliminar',
      textCancel: 'Cancelar',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        print('🔄 Iniciando eliminación de promoción...');

        // Cerrar el diálogo de confirmación primero
        Navigator.of(context).pop();

        // Luego ejecutar la eliminación
        final success = await controller.deletePromocion(promocion.id!);

        if (success) {
          print('✅ Promoción eliminada exitosamente');
        } else {
          print('❌ Error al eliminar promoción');
        }
      },
    );
  }
}
