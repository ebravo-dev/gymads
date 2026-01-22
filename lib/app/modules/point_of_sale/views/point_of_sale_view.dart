import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/point_of_sale_controller.dart';
import '../../../data/models/product_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/sales_stats_widget.dart';
import '../../../core/utils/snackbar_helper.dart';

class PointOfSaleView extends GetView<PointOfSaleController> {
  const PointOfSaleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        actions: [
          Obx(() => IconButton(
            icon: Badge(
              label: Text('${controller.cartItems.length}'),
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => _showCartModal(context),
          )),
        ],
      ),
      body: SafeArea(
        child: _buildProductsPanel(),
      ),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
        onPressed: () => _showCartModal(context),
        icon: Badge(
          label: Text('${controller.cartItems.length}'),
          backgroundColor: AppColors.accent,
          child: const Icon(Icons.shopping_cart),
        ),
        label: const Text('Ver Carrito'),
        backgroundColor: controller.cartItems.isNotEmpty ? AppColors.accent : AppColors.disabled,
        foregroundColor: AppColors.textPrimary,
      )),
    );
  }

  Widget _buildProductsPanel() {
    return Container(
      color: AppColors.backgroundColor,
      child: Column(
        children: [
          // Widget de estadísticas
          const SalesStatsWidget(),
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: controller.searchProducts,
            ),
          ),
          // Grid de productos
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              
              final products = controller.filteredProducts;
              
              if (products.isEmpty) {
                return Center(
                  child: Text(
                    'No hay productos disponibles',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              
              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                                       constraints.maxWidth > 800 ? 3 : 2;
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(product);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Obx(() {
      // Obtener la cantidad actual del producto en el carrito
      final cartItem = controller.cartItems.firstWhereOrNull(
        (item) => item.productId == product.id,
      );
      final currentQuantity = cartItem?.quantity ?? 0;
      
      return Card(
        elevation: 3,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: currentQuantity > 0 
            ? BorderSide(color: AppColors.accent, width: 2)
            : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => controller.addProductToCart(product),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del producto (placeholder) con badge de cantidad
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.containerBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      // Badge de cantidad en el carrito
                      if (currentQuantity > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$currentQuantity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Nombre del producto
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Precio
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
                // Stock disponible
                Text(
                  'Stock: ${product.stock}',
                  style: TextStyle(
                    fontSize: 12,
                    color: product.stock > 0 ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                // Controles de cantidad
                if (currentQuantity > 0)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.containerBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          color: AppColors.accent,
                          onPressed: () => controller.updateCartItemQuantity(
                            product.id,
                            currentQuantity - 1,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        Text(
                          '$currentQuantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          color: AppColors.accent,
                          onPressed: () => controller.addProductToCart(product),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCartItem(item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${item.unitPrice.toStringAsFixed(2)} c/u',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Controles de cantidad
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: AppColors.accent,
                    onPressed: () => controller.updateCartItemQuantity(
                      item.productId,
                      item.quantity - 1,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: AppColors.accent,
                    onPressed: () => controller.updateCartItemQuantity(
                      item.productId,
                      item.quantity + 1,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            // Total del item
            SizedBox(
              width: 80,
              child: Column(
                children: [
                  Text(
                    '\$${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.accent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () => controller.removeFromCart(item.productId),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Totales
          Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTotalRow('Subtotal:', controller.totalAmount),
              if (controller.taxAmount > 0)
                _buildTotalRow('Impuestos:', controller.taxAmount),
              if (controller.discountAmount > 0)
                _buildTotalRow('Descuento:', -controller.discountAmount),
              Divider(height: 6, color: AppColors.textSecondary.withOpacity(0.3)),
              _buildTotalRow(
                'TOTAL:',
                controller.finalAmount,
                isTotal: true,
              ),
            ],
          )),
          const SizedBox(height: 8),
          // Método de pago
          Obx(() => DropdownButtonFormField<String>(
            value: controller.selectedPaymentMethod,
            dropdownColor: AppColors.cardBackground,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Método de pago',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.containerBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: controller.paymentMethods.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Text(
                  _getPaymentMethodName(method),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.setPaymentMethod(value);
              }
            },
          )),
          const SizedBox(height: 8),
          // Campo de monto recibido (solo para efectivo)
          Obx(() {
            if (controller.selectedPaymentMethod == 'efectivo') {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Monto recibido',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      prefixText: '\$',
                      prefixStyle: const TextStyle(color: AppColors.accent),
                      filled: true,
                      fillColor: AppColors.containerBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0.0;
                      controller.setReceivedAmount(amount);
                    },
                  ),
                  const SizedBox(height: 6),
                  if (controller.changeAmount >= 0)
                    Text(
                      'Cambio: \$${controller.changeAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.clearCart(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.textSecondary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Limpiar', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.canProcessSale() && !controller.isProcessingPayment
                      ? () => _processSale()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: controller.isProcessingPayment
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Procesar Venta', style: TextStyle(fontSize: 14)),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
                color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta_debito':
        return 'Tarjeta de Débito';
      case 'tarjeta_credito':
        return 'Tarjeta de Crédito';
      case 'transferencia':
        return 'Transferencia';
      case 'mixto':
        return 'Mixto';
      default:
        return method;
    }
  }

  void _showCartModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle visual para indicar que se puede deslizar
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header del carrito
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Carrito de Compras',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.textSecondary.withOpacity(0.3)),
            // Contenido del carrito
            Expanded(
              child: _buildCartModalContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartModalContent() {
    return Column(
      children: [
        // Lista de items del carrito
        Expanded(
          child: Obx(() {
            if (controller.cartItems.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Carrito vacío',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Agregar productos para comenzar',
                      style: TextStyle(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.cartItems.length,
              itemBuilder: (context, index) {
                final item = controller.cartItems[index];
                return _buildCartItem(item);
              },
            );
          }),
        ),
        // Panel de totales y pago
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(
              top: BorderSide(
                color: AppColors.textSecondary.withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: _buildPaymentPanel(),
          ),
        ),
      ],
    );
  }

  void _processSale() async {
    final success = await controller.processSale();
    if (success) {
      SnackbarHelper.success(
        'Éxito',
        'Venta procesada correctamente',
      );
    }
  }
}
