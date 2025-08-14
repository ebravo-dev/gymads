import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/data/providers/membership_type_provider.dart';
import 'package:gymads/app/data/models/membership_type_model.dart';
import 'package:gymads/app/data/models/user_model.dart';
import 'package:gymads/app/data/models/promotion_model.dart';
import 'package:gymads/app/data/repositories/user_repository.dart';
import 'package:gymads/app/data/services/promotion_service.dart';
import 'package:gymads/app/data/services/ingreso_service.dart';
import 'package:gymads/app/modules/ingresos/controllers/ingresos_controller.dart';
import 'package:gymads/app/global_widgets/qr_dialog.dart';

class ClientesController extends GetxController {
  final UserRepository userRepository;
  final MembershipTypeProvider membershipProvider;
  final IngresoService? ingresoService; // Opcional para evitar problemas de dependencias
  
  ClientesController({
    required this.userRepository,
    required this.membershipProvider,
    this.ingresoService,
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
  
  // Información de promociones
  final RxList<PromotionModel> availablePromotions = <PromotionModel>[].obs;
  final Rx<PromotionModel?> selectedPromotion = Rx<PromotionModel?>(null);
  final RxDouble promotionDiscount = 0.0.obs;
  final RxDouble finalAmount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchClientes();
    fetchMembershipTypes();
    
    // Escuchar cambios en el tipo de membresía para actualizar promociones
    selectedMembershipType.listen((_) {
      updateMembershipCost();
    });
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
      
      // Crear lista de nombres única usando normalización de strings
      final Set<String> typeNamesSet = {};
      for (final type in types) {
        final trimmedName = type.name.trim();
        typeNamesSet.add(trimmedName);
      }
      final List<String> typeNames = typeNamesSet.toList();
      
      // Buscar "normal" de manera case-insensitive
      String? normalType = typeNames.firstWhereOrNull((name) => name.toLowerCase() == 'normal');
      
      // Asegurar que "normal" (o su variación) esté al principio de la lista si existe
      if (normalType != null) {
        typeNames.remove(normalType);
        typeNames.insert(0, normalType);
      }
      
      membershipTypeList.clear(); // Limpiar antes de asignar
      membershipTypeList.assignAll(typeNames);
      
      // Solo cambiar el valor seleccionado si no es válido o si no está establecido
      if (membershipTypeList.isNotEmpty) {
        // Si el valor actual no está en la lista, seleccionar "normal" o el primero disponible
        bool currentValueExists = membershipTypeList.any((name) => 
          name.toLowerCase() == selectedMembershipType.value.toLowerCase()
        );
        
        if (!currentValueExists) {
          if (normalType != null) {
            selectedMembershipType.value = normalType;
          } else {
            selectedMembershipType.value = membershipTypeList.first;
          }
        }
      }
      
      print('🔍 DEBUG fetchMembershipTypes: ${typeNames.join(", ")}');
    } catch (e) {
      errorMessage.value = 'Error al cargar tipos de membresía: $e';
      print(errorMessage.value);
    }
  }
  
  // Obtener promociones disponibles
  Future<void> fetchAvailablePromotions() async {
    try {
      print('🔍 DEBUG: Iniciando fetchAvailablePromotions...');
      print('   - Tipo de membresía: ${selectedMembershipType.value}');
      print('   - Costo membresía: ${membershipCost.value}');
      print('   - Tarifa registro: ${registrationFee.value}');
      print('   - Día actual: ${DateTime.now().weekday % 7} (${_getDayName(DateTime.now().weekday % 7)})');
      
      final promotionService = Get.find<PromotionService>();
      
      // Obtener TODAS las promociones válidas, no solo las mejores
      final allValidPromotions = await promotionService.getCurrentValidPromotions();
      
      print('🎯 DEBUG: Promociones válidas obtenidas del servicio: ${allValidPromotions.length}');
      for (final promo in allValidPromotions) {
        print('   - ${promo.name}: ${promo.appliesTo} | Día: ${promo.dayOfWeek} | Activa: ${promo.isCurrentlyValid}');
      }
      
      // Filtrar promociones que apliquen al contexto actual
      final List<PromotionModel> applicablePromotions = [];
      
      for (final promotion in allValidPromotions) {
        bool isApplicable = false;
        
        print('📝 DEBUG: Evaluando promoción "${promotion.name}"...');
        
        // Verificar si aplica a registro (cuando hay tarifa de registro)
        if (registrationFee.value > 0 && 
           (promotion.appliesTo_('registration') || promotion.appliesTo_('both'))) {
          isApplicable = true;
          print('   ✅ Aplica a registro (tarifa: ${registrationFee.value})');
        }
        
        // Verificar si aplica a membresía
        if (promotion.appliesTo_('membership') || promotion.appliesTo_('both')) {
          isApplicable = true;
          print('   ✅ Aplica a membresía');
        }
        
        // Verificar condiciones específicas (día de la semana, tipo de membresía, etc.)
        if (isApplicable && promotion.isCurrentlyValid) {
          print('   ✅ Promoción es válida y aplicable inicialmente');
          
          // Verificar día de la semana si está especificado
          if (promotion.dayOfWeek != null) {
            final today = DateTime.now();
            final currentDayOfWeek = today.weekday % 7; // 0=domingo, 6=sábado
            if (promotion.dayOfWeek != currentDayOfWeek) {
              isApplicable = false;
              print('   ❌ No aplica por día de semana (requiere: ${_getDayName(promotion.dayOfWeek!)}, hoy: ${_getDayName(currentDayOfWeek)})');
            } else {
              print('   ✅ Aplica por día de semana (${_getDayName(promotion.dayOfWeek!)})');
            }
          }
          
          // Verificar tipo de membresía si está especificado
          if (promotion.membershipTypes.isNotEmpty &&
              !promotion.appliesToMembership(selectedMembershipType.value)) {
            isApplicable = false;
            print('   ❌ No aplica por tipo de membresía (requiere: ${promotion.membershipTypes}, actual: ${selectedMembershipType.value})');
          } else if (promotion.membershipTypes.isNotEmpty) {
            print('   ✅ Aplica por tipo de membresía');
          }
          
          if (isApplicable) {
            applicablePromotions.add(promotion);
            print('   🎉 Promoción agregada a la lista aplicable');
          }
        } else {
          print('   ❌ Promoción no válida o no aplicable (isCurrentlyValid: ${promotion.isCurrentlyValid})');
        }
      }
      
      availablePromotions.assignAll(applicablePromotions);
      
      // Debug para verificar las promociones encontradas
      print('🎯 DEBUG: Promociones disponibles FINALES: ${applicablePromotions.length}');
      for (final promo in applicablePromotions) {
        print('   - ${promo.name}: ${promo.appliesTo} | Día: ${promo.dayOfWeek} | Activa: ${promo.isCurrentlyValid}');
      }
      
      // Auto-seleccionar la mejor promoción si hay alguna disponible
      if (applicablePromotions.isNotEmpty) {
        PromotionModel? bestPromotion;
        double bestDiscount = 0.0;
        
        for (final promotion in applicablePromotions) {
          final discount = _calculatePromotionDiscount(promotion);
          print('💰 DEBUG: Descuento calculado para "${promotion.name}": \$${discount.toStringAsFixed(2)}');
          if (discount > bestDiscount) {
            bestDiscount = discount;
            bestPromotion = promotion;
          }
        }
        
        if (bestPromotion != null) {
          selectedPromotion.value = bestPromotion;
          promotionDiscount.value = bestDiscount;
          finalAmount.value = totalAmount.value - bestDiscount;
          print('🏆 DEBUG: Mejor promoción seleccionada: "${bestPromotion.name}" con descuento \$${bestDiscount.toStringAsFixed(2)}');
        } else {
          selectedPromotion.value = null;
          promotionDiscount.value = 0.0;
          finalAmount.value = totalAmount.value;
          print('❌ DEBUG: No hay promoción con descuento válido');
        }
      } else {
        selectedPromotion.value = null;
        promotionDiscount.value = 0.0;
        finalAmount.value = totalAmount.value;
        print('❌ DEBUG: No hay promociones aplicables');
      }
      
      // Actualizar la UI
      update(['promotions']);
    } catch (e) {
      print('❌ ERROR al obtener promociones: $e');
      availablePromotions.clear();
      selectedPromotion.value = null;
      promotionDiscount.value = 0.0;
      finalAmount.value = totalAmount.value;
    }
  }
  
  String _getDayName(int dayOfWeek) {
    const days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    return days[dayOfWeek];
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
      final userId = await userRepository.addUser(
        newClient,
        photoFile: photoFile,
      );
      
      if (userId != null) {
        await fetchClientes();
        
        // Actualizar el cliente con el ID recién obtenido
        final clienteConId = newClient.copyWith(id: userId);
        
        // Registrar el ingreso automáticamente si el servicio está disponible
        if (ingresoService != null) {
          try {
            print('🔧 DEBUG: IngresoService disponible, registrando ingreso...');
            
            // Obtener información del staff actual (por ahora hardcodeado, después se puede obtener del usuario autenticado)
            final usuarioStaff = 'Staff'; // TODO: Obtener del usuario autenticado
            
            print('🔧 DEBUG: Datos para ingreso:');
            print('   - clienteId: $userId');
            print('   - clienteNombre: ${clienteConId.name}');
            print('   - tipoMembresia: ${clienteConId.membershipType}');
            print('   - precioRegistro: ${registrationFee.value}');
            print('   - precioMembresia: ${membershipCost.value}');
            print('   - metodoPago: ${selectedPaymentMethod.value.toLowerCase()}');
            print('   - usuarioStaff: $usuarioStaff');
            print('   - promocion: ${selectedPromotion.value?.name ?? 'Ninguna'}');
            
            // Registrar el ingreso
            final ingresoRegistrado = await ingresoService!.registrarIngresoNuevoCliente(
              clienteId: userId,
              clienteNombre: clienteConId.name,
              tipoMembresia: clienteConId.membershipType,
              precioRegistro: registrationFee.value,
              precioMembresia: membershipCost.value,
              metodoPago: selectedPaymentMethod.value.toLowerCase(),
              usuarioStaff: usuarioStaff,
              promocion: selectedPromotion.value,
              notas: 'Registro de nuevo cliente',
            );
            
            if (ingresoRegistrado) {
              print('✅ Ingreso registrado correctamente para ${clienteConId.name}');
              // Refrescar datos de ingresos globalmente
              IngresosController.refreshIngresosGlobally();
            } else {
              print('⚠️ No se pudo registrar el ingreso para ${clienteConId.name}');
            }
          } catch (e) {
            print('❌ Error al registrar ingreso: $e');
            print('📊 Stack trace: ${StackTrace.current}');
          }
        } else {
          print('⚠️ IngresoService no disponible, no se registrará el ingreso');
        }
        
        Get.back(); // Cerrar el diálogo de creación

        // Mostrar el diálogo con el QR
        Get.dialog(
          QrDialog(
            nombre: clienteConId.name,
            telefono: clienteConId.phone,
            userNumber: clienteConId.userNumber,
            totalAmount: finalAmount.value > 0 ? finalAmount.value : totalAmount.value,
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

        // Registrar el ingreso automáticamente si el servicio está disponible
        if (ingresoService != null) {
          try {
            final usuarioStaff = 'Staff'; // TODO: Obtener del usuario autenticado
            
            final ingresoRegistrado = await ingresoService!.registrarIngresoRenovacion(
              clienteId: client.id!,
              clienteNombre: client.name,
              tipoMembresia: membershipType,
              precioMembresia: price,
              metodoPago: paymentMethod.toLowerCase(),
              usuarioStaff: usuarioStaff,
              promocion: selectedPromotion.value,
              notas: isNewRegistration ? 'Renovación con registro nuevo' : 'Renovación de membresía',
            );
            
            if (ingresoRegistrado) {
              print('✅ Ingreso de renovación registrado correctamente para ${client.name}');
              // Refrescar datos de ingresos globalmente
              IngresosController.refreshIngresosGlobally();
            } else {
              print('⚠️ No se pudo registrar el ingreso de renovación para ${client.name}');
            }
          } catch (e) {
            print('❌ Error al registrar ingreso de renovación: $e');
          }
        }

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

  Future<void> setupFormForEdit(UserModel client) async {
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
      // Cargar solo los tipos de membresía activos
      final activeTypes = await membershipProvider.getMembershipTypes(onlyActive: true);
      
      // Verificar si la membresía actual del cliente está activa
      final clientMembershipNormalized = client.membershipType.trim();
      bool clientMembershipIsActive = activeTypes.any((type) => 
        type.name.toLowerCase().trim() == clientMembershipNormalized.toLowerCase()
      );
      
      // Si la membresía del cliente no está activa, cargarla también
      List<MembershipTypeModel> allTypesToShow = List.from(activeTypes);
      if (!clientMembershipIsActive) {
        // Buscar la membresía inactiva del cliente
        final allTypes = await membershipProvider.getMembershipTypes(onlyActive: false);
        final clientInactiveType = allTypes.firstWhereOrNull((type) =>
          type.name.toLowerCase().trim() == clientMembershipNormalized.toLowerCase()
        );
        if (clientInactiveType != null) {
          allTypesToShow.add(clientInactiveType);
        }
      }
      
      // Asignar lista de modelos
      membershipTypes.assignAll(allTypesToShow);
      
      // Crear lista de nombres única usando normalización de strings
      final Set<String> uniqueNamesSet = {};
      for (final type in allTypesToShow) {
        final trimmedName = type.name.trim();
        uniqueNamesSet.add(trimmedName);
      }
      
      // Convertir a lista, limpiar y asignar
      final List<String> uniqueNamesList = uniqueNamesSet.toList();
      membershipTypeList.clear(); // Limpiar antes de asignar
      membershipTypeList.assignAll(uniqueNamesList);
    } catch (e) {
      print('Error al cargar tipos de membresía: $e');
      // En caso de error, al menos asegurarse que el tipo del cliente esté disponible
      final clientMembership = client.membershipType.trim();
      if (!membershipTypeList.any((name) => name.toLowerCase() == clientMembership.toLowerCase())) {
        membershipTypeList.add(clientMembership);
      }
    }
    
    // Establecer valor seleccionado (cliente) - buscar coincidencia exacta en la lista
    String clientMembershipToSet = client.membershipType.trim();
    
    // Buscar el valor exacto en la lista (puede tener capitalización diferente)
    String? exactMatch = membershipTypeList.firstWhereOrNull((name) => 
      name.toLowerCase() == clientMembershipToSet.toLowerCase()
    );
    
    if (exactMatch != null) {
      selectedMembershipType.value = exactMatch;
    } else {
      // Si no se encuentra, usar el primer valor disponible o el original
      if (membershipTypeList.isNotEmpty) {
        selectedMembershipType.value = membershipTypeList.first;
      } else {
        selectedMembershipType.value = clientMembershipToSet;
      }
    }
    
    // Inicializar para edición
    initializeForEdit(client);
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
    
    // Configurar tasas de registro para cliente nuevo
    registrationFee.value = UserModel.registrationFee;
    
    // Limpiar promociones
    availablePromotions.clear();
    selectedPromotion.value = null;
    promotionDiscount.value = 0.0;
    finalAmount.value = 0.0;
    
    // Actualizar costos
    updateMembershipCost();
  }
  
  // Método para inicializar el formulario en modo edición
  void initializeForEdit(UserModel client) {
    // Configurar tasas de registro (sin cobrar en edición normal)
    registrationFee.value = 0.0;
    
    // Actualizar costos basados en el tipo de membresía del cliente
    updateMembershipCost();
    
    // Inicializar promociones
    initializePromotions();
  }
  
  // Método para inicializar el formulario en modo renovación
  void initializeForRenewal(UserModel client) {
    // Verificar si es un registro nuevo (más de 3 meses sin pagar)
    bool isNewRegistration = client.isNewRegistration();
    
    // Configurar tarifa de registro si es necesario
    registrationFee.value = isNewRegistration ? UserModel.registrationFee : 0.0;
    
    // Actualizar costos
    updateMembershipCost();
    
    // Inicializar promociones
    initializePromotions();
  }
  
  // Método para inicializar las promociones en el formulario
  Future<void> initializePromotions() async {
    await fetchAvailablePromotions();
    
    // Auto-seleccionar la mejor promoción si hay alguna disponible
    if (availablePromotions.isNotEmpty) {
      PromotionModel? bestPromotion;
      double bestDiscount = 0.0;
      
      for (final promotion in availablePromotions) {
        final discount = _calculatePromotionDiscount(promotion);
        if (discount > bestDiscount) {
          bestDiscount = discount;
          bestPromotion = promotion;
        }
      }
      
      if (bestPromotion != null) {
        applyPromotion(bestPromotion);
      }
    }
    
    // Actualizar la UI
    update(['promotions']);
  }
  
  // Método auxiliar para calcular descuento de una promoción específica
  double _calculatePromotionDiscount(PromotionModel promotion) {
    if (!promotion.isCurrentlyValid) return 0.0;
    
    double discount = 0.0;
    
    // Verificar si aplica a registro
    if (promotion.appliesTo_('registration') || promotion.appliesTo_('both')) {
      discount += promotion.calculateDiscount(registrationFee.value);
    }
    
    // Verificar si aplica a membresía  
    if (promotion.appliesTo_('membership') || promotion.appliesTo_('both')) {
      discount += promotion.calculateDiscount(membershipCost.value);
    }
    
    return discount;
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
    
    // Actualizar el total después de cambiar el costo de membresía
    updateTotalAmount();
    
    // Obtener promociones disponibles para el nuevo tipo de membresía
    fetchAvailablePromotions();
  }

  // Método para actualizar tarifa de registro (se cobra solo si es nuevo o expiró hace más de 3 meses)
  void updateRegistrationFee(bool isNewOrExpired) {
    registrationFee.value = isNewOrExpired ? UserModel.registrationFee : 0.0;
    updateTotalAmount();
  }

  // Método para actualizar el monto total
  void updateTotalAmount() {
    totalAmount.value = membershipCost.value + registrationFee.value;
    
    // Calcular el monto final considerando promociones
    if (selectedPromotion.value != null && promotionDiscount.value > 0) {
      finalAmount.value = totalAmount.value - promotionDiscount.value;
      // Asegurar que el monto final no sea negativo
      if (finalAmount.value < 0) finalAmount.value = 0;
    } else {
      finalAmount.value = totalAmount.value;
    }
  }
  
  // Método para aplicar una promoción específica
  void applyPromotion(PromotionModel? promotion) {
    selectedPromotion.value = promotion;
    
    if (promotion != null) {
      // Calcular el descuento basado en el tipo de promoción
      double discount = 0.0;
      
      if (promotion.appliesTo_('registration') || promotion.appliesTo_('both')) {
        discount += promotion.calculateDiscount(registrationFee.value);
      }
      
      if (promotion.appliesTo_('membership') || promotion.appliesTo_('both')) {
        discount += promotion.calculateDiscount(membershipCost.value);
      }
      
      promotionDiscount.value = discount;
    } else {
      promotionDiscount.value = 0.0;
    }
    
    updateTotalAmount();
  }
}
