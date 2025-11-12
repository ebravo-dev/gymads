import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gymads/core/theme/app_colors.dart';
import '../controllers/membresias_controller.dart';

class MembershipFormDialog extends StatelessWidget {
  final Function onSave;
  final MembresiasController controller;
  final bool isEditing;

  const MembershipFormDialog({
    Key? key,
    required this.onSave,
    required this.controller,
    this.isEditing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Tipo de Membresía' : 'Nuevo Tipo de Membresía',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            controller.clearForm();
            Get.back();
          },
        ),
        actions: [
          Obx(() => TextButton(
            onPressed: controller.isSaving.value ? null : () => onSave(),
            child: controller.isSaving.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isEditing ? 'Actualizar' : 'Guardar',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          )),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo de nombre
                TextFormField(
                  controller: controller.nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Ej: Mensual, Anual, etc.',
                    prefixIcon: const Icon(Icons.badge, color: AppColors.accent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.containerBackground,
                  ),
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]')),
                    LengthLimitingTextInputFormatter(50),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    if (value.trim().length < 3) {
                      return 'Mínimo 3 caracteres';
                    }
                    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(value)) {
                      return 'Solo letras y espacios';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Campo de descripción
                TextFormField(
                  controller: controller.descriptionController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Descripción *',
                    hintText: 'Describe los beneficios o detalles',
                    prefixIcon: const Icon(Icons.description, color: AppColors.accent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.containerBackground,
                    helperText: 'Máximo 200 caracteres',
                    helperStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(200),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es obligatoria';
                    }
                    if (value.trim().length < 10) {
                      return 'Mínimo 10 caracteres';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Campo de precio
                TextFormField(
                  controller: controller.priceController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Precio *',
                    hintText: 'Ej: 199.99',
                    prefixIcon: const Icon(Icons.attach_money, color: AppColors.accent),
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.containerBackground,
                    helperText: 'Solo números - Máximo 2 decimales',
                    helperStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El precio es obligatorio';
                    }
                    if (!RegExp(r'^\d+\.?\d{0,2}$').hasMatch(value)) {
                      return 'Formato inválido';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Debe ser mayor a cero';
                    }
                    if (price > 99999.99) {
                      return 'Precio muy alto';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Campo de duración en días
                TextFormField(
                  controller: controller.durationDaysController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Duración (días) *',
                    hintText: 'Ej: 30, 90, 365',
                    prefixIcon: const Icon(Icons.calendar_today, color: AppColors.accent),
                    suffixText: 'días',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: AppColors.containerBackground,
                    helperText: 'Solo números enteros',
                    helperStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La duración es obligatoria';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(value)) {
                      return 'Solo números enteros';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return 'Debe ser mayor a cero';
                    }
                    if (duration < 7) {
                      return 'Mínimo 7 días';
                    }
                    if (duration > 9999) {
                      return 'Duración muy larga';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Checkbox para membresía activa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.containerBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.2),
                    ),
                  ),
                  child: Obx(() => CheckboxListTile(
                    title: const Text(
                      'Membresía Activa',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'Disponible para nuevos clientes',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: controller.isActiveChecked.value,
                    onChanged: (value) {
                      controller.isActiveChecked.value = value ?? true;
                    },
                    activeColor: AppColors.accent,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  )),
                ),
                
                const SizedBox(height: 16),
                
                // Mensaje de error
                Obx(() => controller.errorMessage.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.errorMessage.value,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
