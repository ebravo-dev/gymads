import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/data/models/user_model.dart';
import 'package:gymads/app/global_widgets/cliente_card.dart';
import 'package:gymads/app/global_widgets/cliente_form_dialog.dart';
import 'package:gymads/core/utils/responsive_utils.dart';

import '../controllers/clientes_controller.dart';

class ClientesView extends GetView<ClientesController> {
  const ClientesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Cargando clientes...',
                  style: TextStyle(
                    fontSize: ResponsiveValues.getFontSize(context,
                      mobile: 16,
                      smallPhone: 14,
                      tablet: 18
                    ), 
                    color: Colors.grey.shade600
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
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
                          color: Colors.grey,
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
                            color: Colors.grey,
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

  // Mostrar detalles de cliente
  void _showClienteDetails(UserModel cliente) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            // Limitar la altura al 80% de la pantalla para permitir scroll
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        cliente.photoUrl != null
                            ? NetworkImage(cliente.photoUrl!)
                            : null,
                    child:
                        cliente.photoUrl == null
                            ? Text(
                              cliente.name.isNotEmpty
                                  ? cliente.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${cliente.userNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),

              // Información de contacto
              _detailItem(Icons.phone, 'Teléfono:', cliente.phone),

              // Información de RFID
              _detailItem(
                Icons.credit_card,
                'Tarjeta RFID:',
                cliente.rfidCard ?? 'No asignada',
                textColor: cliente.rfidCard != null ? Colors.green : Colors.grey,
              ),

              // Información de membresía
              _detailItem(
                Icons.calendar_today,
                'Fecha de registro:',
                '${cliente.joinDate.day}/${cliente.joinDate.month}/${cliente.joinDate.year}',
              ),

              // Mostrar con primera letra en mayúscula
              _detailItem(
                Icons.card_membership,
                'Tipo de membresía:',
                '${cliente.membershipType[0].toUpperCase() + cliente.membershipType.substring(1)} (\$${cliente.membershipPrice.toStringAsFixed(0)})',
              ),

              if (cliente.expirationDate != null)
                _detailItem(
                  Icons.event,
                  'Fecha de expiración:',
                  '${cliente.expirationDate!.day}/${cliente.expirationDate!.month}/${cliente.expirationDate!.year}',
                ),

              _detailItem(
                Icons.timer,
                'Días restantes:',
                '${cliente.daysRemaining}',
                textColor:
                    cliente.needsRenewal
                        ? Colors.orange
                        : cliente.isActive
                        ? Colors.green
                        : Colors.red,
              ),

              if (cliente.lastPaymentDate != null)
                _detailItem(
                  Icons.payment,
                  'Último pago:',
                  '${cliente.lastPaymentDate!.day}/${cliente.lastPaymentDate!.month}/${cliente.lastPaymentDate!.year}',
                ),

              // Estado de membresía
              _detailItem(
                cliente.isActive
                    ? cliente.needsRenewal
                        ? Icons.warning
                        : Icons.check_circle
                    : Icons.cancel,
                'Estado:',
                cliente.isActive
                    ? cliente.needsRenewal
                        ? 'Por vencer'
                        : 'Activo'
                    : 'Inactivo',
                textColor:
                    cliente.isActive
                        ? cliente.needsRenewal
                            ? Colors.orange
                            : Colors.green
                        : Colors.red,
              ),

              // Información sobre el registro nuevo
              if (!cliente.isActive)
                _detailItem(
                  Icons.info_outline,
                  'Información:',
                  cliente.isNewRegistration()
                      ? 'Requiere pago de registro nuevo (\$${UserModel.registrationFee.toStringAsFixed(0)})'
                      : 'Puede renovar sin costo adicional',
                  textColor:
                      cliente.isNewRegistration() ? Colors.red : Colors.blue,
                ),

              const SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),  // Cierra Container
    ),    // Cierra Dialog
    );    // Cierra Get.dialog
  }

  // Widget para elementos de detalle
  Widget _detailItem(
    IconData icon,
    String label,
    String value, {
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor ?? Colors.grey, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
          ),
        ],
      ),
    );
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

    // Actualizar el costo de membresía según el tipo seleccionado
    controller.updateMembershipCost();
    // Inicializar tarifa de registro (nuevo cliente siempre paga registro)
    controller.updateRegistrationFee(true);

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
    controller.setupFormForEdit(cliente);
    
    // Recargar las membresías de la base de datos para tener la lista actualizada
    await controller.fetchMembershipTypes();

    // Actualizar costos
    controller.updateMembershipCost();
    // No cobra tarifa de registro en ediciones normales
    controller.updateRegistrationFee(false);

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
    controller.selectedMembershipType.value = cliente.membershipType;
    
    // Recargar las membresías de la base de datos para tener la lista actualizada
    await controller.fetchMembershipTypes();

    // Verificar si es un registro nuevo para aplicar tarifa adicional
    bool isNewRegistration = cliente.isNewRegistration();

    // Actualizar costos para mostrar en el formulario
    controller.updateMembershipCost();
    controller.updateRegistrationFee(isNewRegistration);

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
