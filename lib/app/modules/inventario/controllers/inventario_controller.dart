import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:gymads/app/data/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import 'package:gymads/app/data/models/product_model.dart';
import 'package:gymads/app/data/repositories/product_repository.dart';

class InventarioController extends GetxController {
  final ProductRepository productRepository = ProductRepository();
  
  // Estado observable para productos
  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxList<ProductCategory> categories = <ProductCategory>[].obs;
  
  // Estado para la búsqueda
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'Todas'.obs;
  
  // Estado para el formulario
  final Rx<Product?> currentProduct = Rx<Product?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool isEditing = false.obs;
  
  // Estadísticas
  final RxMap<String, dynamic> inventoryStats = <String, dynamic>{}.obs;
  
  // Para la imagen
  final Rx<File?> productImage = Rx<File?>(null);
  
  // Para transacciones
  final RxList<ProductTransaction> transactions = <ProductTransaction>[].obs;
  final Rx<TransactionType> selectedTransactionType = TransactionType.entrada.obs;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  
  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadCategories();
    loadInventoryStats();
  }
  
  @override
  void onClose() {
    quantityController.dispose();
    notesController.dispose();
    priceController.dispose();
    super.onClose();
  }
  
  void resetForm() {
    currentProduct.value = null;
    productImage.value = null;
    isEditing.value = false;
    quantityController.clear();
    notesController.clear();
    priceController.clear();
  }
  
  Future<void> loadProducts() async {
    isLoading.value = true;
    try {
      products.value = await productRepository.getAllProducts();
      filterProducts();
    } catch (e) {
      print('Error al cargar productos: $e');
      Get.snackbar(
        'Error',
        'No se pudieron cargar los productos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadCategories() async {
    try {
      categories.value = await productRepository.getAllCategories();
    } catch (e) {
      print('Error al cargar categorías: $e');
    }
  }
  
  Future<void> loadInventoryStats() async {
    try {
      inventoryStats.value = await productRepository.getInventoryStats();
    } catch (e) {
      print('Error al cargar estadísticas: $e');
    }
  }
  
  void filterProducts() {
    if (searchQuery.isEmpty && selectedCategory.value == 'Todas') {
      filteredProducts.value = products;
    } else {
      filteredProducts.value = products.where((product) {
        bool matchesSearch = searchQuery.isEmpty || 
            product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            product.barcode == searchQuery ||
            product.sku.toLowerCase().contains(searchQuery.toLowerCase());
            
        bool matchesCategory = selectedCategory.value == 'Todas' || 
            product.category == selectedCategory.value;
            
        return matchesSearch && matchesCategory;
      }).toList();
    }
  }
  
  void setSearchQuery(String query) {
    searchQuery.value = query;
    filterProducts();
  }
  
  void setSelectedCategory(String category) {
    selectedCategory.value = category;
    filterProducts();
  }
  
  Future<void> saveProduct(Map<String, dynamic> productData) async {
    isLoading.value = true;
    
    try {
      String? imageUrl;
      if (productImage.value != null) {
        imageUrl = await uploadProductImage(productImage.value!);
      }
      
      final now = DateTime.now();
      
      if (isEditing.value && currentProduct.value != null) {
        // Actualizar producto existente
        final updatedProduct = currentProduct.value!.copyWith(
          name: productData['name'],
          description: productData['description'],
          category: productData['category'],
          price: double.parse(productData['price']),
          costPrice: double.parse(productData['costPrice']),
          stock: int.parse(productData['stock']),
          imageUrl: imageUrl ?? currentProduct.value!.imageUrl,
          sku: productData['sku'],
          barcode: productData['barcode'],
          isActive: true,
          updatedAt: now,
        );
        
        final result = await productRepository.updateProduct(updatedProduct);
        
        if (result != null) {
          int index = products.indexWhere((p) => p.id == result.id);
          if (index >= 0) {
            products[index] = result;
            products.refresh();
          }
          
          Get.back();
          Get.snackbar(
            'Éxito',
            'Producto actualizado correctamente',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } else {
        // Crear nuevo producto
        final newProduct = Product(
          id: const Uuid().v4(),
          name: productData['name'],
          description: productData['description'],
          category: productData['category'],
          price: double.parse(productData['price']),
          costPrice: double.parse(productData['costPrice']),
          stock: int.parse(productData['stock']),
          imageUrl: imageUrl,
          sku: productData['sku'],
          barcode: productData['barcode'],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        
        final result = await productRepository.createProduct(newProduct);
        
        if (result != null) {
          products.add(result);
          products.refresh();
          
          Get.back();
          Get.snackbar(
            'Éxito',
            'Producto creado correctamente',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      }
      
      filterProducts();
      loadInventoryStats();
      
    } catch (e) {
      print('Error al guardar producto: $e');
      Get.snackbar(
        'Error',
        'No se pudo guardar el producto',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<String?> uploadProductImage(File file) async {
    isUploading.value = true;
    try {
      final String fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
      final response = await SupabaseService.client
          .storage
          .from('product_images')
          .upload(fileName, file);
      
      if (response.isNotEmpty) {
        final imageUrl = SupabaseService.client
            .storage
            .from('product_images')
            .getPublicUrl(fileName);
        
        return imageUrl;
      }
      return null;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    } finally {
      isUploading.value = false;
    }
  }
  
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      productImage.value = File(image.path);
    }
  }
  
  void editProduct(Product product) {
    currentProduct.value = product;
    isEditing.value = true;
  }
  
  Future<void> deactivateProduct(String productId) async {
    try {
      final result = await productRepository.deactivateProduct(productId);
      
      if (result) {
        products.removeWhere((p) => p.id == productId);
        products.refresh();
        filterProducts();
        loadInventoryStats();
        
        Get.snackbar(
          'Éxito',
          'Producto eliminado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error al eliminar producto: $e');
      Get.snackbar(
        'Error',
        'No se pudo eliminar el producto',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> loadProductTransactions(String productId) async {
    isLoading.value = true;
    try {
      transactions.value = await productRepository.getProductTransactions(productId);
    } catch (e) {
      print('Error al cargar transacciones: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> recordTransaction(String productId, String productName) async {
    if (quantityController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Debes ingresar una cantidad',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    isLoading.value = true;
    try {
      final int quantity = int.parse(quantityController.text);
      final String notes = notesController.text;
      final double unitPrice = priceController.text.isNotEmpty 
          ? double.parse(priceController.text) 
          : 0.0;
      
      final transaction = ProductTransaction(
        id: const Uuid().v4(),
        productId: productId,
        productName: productName,
        type: selectedTransactionType.value,
        quantity: quantity,
        unitPrice: unitPrice,
        notes: notes,
        staffUser: 'Admin', // Esto debería venir del usuario logueado
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      
      final result = await productRepository.recordTransaction(transaction);
      
      if (result) {
        // Recargar el producto y las transacciones
        await loadProducts();
        await loadProductTransactions(productId);
        await loadInventoryStats();
        
        quantityController.clear();
        notesController.clear();
        priceController.clear();
        
        Get.back(); // Cerrar el diálogo
        
        Get.snackbar(
          'Éxito',
          'Transacción registrada correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error al registrar transacción: $e');
      Get.snackbar(
        'Error',
        'No se pudo registrar la transacción',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> saveCategory(String name, String description) async {
    if (name.isEmpty) {
      Get.snackbar(
        'Error',
        'El nombre de la categoría es obligatorio',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    isLoading.value = true;
    try {
      final now = DateTime.now();
      
      final newCategory = ProductCategory(
        id: const Uuid().v4(),
        name: name,
        description: description,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      
      final result = await productRepository.createCategory(newCategory);
      
      if (result != null) {
        categories.add(result);
        categories.refresh();
        
        Get.back();
        Get.snackbar(
          'Éxito',
          'Categoría creada correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error al guardar categoría: $e');
      Get.snackbar(
        'Error',
        'No se pudo guardar la categoría',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
