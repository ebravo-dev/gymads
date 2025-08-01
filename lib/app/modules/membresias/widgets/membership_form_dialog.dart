import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:gymads/core/utils/responsive_utils.dart';
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
    final isTablet = ResponsiveValues.getWidth(context) > 600;
    final dialogWidth = isTablet ? 500.0 : double.infinity;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: isTablet ? 500 : ResponsiveValues.getWidth(context) * 0.9,
          maxHeight: ResponsiveValues.getHeight(context) * 0.8,
        ),
        padding: EdgeInsets.all(ResponsiveValues.getSpacing(context, 
          mobile: 16, 
          tablet: 24, 
          desktop: 32
        )),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título del formulario
            Text(
              isEditing ? 'Editar Tipo de Membresía' : 'Nuevo Tipo de Membresía',
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
              mobile: 16, 
              tablet: 20, 
              desktop: 24
            )),
            
            // Formulario
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: controller.formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo de nombre
                      TextFormField(
                        controller: controller.nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'Ej: Mensual, Anual, etc.',
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: ResponsiveValues.getSpacing(context, 
                        mobile: 16, 
                        tablet: 20, 
                        desktop: 24
                      )),
                      
                      // Campo de descripción
                      TextFormField(
                        controller: controller.descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Describe los beneficios o detalles',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La descripción es obligatoria';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: ResponsiveValues.getSpacing(context, 
                        mobile: 16, 
                        tablet: 20, 
                        desktop: 24
                      )),
                      
                      // Campo de precio
                      TextFormField(
                        controller: controller.priceController,
                        decoration: const InputDecoration(
                          labelText: 'Precio',
                          hintText: 'Ej: 199.99',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El precio es obligatorio';
                          }
                          
                          if (double.tryParse(value) == null) {
                            return 'Ingresa un valor numérico válido';
                          }
                          
                          if (double.parse(value) <= 0) {
                            return 'El precio debe ser mayor a cero';
                          }
                          
                          return null;
                        },
                      ),
                      
                      SizedBox(height: ResponsiveValues.getSpacing(context, 
                        mobile: 16, 
                        tablet: 20, 
                        desktop: 24
                      )),
                      
                      // Campo de duración en días
                      TextFormField(
                        controller: controller.durationDaysController,
                        decoration: const InputDecoration(
                          labelText: 'Duración (días)',
                          hintText: 'Ej: 30, 90, 365',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La duración es obligatoria';
                          }
                          
                          if (int.tryParse(value) == null) {
                            return 'Ingresa un valor numérico válido';
                          }
                          
                          if (int.parse(value) <= 0) {
                            return 'La duración debe ser mayor a cero';
                          }
                          
                          return null;
                        },
                      ),
                      
                      SizedBox(height: ResponsiveValues.getSpacing(context, 
                        mobile: 16, 
                        tablet: 20, 
                        desktop: 24
                      )),
                      
                      // Checkbox para membresía activa
                      Obx(() => CheckboxListTile(
                        title: const Text('Membresía Activa'),
                        value: controller.isActiveChecked.value,
                        onChanged: (value) {
                          controller.isActiveChecked.value = value ?? true;
                        },
                        activeColor: AppColors.titleColor,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      )),
                      
                      SizedBox(height: ResponsiveValues.getSpacing(context, 
                        mobile: 24, 
                        tablet: 32, 
                        desktop: 40
                      )),
                      
                      // Mensaje de error
                      Obx(() => controller.errorMessage.isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      controller.errorMessage.value,
                                      style: const TextStyle(color: Colors.red),
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
            
            SizedBox(height: ResponsiveValues.getSpacing(context, 
              mobile: 16, 
              tablet: 20, 
              desktop: 24
            )),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón cancelar
                TextButton(
                  onPressed: () {
                    controller.clearForm();
                    Get.back();
                  },
                  child: const Text('Cancelar'),
                ),
                
                SizedBox(width: ResponsiveValues.getSpacing(context, 
                  mobile: 8, 
                  tablet: 12, 
                  desktop: 16
                )),
                
                // Botón guardar
                Obx(() => ElevatedButton(
                  onPressed: controller.isSaving.value 
                      ? null 
                      : () => onSave(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.titleColor,
                  ),
                  child: controller.isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(isEditing ? 'Actualizar' : 'Guardar'),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
