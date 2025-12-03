import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../controllers/ble_controller.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Controller
    final controller = Get.put(BleController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Atrial Fibrillation Scanner"),
        actions: [
          Obx(() => IconButton(
            icon: Icon(controller.isScanning.value ? Icons.stop : Icons.refresh),
            onPressed: () {
              if (controller.isScanning.value) {
                controller.stopScan();
              } else {
                controller.startScan();
              }
            },
          ))
        ],
      ),
      body: Obx(() => ListView.builder(
          itemCount: controller.scanResults.length,
          itemBuilder: (context, index) {
            final device = controller.scanResults[index];
            return ListTile(
              title: Text(device.platformName.isNotEmpty ? device.platformName : "Unknown Device"),
              subtitle: Text(device.remoteId.toString()),
              trailing: ElevatedButton(
                onPressed: () {
                   controller.connect(device);
                },
                child: const Text("Connect"),
              ),
            );
          },
        ),
      ),
    );
  }
}