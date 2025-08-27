import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/data/models/product_model.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:gymads/app/routes/app_pages.dart';
import '../controllers/inventario_controller.dart';

class InventarioView extends GetView<InventarioController> {
  const InventarioView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadProducts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.resetForm();
          Get.toNamed(Routes.PRODUCT_FORM);
        },
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildStatsSection(),
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: _buildProductList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsSection() {
    return Obx(() {
      if (controller.inventoryStats.isEmpty) {
        return const SizedBox.shrink();
      }
      
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        margin: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Productos', '${controller.inventoryStats['totalProducts'] ?? 0}'),
            _buildStatItem('Stock Total', '${controller.inventoryStats['totalStock'] ?? 0}'),
            _buildStatItem('Valor Total', '\$${(controller.inventoryStats['totalValue'] ?? 0.0).toStringAsFixed(2)}'),
          ],
        ),
      );
    });
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          hintStyle: const TextStyle(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search, color: AppColors.accent),
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.accent.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.accent.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
        ),
        onChanged: controller.setSearchQuery,
      ),
    );
  }
  
  Widget _buildCategoryFilter() {
    return Obx(() {
      return Container(
        height: 50,
        margin: const EdgeInsets.all(16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildCategoryChip('Todas'),
            ...controller.categories.map((category) => _buildCategoryChip(category.name)),
          ],
        ),
      );
    });
  }
  
  Widget _buildCategoryChip(String category) {
    return Obx(() {
      final isSelected = controller.selectedCategory.value == category;
      
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(
            category,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            controller.setSelectedCategory(category);
          },
          backgroundColor: AppColors.cardBackground,
          selectedColor: AppColors.accent,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.accent : AppColors.accent.withOpacity(0.3),
            width: 1.5,
          ),
          elevation: isSelected ? 4 : 1,
          shadowColor: AppColors.accent.withOpacity(0.3),
        ),
      );
    });
  }
  
  Widget _buildProductList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
          ),
        );
      }
      
      if (controller.products.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2, size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                'No hay productos registrados',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  controller.resetForm();
                  Get.toNamed(Routes.PRODUCT_FORM);
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar primer producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        itemCount: controller.filteredProducts.length,
        itemBuilder: (context, index) {
          final product = controller.filteredProducts[index];
          return _buildProductCard(product);
        },
      );
    });
  }
  
  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardBackground,
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withOpacity(0.2),
          child: Text(
            product.name.isNotEmpty ? product.name[0].toUpperCase() : 'P',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.description,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: product.stock > 0 ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Stock: ${product.stock}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          onSelected: (value) {
            if (value == 'edit') {
              controller.editProduct(product);
              Get.toNamed(Routes.PRODUCT_FORM, arguments: {'isEditing': true});
            } else if (value == 'transaction') {
              _showTransactionDialog(Get.context!, product);
            } else if (value == 'deactivate') {
              controller.deactivateProduct(product.id);
            } else if (value == 'delete') {
              controller.deleteProduct(product.id);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: AppColors.accent),
                title: Text('Editar', style: TextStyle(color: AppColors.textPrimary)),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'transaction',
              child: ListTile(
                leading: Icon(Icons.sync_alt, color: AppColors.info),
                title: Text('Registrar transacción', style: TextStyle(color: AppColors.textPrimary)),
              ),
            ),
            // Solo mostrar "Desactivar" si hay stock
            if (product.stock > 0)
              const PopupMenuItem<String>(
                value: 'deactivate',
                child: ListTile(
                  leading: Icon(Icons.visibility_off, color: AppColors.warning),
                  title: Text('Desactivar', style: TextStyle(color: AppColors.textPrimary)),
                ),
              ),
            // Siempre mostrar "Eliminar permanentemente"
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: AppColors.error),
                title: Text('Eliminar permanentemente', style: TextStyle(color: AppColors.textPrimary)),
              ),
            ),
          ],
        ),
        onTap: () => _showProductDetail(product),
      ),
    );
  }
  
  void _showProductDetail(Product product) {
    Get.dialog(
      AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Descripción', product.description),
            _buildDetailRow('Categoría', product.category),
            _buildDetailRow('Precio de venta', '\$${product.price.toStringAsFixed(2)}'),
            _buildDetailRow('Stock actual', '${product.stock} unidades'),
            _buildDetailRow('Estado', product.isActive ? 'Activo' : 'Inactivo'),
            _buildDetailRow('Creado', '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.editProduct(product);
              Get.toNamed(Routes.PRODUCT_FORM, arguments: {'isEditing': true});
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showTransactionDialog(BuildContext context, Product product) {
    controller.selectedTransactionType.value = TransactionType.entrada;
    controller.quantityController.clear();
    controller.notesController.clear();
    controller.priceController.clear();
    
    Get.dialog(
      AlertDialog(
        title: Text('Registrar Transacción - ${product.name}'),
        content: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                return DropdownButtonFormField<TransactionType>(
                  value: controller.selectedTransactionType.value,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de transacción',
                    border: OutlineInputBorder(),
                  ),
                  items: TransactionType.values.map((type) {
                    return DropdownMenuItem<TransactionType>(
                      value: type,
                      child: Text(type == TransactionType.entrada ? 'Entrada' : 'Salida'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedTransactionType.value = value;
                    }
                  },
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.quantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requerido';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Cantidad inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio unitario',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.recordTransaction(product.id, product.name);
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }
}
