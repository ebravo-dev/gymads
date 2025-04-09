import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/data/models/user_model.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class ClienteFormDialog extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController phoneController;
  final TextEditingController userNumberController;
  final RxString selectedMembershipType;
  final List<String> membershipTypes;
  final RxString selectedPaymentMethod;
  final List<String> paymentMethods;
  final bool isEditing;
  final bool isRenewing;
  final Function(UserModel) onSave;
  final RxDouble membershipCost;
  final RxDouble registrationFee;
  final RxDouble totalAmount;

  const ClienteFormDialog({
    super.key,
    required this.nombreController,
    required this.phoneController,
    required this.userNumberController,
    required this.selectedMembershipType,
    required this.membershipTypes,
    required this.selectedPaymentMethod,
    required this.paymentMethods,
    this.isEditing = false,
    this.isRenewing = false,
    required this.onSave,
    required this.membershipCost,
    required this.registrationFee,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final bool isNewRegistration = !isEditing || isRenewing;
    final phoneNumberController = TextEditingController();

    if (phoneController.text.isNotEmpty) {
      try {
        PhoneNumber.getRegionInfoFromPhoneNumber(
          phoneController.text,
          'MX',
        ).then((value) => phoneNumberController.text = value.phoneNumber ?? '');
      } catch (e) {
        phoneNumberController.text = phoneController.text;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context, formKey, isNewRegistration),
    );
  }

  Widget contentBox(
    BuildContext context,
    GlobalKey<FormState> formKey,
    bool isNewRegistration,
  ) {
    final initialPhoneNumber = PhoneNumber(isoCode: 'MX');
    String formattedPhoneNumber = '';

    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: const Color.fromARGB(255, 34, 34, 34),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            offset: const Offset(0, 10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    isEditing
                        ? (isRenewing ? Icons.autorenew : Icons.edit)
                        : Icons.person_add,
                    color: AppColors.textPrimary,
                    size: 30,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    isEditing
                        ? (isRenewing ? 'Renovar Membresía' : 'Editar Cliente')
                        : 'Nuevo Cliente',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (!isRenewing) ...[
                      TextFormField(
                        controller: userNumberController,
                        decoration: InputDecoration(
                          labelText: 'Número de Usuario',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.badge_outlined),
                          filled: true,
                          fillColor: AppColors.containerBackground,
                        ),
                        style: TextStyle(color: AppColors.accent),
                        keyboardType: TextInputType.number,
                        readOnly: isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un número de usuario';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: AppColors.containerBackground,
                        ),
                        style: TextStyle(color: AppColors.textPrimary),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InternationalPhoneNumberInput(
                        onInputChanged: (PhoneNumber number) {
                          formattedPhoneNumber = number.phoneNumber ?? '';
                          phoneController.text = formattedPhoneNumber;
                        },
                        onInputValidated: (bool value) {
                          if (value && formattedPhoneNumber.isNotEmpty) {
                            phoneController.text = formattedPhoneNumber;
                          }
                        },
                        selectorConfig: const SelectorConfig(
                          selectorType: PhoneInputSelectorType.DIALOG,
                          setSelectorButtonAsPrefixIcon: true,
                        ),
                        ignoreBlank: false,
                        autoValidateMode: AutovalidateMode.onUserInteraction,
                        initialValue: initialPhoneNumber,
                        textStyle: TextStyle(color: AppColors.textPrimary),
                        selectorTextStyle: TextStyle(
                          color: AppColors.textPrimary,
                        ),
                        inputDecoration: InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: AppColors.containerBackground,
                        ),
                        searchBoxDecoration: InputDecoration(
                          labelText: 'Buscar país',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        locale: 'es',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un número de teléfono';
                          }
                          if (!formattedPhoneNumber.startsWith('+')) {
                            return 'El número debe incluir el código de país';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    Obx(
                      () => DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Tipo de Membresía',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.card_membership),
                          filled: true,
                          fillColor: AppColors.containerBackground,
                        ),
                        dropdownColor: AppColors.cardBackground,
                        style: TextStyle(color: AppColors.textPrimary),
                        value: selectedMembershipType.value,
                        items:
                            membershipTypes.map((type) {
                              double precio =
                                  UserModel.membershipPrices[type] ?? 0.0;
                              String displayType =
                                  type[0].toUpperCase() + type.substring(1);
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  '$displayType (\$${precio.toStringAsFixed(0)})',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            selectedMembershipType.value = value;
                            membershipCost.value =
                                UserModel.membershipPrices[value] ??
                                UserModel.membershipPrices['normal']!;
                            totalAmount.value =
                                membershipCost.value + registrationFee.value;
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Método de Pago',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.payments_outlined),
                          filled: true,
                          fillColor: AppColors.containerBackground,
                        ),
                        dropdownColor: AppColors.cardBackground,
                        style: TextStyle(color: AppColors.textPrimary),
                        value: selectedPaymentMethod.value,
                        items:
                            paymentMethods
                                .map(
                                  (method) => DropdownMenuItem(
                                    value: method,
                                    child: Text(
                                      method,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            selectedPaymentMethod.value = value;
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.containerBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.receipt_long, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Text(
                                'Resumen de Pago',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Obx(
                            () => _buildCostRow(
                              'Membresía:',
                              membershipCost.value,
                            ),
                          ),
                          Obx(
                            () =>
                                registrationFee.value > 0
                                    ? Column(
                                      children: [
                                        Divider(
                                          color: AppColors.disabled,
                                          height: 16,
                                        ),
                                        _buildCostRow(
                                          'Registro:',
                                          registrationFee.value,
                                        ),
                                      ],
                                    )
                                    : const SizedBox.shrink(),
                          ),
                          Divider(color: AppColors.disabled, height: 16),
                          Obx(
                            () => _buildCostRow(
                              'Total a pagar:',
                              totalAmount.value,
                              isTotal: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              DateTime now = DateTime.now();
                              DateTime expirationDate = now.add(
                                const Duration(days: 90),
                              );

                              String finalPhoneNumber = phoneController.text;
                              if (!finalPhoneNumber.startsWith('+')) {
                                finalPhoneNumber = '+52$finalPhoneNumber';
                              }

                              final user = UserModel(
                                name: nombreController.text,
                                phone: finalPhoneNumber,
                                membershipType: selectedMembershipType.value,
                                joinDate: isEditing ? now : now,
                                expirationDate: expirationDate,
                                isActive: true,
                                userNumber: userNumberController.text,
                                lastPaymentDate: now,
                              );

                              onSave(user);
                              Get.back();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            backgroundColor: AppColors.accent,
                          ),
                          child: Text(
                            isEditing
                                ? (isRenewing ? 'Renovar' : 'Actualizar')
                                : 'Crear',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
