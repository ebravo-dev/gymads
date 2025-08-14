import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/data/models/product_model.dart';
import 'package:gymads/core/theme/app_colors.dart';
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
        onPressed: () => _showProductDialog(context),
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
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
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
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
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
      final isSelected = controller.selectedCategory.value == category ||
          (category == 'Todas' && controller.selectedCategory.value.isEmpty);
      
      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            controller.setSelectedCategory(category == 'Todas' ? '' : category);
          },
          backgroundColor: Colors.grey.shade200,
          selectedColor: AppColors.primary.withOpacity(0.2),
        ),
      );
    });
  }
  
  Widget _buildProductList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (controller.products.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No hay productos registrados'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showProductDialog(Get.context!),
                icon: const Icon(Icons.add),
                label: const Text('Agregar primer producto'),
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            product.name.isNotEmpty ? product.name[0].toUpperCase() : 'P',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: product.stock > 0 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Stock: ${product.stock}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              controller.editProduct(product);
              _showProductDialog(Get.context!, isEditing: true);
            } else if (value == 'transaction') {
              _showTransactionDialog(Get.context!, product);
            } else if (value == 'deactivate') {
              _showDeactivateDialog(product);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'transaction',
              child: ListTile(
                leading: Icon(Icons.sync_alt),
                title: Text('Registrar transacción'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'deactivate',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Desactivar'),
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
              _showProductDialog(Get.context!, isEditing: true);
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
  
  void _showProductDialog(BuildContext context, {bool isEditing = false}) {
    controller.resetForm();
    
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    
    String selectedCategory = controller.categories.isNotEmpty 
        ? controller.categories.first.name 
        : '';
    
    if (isEditing && controller.currentProduct.value != null) {
      final product = controller.currentProduct.value!;
      nameController.text = product.name;
      descriptionController.text = product.description;
      priceController.text = product.price.toString();
      stockController.text = product.stock.toString();
      selectedCategory = product.category;
    }
    
    Get.dialog(
      AlertDialog(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto *',
                      border: OutlineInputBorder(),
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
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    return DropdownButtonFormField<String>(
                      value: selectedCategory.isEmpty ? null : selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(),
                      ),
                      items: controller.categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.name,
                          child: Text(category.name),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio de venta *',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Número inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock inicial *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el stock';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Número inválido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          Obx(() {
            return ElevatedButton(
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
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isEditing ? 'Actualizar' : 'Crear'),
            );
          }),
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
                      child: Text(type.toString().split('.').last.toUpperCase()),
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
  
  void _showDeactivateDialog(Product product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar desactivación'),
        content: Text('¿Estás seguro de que quieres desactivar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deactivateProduct(product.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desactivar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
