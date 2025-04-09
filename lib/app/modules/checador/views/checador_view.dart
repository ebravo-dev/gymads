import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/checador_controller.dart';

class ChecadorView extends GetView<ChecadorController> {
  const ChecadorView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChecadorView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'ChecadorView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
