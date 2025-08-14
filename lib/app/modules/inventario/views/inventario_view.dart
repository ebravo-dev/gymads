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
        child: Column(
          children: [
            const Text(
              'Resumen de Inventario',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.inventory_2,
                  'Productos',
                  controller.inventoryStats['totalProducts']?.toString() ?? '0',
                ),
                _buildStatItem(
                  Icons.add_shopping_cart,
                  'Unidades',
                  controller.inventoryStats['totalStock']?.toString() ?? '0',
                ),
                _buildStatItem(
                  Icons.attach_money,
                  'Valor',
                  '\$${controller.inventoryStats['totalValue']?.toStringAsFixed(2) ?? '0.00'}',
                ),
                _buildStatItem(
                  Icons.warning_amber,
                  'Stock Bajo',
                  controller.inventoryStats['lowStockCount']?.toString() ?? '0',
                  isWarning: true,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
  
  Widget _buildStatItem(IconData icon, String title, String value, {bool isWarning = false}) {
    return Column(
      children: [
        Icon(
          icon,
          color: isWarning && int.parse(value) > 0 ? Colors.orange : AppColors.primary,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isWarning && int.parse(value) > 0 ? Colors.orange : Colors.black,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: controller.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
  
  Widget _buildCategoryFilter() {
    return Obx(() {
      final List<String> categoryOptions = ['Todas'];
      categoryOptions.addAll(controller.categories.map((cat) => cat.name).toList());
      
      return Container(
        height: 50,
        margin: const EdgeInsets.only(top: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categoryOptions.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final category = categoryOptions[index];
            final isSelected = category == controller.selectedCategory.value;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.setSelectedCategory(category);
                  }
                },
              ),
            );
          },
        ),
      );
    });
  }
  
  Widget _buildProductList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (controller.filteredProducts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                controller.products.isEmpty
                    ? 'No hay productos en el inventario'
                    : 'No se encontraron productos',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              if (controller.products.isEmpty)
                ElevatedButton.icon(
                  onPressed: () => _showProductDialog(Get.context!),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Producto'),
                ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        itemCount: controller.filteredProducts.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final product = controller.filteredProducts[index];
          return _buildProductCard(product, context);
        },
      );
    });
  }
  
  Widget _buildProductCard(Product product, BuildContext context) {
    final isLowStock = product.stock <= 5;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showProductDetail(product, context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto o placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.inventory_2_outlined),
                      ),
              ),
              const SizedBox(width: 16),
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLowStock)
                          Tooltip(
                            message: 'Stock bajo',
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Precio: \$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory,
                                  size: 14,
                                  color: isLowStock ? Colors.orange : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Stock: ${product.stock}',
                                  style: TextStyle(
                                    color: isLowStock ? Colors.orange : Colors.grey.shade600,
                                    fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                controller.editProduct(product);
                                _showProductDialog(context, isEditing: true);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart, size: 20),
                              onPressed: () => _showTransactionDialog(product, context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showProductDetail(Product product, BuildContext context) {
    controller.loadProductTransactions(product.id);
    
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (product.imageUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.imageUrl!,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 48),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Descripción',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(product.description.isEmpty ? 'Sin descripción' : product.description),
            const SizedBox(height: 16),
            _buildDetailRow('Categoría', product.category),
            _buildDetailRow('SKU', product.sku),
            _buildDetailRow('Código de barras', product.barcode),
            _buildDetailRow('Precio de venta', '\$${product.price.toStringAsFixed(2)}'),
            _buildDetailRow('Precio de costo', '\$${product.costPrice.toStringAsFixed(2)}'),
            _buildDetailRow('Stock actual', '${product.stock} unidades'),
            const SizedBox(height: 16),
            const Text(
              'Historial de Transacciones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (controller.transactions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('No hay transacciones registradas'),
                  ),
                );
              }
              
              return SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: controller.transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = controller.transactions[index];
                    return ListTile(
                      leading: _getTransactionIcon(transaction.type),
                      title: Text(_getTransactionTitle(transaction)),
                      subtitle: Text(
                        '${transaction.transactionDate.day}/${transaction.transactionDate.month}/${transaction.transactionDate.year} - ${transaction.notes}',
                      ),
                      trailing: Text(
                        _getTransactionQuantity(transaction),
                        style: TextStyle(
                          color: _getTransactionColor(transaction.type),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    controller.editProduct(product);
                    Get.back();
                    _showProductDialog(context, isEditing: true);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    _showTransactionDialog(product, context);
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Movimiento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    _showDeleteConfirmation(product);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Icon _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.entrada:
        return Icon(Icons.add_circle, color: Colors.green);
      case TransactionType.salida:
        return Icon(Icons.remove_circle, color: Colors.red);
      case TransactionType.venta:
        return Icon(Icons.shopping_cart, color: Colors.blue);
      case TransactionType.ajuste:
        return Icon(Icons.sync, color: Colors.orange);
    }
  }
  
  String _getTransactionTitle(ProductTransaction transaction) {
    switch (transaction.type) {
      case TransactionType.entrada:
        return 'Entrada de producto';
      case TransactionType.salida:
        return 'Salida de producto';
      case TransactionType.venta:
        return 'Venta';
      case TransactionType.ajuste:
        return 'Ajuste de inventario';
    }
  }
  
  String _getTransactionQuantity(ProductTransaction transaction) {
    switch (transaction.type) {
      case TransactionType.entrada:
        return '+${transaction.quantity}';
      case TransactionType.salida:
      case TransactionType.venta:
        return '-${transaction.quantity}';
      case TransactionType.ajuste:
        return '=${transaction.quantity}';
    }
  }
  
  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.entrada:
        return Colors.green;
      case TransactionType.salida:
      case TransactionType.venta:
        return Colors.red;
      case TransactionType.ajuste:
        return Colors.orange;
    }
  }
  
  void _showProductDialog(BuildContext context, {bool isEditing = false}) {
    controller.resetForm();
    
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final costPriceController = TextEditingController();
    final stockController = TextEditingController();
    final skuController = TextEditingController();
    final barcodeController = TextEditingController();
    
    String selectedCategory = controller.categories.isNotEmpty 
        ? controller.categories.first.name 
        : '';
    
    if (isEditing && controller.currentProduct.value != null) {
      final product = controller.currentProduct.value!;
      nameController.text = product.name;
      descriptionController.text = product.description;
      priceController.text = product.price.toString();
      costPriceController.text = product.costPrice.toString();
      stockController.text = product.stock.toString();
      skuController.text = product.sku;
      barcodeController.text = product.barcode;
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
                  Obx(() {
                    return InkWell(
                      onTap: controller.pickImage,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: controller.productImage.value != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  controller.productImage.value!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : isEditing && controller.currentProduct.value?.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      controller.currentProduct.value!.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.add_a_photo),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Agregar imagen',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_a_photo),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Agregar imagen',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un nombre';
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
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    if (controller.categories.isEmpty) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Categoría *',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => selectedCategory = value,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa una categoría';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: () => _showCategoryDialog(context),
                          ),
                        ],
                      );
                    }
                    
                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: controller.categories.any((c) => c.name == selectedCategory)
                                ? selectedCategory
                                : controller.categories.first.name,
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
                              if (value != null) {
                                selectedCategory = value;
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: () => _showCategoryDialog(context),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Precio venta *',
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: costPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Precio costo *',
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
                      ),
                    ],
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Código de barras',
                      border: OutlineInputBorder(),
                    ),
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
                          'costPrice': costPriceController.text,
                          'stock': stockController.text,
                          'sku': skuController.text,
                          'barcode': barcodeController.text,
                        });
                      }
                    },
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(isEditing ? 'Actualizar' : 'Guardar'),
            );
          }),
        ],
      ),
    );
  }
  
  void _showCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Nueva Categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la categoría *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
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
                      if (nameController.text.isNotEmpty) {
                        controller.saveCategory(
                          nameController.text,
                          descriptionController.text,
                        );
                      } else {
                        Get.snackbar(
                          'Error',
                          'El nombre de la categoría es obligatorio',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Guardar'),
            );
          }),
        ],
      ),
    );
  }
  
  void _showTransactionDialog(Product product, BuildContext context) {
    controller.selectedTransactionType.value = TransactionType.entrada;
    controller.quantityController.clear();
    controller.notesController.clear();
    controller.priceController.clear();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Registrar Movimiento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Producto: ${product.name}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Stock actual: ${product.stock}'),
            const SizedBox(height: 16),
            const Text('Tipo de movimiento:'),
            Obx(() {
              return Row(
                children: [
                  Radio<TransactionType>(
                    value: TransactionType.entrada,
                    groupValue: controller.selectedTransactionType.value,
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedTransactionType.value = value;
                      }
                    },
                  ),
                  const Text('Entrada'),
                  Radio<TransactionType>(
                    value: TransactionType.salida,
                    groupValue: controller.selectedTransactionType.value,
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedTransactionType.value = value;
                      }
                    },
                  ),
                  const Text('Salida'),
                ],
              );
            }),
            Obx(() {
              return Row(
                children: [
                  Radio<TransactionType>(
                    value: TransactionType.venta,
                    groupValue: controller.selectedTransactionType.value,
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedTransactionType.value = value;
                      }
                    },
                  ),
                  const Text('Venta'),
                  Radio<TransactionType>(
                    value: TransactionType.ajuste,
                    groupValue: controller.selectedTransactionType.value,
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedTransactionType.value = value;
                      }
                    },
                  ),
                  const Text('Ajuste'),
                ],
              );
            }),
            const SizedBox(height: 16),
            Obx(() {
              return TextField(
                controller: controller.quantityController,
                decoration: InputDecoration(
                  labelText: 'Cantidad *',
                  border: const OutlineInputBorder(),
                  helperText: controller.selectedTransactionType.value == TransactionType.ajuste
                      ? 'Nuevo stock total'
                      : null,
                ),
                keyboardType: TextInputType.number,
              );
            }),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.selectedTransactionType.value == TransactionType.venta) {
                return Column(
                  children: [
                    TextField(
                      controller: controller.priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio unitario',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
            TextField(
              controller: controller.notesController,
              decoration: const InputDecoration(
                labelText: 'Notas',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
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
                  : () => controller.recordTransaction(product.id, product.name),
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Guardar'),
            );
          }),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(Product product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deactivateProduct(product.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
