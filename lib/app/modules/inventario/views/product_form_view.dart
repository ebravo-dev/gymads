import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/core/theme/app_colors.dart';
import '../controllers/inventario_controller.dart';

class ProductFormView extends GetView<InventarioController> {
  const ProductFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map<String, dynamic>? ?? {};
    final bool isEditing = arguments['isEditing'] ?? false;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    
    String selectedCategory = controller.categories.isNotEmpty 
        ? controller.categories.first.name 
        : '';
    
    // Si estamos editando, llenar los campos con los datos del producto actual
    if (isEditing && controller.currentProduct.value != null) {
      final product = controller.currentProduct.value!;
      nameController.text = product.name;
      descriptionController.text = product.description;
      priceController.text = product.price.toString();
      stockController.text = product.stock.toString();
      selectedCategory = product.category;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            controller.resetForm();
            Get.back();
          },
        ),
        actions: [
          Obx(() {
            return TextButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      if (formKey.currentState!.validate()) {
                        controller.saveProduct({
                          'name': nameController.text,
                          'description': descriptionController.text,
                          'category': selectedCategory,
                          'price': priceController.text,
                          'stock': stockController.text,
                        });
                      }
                    },
              child: controller.isLoading.value
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
                      ),
                    ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de información básica
                _buildSectionCard(
                  title: 'Información Básica',
                  icon: Icons.info_outline,
                  children: [
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto *',
                        hintText: 'Ej: Proteína Whey 1kg',
                      prefixIcon: Icon(Icons.shopping_bag, color: AppColors.accent),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el nombre del producto';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Describe las características del producto...',
                      prefixIcon: Icon(Icons.description, color: AppColors.accent),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    return DropdownButtonFormField<String>(
                      value: selectedCategory.isEmpty ? null : selectedCategory,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        prefixIcon: Icon(Icons.category, color: AppColors.accent),
                      ),
                      dropdownColor: AppColors.cardBackground,
                      items: controller.categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.name,
                          child: Text(
                            category.name,
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedCategory = value ?? '';
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor selecciona una categoría';
                        }
                        return null;
                      },
                    );
                  }),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Sección de precios y stock
              _buildSectionCard(
                title: 'Precio y Stock',
                icon: Icons.attach_money,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Precio de venta *',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.monetization_on, color: AppColors.accent),
                            prefixText: '\$',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Precio inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: stockController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Stock inicial *',
                            hintText: '0',
                            prefixIcon: Icon(Icons.inventory, color: AppColors.accent),
                            suffixText: 'unidades',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerido';
                            }
                            final stock = int.tryParse(value);
                            if (stock == null || stock < 0) {
                              return 'Stock inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24), // Espacio al final del formulario
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
