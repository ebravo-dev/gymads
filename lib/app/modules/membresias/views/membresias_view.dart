import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:gymads/core/utils/responsive_utils.dart';
import '../controllers/membresias_controller.dart';
import '../widgets/membership_form_dialog.dart';
import '../widgets/membership_card.dart';

class MembresiasView extends GetView<MembresiasController> {
  const MembresiasView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestión de Membresías'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        actions: [
          // Botón para agregar nueva membresía en la AppBar
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _showAddDialog(context),
            tooltip: 'Añadir membresía',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchMemberships(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context),
      ),
      // El FloatingActionButton se ha eliminado y movido a la AppBar
    );
  }
  
  Widget _buildBody(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
        mobile: 16,
        tablet: 24,
        desktop: 32
      )),
      // Usamos un Column principal con Expanded para que el contenido no cause overflow
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera y filtros (no se expanden)
          _buildHeader(context),
          
          SizedBox(height: ResponsiveValues.getSpacing(context,
            mobile: 16,
            tablet: 20,
            desktop: 24
          )),
          
          // Lista de membresías (se expande para llenar el espacio restante)
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              
              if (controller.errorMessage.isNotEmpty) {
                return SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          controller.errorMessage.value,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              if (controller.filteredMemberships.isEmpty) {
                return SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_membership,
                          size: ResponsiveValues.getIconSize(context,
                            mobile: 80,
                            tablet: 100,
                            desktop: 120
                          ),
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: ResponsiveValues.getSpacing(context,
                          mobile: 16,
                          tablet: 24,
                          desktop: 32
                        )),
                        Text(
                          'No hay tipos de membresía disponibles',
                          style: TextStyle(
                            fontSize: ResponsiveValues.getFontSize(context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20
                            ),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return _buildMembershipsList(context);
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtros - Movido al principio para ser más prominente y similar a clientes_view
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Mostrar membresías inactivas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Obx(() => Switch(
                value: controller.showInactive.value,
                onChanged: (value) => controller.showInactive.value = value,
                activeColor: AppColors.success,
              )),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMembershipsList(BuildContext context) {
    final isTablet = ResponsiveValues.isTablet(context);
    
    if (isTablet) {
      // Vista de tabla para tablets
      return _buildMembershipsTable(context);
    } else {
      // Vista de lista para móviles
      return ListView.builder(
        itemCount: controller.filteredMemberships.length,
        itemBuilder: (context, index) {
          final membership = controller.filteredMemberships[index];
          return MembershipCard(
            membership: membership,
            onEdit: () => _showEditDialog(context, membership),
            onToggleActive: () => controller.toggleMembershipStatus(membership),
            onDelete: () => _showDeleteConfirmation(context, membership),
          );
        },
      );
    }
  }
  
  Widget _buildMembershipsTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Descripción')),
          DataColumn(label: Text('Precio')),
          DataColumn(label: Text('Duración')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: controller.filteredMemberships.map((membership) {
          return DataRow(
            cells: [
              DataCell(Text(membership.name)),
              DataCell(
                SizedBox(
                  width: 200,
                  child: Text(
                    membership.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(controller.formatPrice(membership.price))),
              DataCell(Text('${membership.durationDays} días')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: membership.isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    membership.isActive ? 'Activa' : 'Inactiva',
                    style: TextStyle(
                      color: membership.isActive ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón de editar
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () => _showEditDialog(context, membership),
                    tooltip: 'Editar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  // Botón de activar/desactivar
                  IconButton(
                    icon: Icon(
                      membership.isActive ? Icons.unpublished : Icons.check_circle,
                      color: membership.isActive ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                    onPressed: () => controller.toggleMembershipStatus(membership),
                    tooltip: membership.isActive ? 'Desactivar' : 'Activar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  // Botón de eliminar
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _showDeleteConfirmation(context, membership),
                    tooltip: 'Eliminar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              )),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  void _showAddDialog(BuildContext context) {
    controller.clearForm();
    
    Get.dialog(
      MembershipFormDialog(
        onSave: () => controller.createMembership(),
        controller: controller,
      ),
    );
  }
  
  void _showEditDialog(BuildContext context, membership) {
    controller.setupFormForEdit(membership);
    
    Get.dialog(
      MembershipFormDialog(
        onSave: () => controller.updateMembership(),
        controller: controller,
        isEditing: true,
      ),
 
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, membership) {
    final dialogWidth = ResponsiveValues.isTablet(context) ? 400.0 : 300.0;
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: dialogWidth,
          padding: EdgeInsets.all(ResponsiveValues.getSpacing(context,
            mobile: 20,
            tablet: 24,
            desktop: 28
          )),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: ResponsiveValues.getIconSize(context,
                  mobile: 48,
                  tablet: 56,
                  desktop: 64
                ),
              ),
              SizedBox(height: ResponsiveValues.getSpacing(context,
                mobile: 16,
                tablet: 20,
                desktop: 24
              )),
              Text(
                '¿Eliminar tipo de membresía?',
                style: TextStyle(
                  fontSize: ResponsiveValues.getFontSize(context,
                    mobile: 18,
                    tablet: 22,
                    desktop: 24
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveValues.getSpacing(context,
                mobile: 12,
                tablet: 16,
                desktop: 20
              )),
              Text(
                '¿Estás seguro de que deseas eliminar el tipo de membresía "${membership.name}"? Esta acción no se puede deshacer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveValues.getFontSize(context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18
                  ),
                ),
              ),
              SizedBox(height: ResponsiveValues.getSpacing(context,
                mobile: 20,
                tablet: 24,
                desktop: 28
              )),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                    OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancelar'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      if (membership.id != null) {
                        controller.deleteMembership(membership.id!);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
