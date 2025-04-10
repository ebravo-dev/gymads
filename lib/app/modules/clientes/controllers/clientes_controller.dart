import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/data/models/user_model.dart';
import 'package:gymads/app/data/repositories/user_repository.dart';
import 'package:gymads/app/global_widgets/qr_dialog.dart';

class ClientesController extends GetxController {
  final UserRepository userRepository;
  ClientesController({required this.userRepository});

  // Estado observable para la lista de clientes
  final RxList<UserModel> clientes = <UserModel>[].obs;

  // Estado para búsqueda y filtrado
  final searchQuery = ''.obs;
  final selectedFilter = 'Todos'.obs;

  // Estado para el cliente seleccionado para visualizar detalles
  final Rx<UserModel?> selectedClient = Rx<UserModel?>(null);

  // Estado para indicar carga
  final RxBool isLoading = false.obs;

  // Estado para formulario de cliente
  final nombreController = TextEditingController();
  final phoneController = TextEditingController();
  final userNumberController = TextEditingController();
  final membershipTypeList = ['normal', 'estudiante', 'profesor'].obs;
  final selectedMembershipType = 'normal'.obs;
  final paymentMethodList = ['Efectivo', 'Tarjeta', 'Transferencia'].obs;
  final selectedPaymentMethod = 'Efectivo'.obs;

  // Información del pago actual
  final RxDouble membershipCost = 0.0.obs;
  final RxDouble registrationFee = 0.0.obs;
  final RxDouble totalAmount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchClientes();
  }

  @override
  void onClose() {
    nombreController.dispose();
    phoneController.dispose();
    userNumberController.dispose();
    super.onClose();
  }

  // Método para obtener todos los clientes
  Future<void> fetchClientes() async {
    isLoading.value = true;
    try {
      final users = await userRepository.getAllUsers();
      clientes.assignAll(users);
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron cargar los clientes: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Método para filtrar clientes
  List<UserModel> get filteredClientes {
    if (searchQuery.isEmpty && selectedFilter.value == 'Todos') {
      return clientes;
    }

    return clientes.where((client) {
      // Aplicar filtro de texto (nombre, teléfono o número)
      bool matchesSearch =
          searchQuery.isEmpty ||
          client.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          client.phone.toLowerCase().contains(searchQuery.toLowerCase()) ||
          client.userNumber.toString().contains(searchQuery.toLowerCase());

      // Aplicar filtro de estado
      bool matchesFilter =
          selectedFilter.value == 'Todos' ||
          (selectedFilter.value == 'Activos' && client.isActive) ||
          (selectedFilter.value == 'Inactivos' && !client.isActive) ||
          (selectedFilter.value == 'Por vencer' && client.needsRenewal);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // Método para añadir un nuevo cliente
  Future<bool> addCliente(UserModel newClient, {File? photoFile}) async {
    isLoading.value = true;
    try {
      final success = await userRepository.addUser(
        newClient,
        photoFile: photoFile,
      );
      if (success) {
        await fetchClientes();
        Get.back(); // Cerrar el diálogo de creación

        // Mostrar el diálogo con el QR
        Get.dialog(
          QrDialog(
            nombre: newClient.name,
            telefono: newClient.phone,
            userNumber: newClient.userNumber,
            totalAmount: totalAmount.value,
          ),
        );

        Get.snackbar(
          'Éxito',
          'Cliente agregado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'No se pudo agregar el cliente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al agregar cliente: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Método para actualizar un cliente existente
  Future<bool> updateCliente(
    String id,
    UserModel updatedClient, {
    File? photoFile,
  }) async {
    isLoading.value = true;
    try {
      final success = await userRepository.updateUser(
        id,
        updatedClient,
        photoFile: photoFile,
      );
      if (success) {
        // Actualizar la lista local para reflejar los cambios
        final index = clientes.indexWhere((client) => client.id == id);
        if (index != -1) {
          clientes[index] = updatedClient;
          clientes.refresh();
        }

        Get.snackbar(
          'Éxito',
          'Cliente actualizado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'No se pudo actualizar el cliente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al actualizar cliente: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Método para eliminar un cliente
  Future<bool> deleteCliente(String id) async {
    isLoading.value = true;
    try {
      final success = await userRepository.deleteUser(id);
      if (success) {
        // Eliminar de la lista local
        clientes.removeWhere((client) => client.id == id);

        Get.snackbar(
          'Éxito',
          'Cliente eliminado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'No se pudo eliminar el cliente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al eliminar cliente: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Método para renovar la membresía de un cliente
  Future<bool> renewMembership(
    UserModel client,
    String membershipType,
    String paymentMethod,
  ) async {
    isLoading.value = true;
    try {
      // Calcular nueva fecha de expiración (3 meses = 90 días)
      final DateTime now = DateTime.now();
      final DateTime newExpirationDate = now.add(Duration(days: 90));

      // Verificar si es un registro nuevo (más de 3 meses sin pagar)
      bool isNewRegistration = client.isNewRegistration();

      final updatedClient = client.copyWith(
        membershipType: membershipType,
        expirationDate: newExpirationDate,
        isActive: true,
        lastPaymentDate: now,
        // Si es un registro nuevo, resetear el historial de accesos
        accessHistory: isNewRegistration ? [] : client.accessHistory,
      );

      final success = await userRepository.updateUser(
        client.id!,
        updatedClient,
      );
      if (success) {
        // Actualizar en la lista local
        final index = clientes.indexWhere((c) => c.id == client.id);
        if (index != -1) {
          clientes[index] = updatedClient;
          clientes.refresh();
        }

        // Calcular el total pagado
        final double total =
            isNewRegistration
                ? UserModel.membershipPrices[membershipType]! +
                    UserModel.registrationFee
                : UserModel.membershipPrices[membershipType]!;

        Get.back(); // Cerrar el diálogo de renovación

        // Mostrar el QR con el total pagado
        Get.dialog(
          QrDialog(
            nombre: updatedClient.name,
            telefono: updatedClient.phone,
            userNumber: updatedClient.userNumber,
            totalAmount: total,
          ),
        );

        Get.snackbar(
          'Éxito',
          'Membresía renovada correctamente. Monto cobrado: \$${total.toStringAsFixed(2)}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          'No se pudo renovar la membresía',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al renovar membresía: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Método para configurar formulario con datos de cliente existente
  void setupFormForEdit(UserModel client) {
    nombreController.text = client.name;
    phoneController.text = client.phone;
    userNumberController.text = client.userNumber.toString();
    selectedMembershipType.value = client.membershipType;
  }

  // Método para limpiar el formulario
  void clearForm() {
    nombreController.clear();
    phoneController.clear();
    userNumberController.clear();
    selectedMembershipType.value = 'normal';
    selectedPaymentMethod.value = 'Efectivo';
    membershipCost.value = UserModel.membershipPrices['normal']!;
    registrationFee.value = UserModel.registrationFee;
    updateTotalAmount();
  }

  // Método para generar un número único de usuario
  Future<String> generateUniqueUserNumber() async {
    final Random random = Random();
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const int codeLength = 5;

    while (true) {
      // Generar un código aleatorio de 5 caracteres
      String code =
          List.generate(codeLength, (index) {
            return chars[random.nextInt(chars.length)];
          }).join();

      // Verificar si el código ya existe
      final allClients = await userRepository.getAllUsers();
      bool isUnique = !allClients.any((client) => client.userNumber == code);

      if (isUnique) {
        return code;
      }
    }
  }

  // Método para calcular el precio de membresía según el tipo seleccionado
  void updateMembershipCost() {
    membershipCost.value =
        UserModel.membershipPrices[selectedMembershipType.value] ??
        UserModel.membershipPrices['normal']!;
    updateTotalAmount();
  }

  // Método para actualizar tarifa de registro (se cobra solo si es nuevo o expiró hace más de 3 meses)
  void updateRegistrationFee(bool isNewOrExpired) {
    registrationFee.value = isNewOrExpired ? UserModel.registrationFee : 0.0;
    updateTotalAmount();
  }

  // Método para actualizar el monto total
  void updateTotalAmount() {
    totalAmount.value = membershipCost.value + registrationFee.value;
  }
}
