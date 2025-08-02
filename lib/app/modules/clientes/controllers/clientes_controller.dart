import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/data/providers/membership_type_provider.dart';
import 'package:gymads/app/data/models/membership_type_model.dart';
import 'package:gymads/app/data/models/user_model.dart';
import 'package:gymads/app/data/repositories/user_repository.dart';
import 'package:gymads/app/global_widgets/qr_dialog.dart';

class ClientesController extends GetxController {
  final UserRepository userRepository;
  final MembershipTypeProvider membershipProvider;
  ClientesController({
    required this.userRepository,
    required this.membershipProvider,
  });

  // Estado observable para la lista de clientes
  final RxList<UserModel> clientes = <UserModel>[].obs;

  // Estado para búsqueda y filtrado
  final searchQuery = ''.obs;
  final selectedFilter = 'Todos'.obs;

  // Estado para el cliente seleccionado para visualizar detalles
  final Rx<UserModel?> selectedClient = Rx<UserModel?>(null);

  // Estado para indicar carga
  final RxBool isLoading = false.obs;
  // Estado observable para mensaje de error
  final RxString errorMessage = ''.obs;

  // Estado para formulario de cliente
  final nombreController = TextEditingController();
  final phoneController = TextEditingController();
  final userNumberController = TextEditingController();
  final rfidController = TextEditingController(); // Añadido controlador para RFID
  // Lista de tipos de membresía obtenida de la base de datos
  final membershipTypeList = <String>[].obs;
  // Lista de modelos completos de tipos de membresía
  final RxList<MembershipTypeModel> membershipTypes = <MembershipTypeModel>[].obs;
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
    fetchMembershipTypes();
  }

  @override
  void onClose() {
    nombreController.dispose();
    phoneController.dispose();
    userNumberController.dispose();
    rfidController.dispose(); // Añadir disposición del controlador RFID
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
  
  // Obtener los tipos de membresía desde la base de datos
  Future<void> fetchMembershipTypes() async {
    errorMessage.value = '';
    try {
      // Solo obtener membresías activas para el formulario de clientes
      final List<MembershipTypeModel> types = await membershipProvider.getMembershipTypes(onlyActive: true);
      
      // Guardar los modelos completos
      membershipTypes.assignAll(types);
      // También mantener la lista de nombres para retrocompatibilidad
      final List<String> typeNames = types.map((e) => e.name).toList();
      
      // Buscar "normal" de manera case-insensitive
      String? normalType = typeNames.firstWhereOrNull((name) => name.toLowerCase() == 'normal');
      
      // Asegurar que "normal" (o su variación) esté al principio de la lista si existe
      if (normalType != null) {
        typeNames.remove(normalType);
        typeNames.insert(0, normalType);
      }
      
      membershipTypeList.value = typeNames;
      
      // Solo cambiar el valor seleccionado si no es válido o si no está establecido
      if (membershipTypeList.isNotEmpty) {
        // Si el valor actual no está en la lista, seleccionar "normal" o el primero disponible
        if (!membershipTypeList.contains(selectedMembershipType.value)) {
          if (normalType != null) {
            selectedMembershipType.value = normalType;
          } else {
            selectedMembershipType.value = membershipTypeList.first;
          }
        }
      }
    } catch (e) {
      errorMessage.value = 'Error al cargar tipos de membresía: $e';
      print(errorMessage.value);
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
      // Calcular nueva fecha de expiración basada en duración de membresía de la base de datos
      final DateTime now = DateTime.now();
      final typeKey = membershipType.toLowerCase().trim();
      
      // Buscar en la lista de membresías para obtener la duración real
      MembershipTypeModel? selectedType = membershipTypes
          .firstWhereOrNull((type) => type.name.toLowerCase() == typeKey);
      
      // Usar la duración de la base de datos o valor predeterminado
      final durationDays = selectedType?.durationDays ?? 
                           UserModel.membershipDurations[typeKey] ?? 
                           30;
                           
      final DateTime newExpirationDate = now.add(Duration(days: durationDays));

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

        // Calcular el total pagado usando datos de la base de datos
        double price;
        
        // Obtener precio de la membresía seleccionada
        MembershipTypeModel? selectedType = membershipTypes
            .firstWhereOrNull((type) => type.name.toLowerCase() == typeKey);
            
        // Usar precio de la base de datos o valor predeterminado
        if (selectedType != null) {
          price = selectedType.price;
        } else {
          price = UserModel.membershipPrices[typeKey] ?? UserModel.membershipPrices['normal']!;
        }
        
        final double total = isNewRegistration ? price + UserModel.registrationFee : price;

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

  void setupFormForEdit(UserModel client) async {
    nombreController.text = client.name;
    phoneController.text = client.phone;
    userNumberController.text = client.userNumber.toString();
    rfidController.text = client.rfidCard ?? '';
    
    print('📞 DEBUG: Teléfono del cliente: "${client.phone}"');
    print('📞 DEBUG: phoneController.text establecido a: "${phoneController.text}"');
    
    // Limpiar listas actuales
    membershipTypes.clear();
    membershipTypeList.clear();
    
    try {
      // Cargar todos los tipos de membresía, activos e inactivos
      final allTypes = await membershipProvider.getMembershipTypes(onlyActive: false);
      
      // Asignar lista de modelos
      membershipTypes.assignAll(allTypes);
      
      // Crear lista de nombres única
      final Set<String> uniqueNamesSet = allTypes.map((m) => m.name).toSet();
      membershipTypeList.assignAll(uniqueNamesSet.toList());
      
      // Asegurarse de que el tipo del cliente esté en la lista
      if (!membershipTypeList.contains(client.membershipType)) {
        membershipTypeList.add(client.membershipType);
      }
    } catch (e) {
      print('Error al cargar tipos de membresía: $e');
      // En caso de error, al menos asegurarse que el tipo del cliente esté disponible
      membershipTypeList.add(client.membershipType);
    }
    
    // Establecer valor seleccionado (cliente)
    selectedMembershipType.value = client.membershipType;
    
    // Actualizar el costo para mostrar en la UI
    updateMembershipCost();
  }

  // Método para limpiar el formulario
  void clearForm() {
    nombreController.clear();
    phoneController.clear();
    userNumberController.clear();
    rfidController.clear(); // Añadido para RFID
    
    // Buscar "normal" de manera case-insensitive
    String? normalType = membershipTypeList.firstWhereOrNull((name) => name.toLowerCase() == 'normal');
    
    // Establecer membresía por defecto en "normal"
    if (normalType != null) {
      selectedMembershipType.value = normalType;
    } else if (membershipTypeList.isNotEmpty) {
      selectedMembershipType.value = membershipTypeList.first;
    } else {
      selectedMembershipType.value = 'normal'; // fallback
    }
    
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
    final typeToFind = selectedMembershipType.value.toLowerCase().trim();
    
    // Buscar primero en la lista de membresías de la base de datos
    MembershipTypeModel? selectedType = membershipTypes
        .firstWhereOrNull((type) => type.name.toLowerCase().trim() == typeToFind);
    
    if (selectedType != null) {
      // Usar el precio de la base de datos si se encuentra el tipo
      membershipCost.value = selectedType.price;
    } else {
      // Si no se encuentra, usar el precio estático como fallback
      final fallbackPrice = UserModel.membershipPrices[typeToFind];
      if (fallbackPrice != null) {
        membershipCost.value = fallbackPrice;
      } else {
        // Si tampoco hay precio estático, usar el precio de la membresía normal como último recurso
        membershipCost.value = UserModel.membershipPrices['normal'] ?? 0.0;
        
        // Si no se encontró el tipo seleccionado, podría ser necesario corregirlo
        if (membershipTypeList.isNotEmpty && !membershipTypeList.contains(selectedMembershipType.value)) {
          print('Tipo de membresía "${selectedMembershipType.value}" no encontrado, usando el primero disponible');
          selectedMembershipType.value = membershipTypeList.first;
        }
      }
    }
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
