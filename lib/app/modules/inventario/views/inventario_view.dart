import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/inventario_controller.dart';

class InventarioView extends GetView<InventarioController> {
  const InventarioView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InventarioView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'InventarioView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
