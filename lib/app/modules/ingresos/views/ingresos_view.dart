import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/ingresos_controller.dart';

class IngresosView extends GetView<IngresosController> {
  const IngresosView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IngresosView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'IngresosView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
