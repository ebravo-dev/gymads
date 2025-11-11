import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/data/models/user_model.dart';
import 'package:gymads/app/global_widgets/cliente_card.dart';
import 'package:gymads/app/global_widgets/cliente_form_dialog.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:gymads/core/utils/responsive_utils.dart';
import 'cliente_detail_view.dart';

import '../controllers/clientes_controller.dart';

class ClientesView extends GetView<ClientesController> {
  const ClientesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchClientes(),
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(),
            tooltip: 'add',
          ),
        ],
      ),
      body: Obx(() {
        // Mostrar el indicador de carga a pantalla completa cuando isLoading es true
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 20),
                Text(
                  'Cargando clientes...',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Si no está cargando, mostrar el contenido normal
        return Column(
          children: [
            // Barra de búsqueda y filtros
            Padding(
              padding: EdgeInsets.all(ResponsiveValues.getSpacing(context, 
                mobile: 16, 
                smallPhone: 12,
                tablet: 24
              )),
              child: Column(
                children: [
                  // Barra de búsqueda
                  TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente...',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
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
                  SizedBox(height: ResponsiveValues.getSpacing(context,
                    mobile: 12,
                    smallPhone: 8,
                    tablet: 16
                  )),
                ],
              ),
            ),

            // Lista de clientes
            Expanded(
              child: Obx(() {
                final filteredClientes = controller.filteredClientes;

                if (filteredClientes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: ResponsiveValues.getIconSize(context,
                            mobile: 80,
                            smallPhone: 60,
                            tablet: 100
                          ),
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: ResponsiveValues.getSpacing(context,
                          mobile: 20,
                          smallPhone: 16,
                          tablet: 24
                        )),
                        Text(
                          controller.clientes.isEmpty
                              ? 'No hay clientes registrados'
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
                  itemCount: filteredClientes.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final cliente = filteredClientes[index];
                    
                    return ClienteCard(
                      cliente: cliente,
                      onTap: () => _showClienteDetails(cliente),
                      onEdit: () => _showEditDialog(cliente),
                      onDelete: () => _showDeleteConfirmation(cliente),
                      onRenovar: () => _showRenovarDialog(cliente),
                    );
                  },
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  // Mostrar detalles de cliente en vista completa
  void _showClienteDetails(UserModel cliente) {
    Get.to(() => ClienteDetailView(cliente: cliente));
  }

  // Mostrar diálogo para añadir cliente
  void _showAddDialog() async {
    // Recargar las membresías de la base de datos para tener la lista actualizada
    await controller.fetchMembershipTypes();
    
    // Limpiar el formulario después de cargar las membresías
    controller.clearForm();
    
    // Obtener un número de usuario único
    final userNumber = await controller.generateUniqueUserNumber();
    controller.userNumberController.text = userNumber.toString();

    // Inicializar promociones disponibles
    await controller.initializePromotions();

    Get.to(
      () => ClienteFormDialog(
        nombreController: controller.nombreController,
        phoneController: controller.phoneController,
        userNumberController: controller.userNumberController,
        rfidController: controller.rfidController,
        selectedMembershipType: controller.selectedMembershipType,
        membershipTypes: controller.membershipTypeList,
        membershipTypeModels: controller.membershipTypes,
        selectedPaymentMethod: controller.selectedPaymentMethod,
        paymentMethods: controller.paymentMethodList,
        membershipCost: controller.membershipCost,
        registrationFee: controller.registrationFee,
        totalAmount: controller.totalAmount,
        onSave: (user, photoFile) {
          controller.addCliente(user, photoFile: photoFile);
        },
        fullScreen: true,
      ),
      fullscreenDialog: true,
    );
  }

  // Mostrar diálogo para editar cliente
  void _showEditDialog(UserModel cliente) async {
    // Solo configurar el formulario para edición - setupFormForEdit manejará cargar las membresías
    await controller.setupFormForEdit(cliente);
    
    // Ya no es necesario llamar métodos adicionales, initializeForEdit se llama dentro de setupFormForEdit

    Get.to(
      () => ClienteFormDialog(
        nombreController: controller.nombreController,
        phoneController: controller.phoneController,
        userNumberController: controller.userNumberController,
        rfidController: controller.rfidController,
        selectedMembershipType: controller.selectedMembershipType,
        membershipTypes: controller.membershipTypeList,
        membershipTypeModels: controller.membershipTypes,
        selectedPaymentMethod: controller.selectedPaymentMethod,
        paymentMethods: controller.paymentMethodList,
        // isEditing: true, duplicado eliminada
        membershipCost: controller.membershipCost,
        registrationFee: controller.registrationFee,
        totalAmount: controller.totalAmount,
        currentPhotoUrl: cliente.photoUrl,
        onSave: (updatedUser, photoFile) {
          // Preservar ID y otros campos que no deberían cambiar
          final user = updatedUser.copyWith(
            id: cliente.id,
            joinDate: cliente.joinDate,
            accessHistory: cliente.accessHistory,
            // Mantener la URL de la foto anterior si no se proporciona una nueva
            photoUrl: photoFile == null ? cliente.photoUrl : null,
          );

          controller.updateCliente(cliente.id!, user, photoFile: photoFile);
        },
        isEditing: true,
        fullScreen: true,
      ),
      fullscreenDialog: true,
    );
  }

  // Mostrar confirmación para eliminar
  void _showDeleteConfirmation(UserModel cliente) {
    Get.defaultDialog(
      title: 'Eliminar Cliente',
      middleText: '¿Estás seguro de que deseas eliminar a ${cliente.name}?',
      textConfirm: 'Eliminar',
      textCancel: 'Cancelar',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        controller.deleteCliente(cliente.id!);
        Get.back();
      },
    );
  }

  // Mostrar diálogo para renovar membresía
  void _showRenovarDialog(UserModel cliente) async {
    // Configurar el formulario para edición/renovación - esto cargará todas las membresías
    await controller.setupFormForEdit(cliente);
    
    // Usar el método específico para renovación
    controller.initializeForRenewal(cliente);

    Get.dialog(
      ClienteFormDialog(
        nombreController: controller.nombreController,
        phoneController: controller.phoneController,
        userNumberController: controller.userNumberController,
        rfidController: controller.rfidController,
        selectedMembershipType: controller.selectedMembershipType,
        membershipTypes: controller.membershipTypeList,
        membershipTypeModels: controller.membershipTypes,
        selectedPaymentMethod: controller.selectedPaymentMethod,
        paymentMethods: controller.paymentMethodList,
        isEditing: true,
        isRenewing: true,
        membershipCost: controller.membershipCost,
        registrationFee: controller.registrationFee,
        totalAmount: controller.totalAmount,
        onSave: (updatedUser, photoFile) {
          controller.renewMembership(
            cliente,
            controller.selectedMembershipType.value,
            controller.selectedPaymentMethod.value,
          );
        },
      ),
    );
  }
}
