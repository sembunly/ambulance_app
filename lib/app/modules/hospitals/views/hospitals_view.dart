import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/hospitals_controller.dart';

class HospitalsView extends GetView<HospitalsController> {
  const HospitalsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HospitalsView'), centerTitle: true),
      body: const Center(
        child: Text('HospitalsView is working', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
