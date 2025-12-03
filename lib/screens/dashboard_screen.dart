import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../controllers/ble_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedRowIndex = 0;
  final BleController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Heart Monitor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () {
              controller.disconnect();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "AI Analysis Result:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Reactive Result Container
            Obx(() {
                bool isAfib = controller.aiResult.value.contains("AFIB");
                bool isError = controller.aiResult.value.contains("Error") || controller.aiResult.value.contains("Waiting");
                
                Color bgColor;
                Color textColor;
                IconData icon;
                
                if (isError) {
                    bgColor = Colors.grey.shade200;
                    textColor = Colors.black54;
                    icon = Icons.hourglass_empty;
                } else if (isAfib) {
                    bgColor = Colors.red.shade100;
                    textColor = Colors.red;
                    icon = Icons.warning;
                } else {
                    bgColor = Colors.green.shade100;
                    textColor = Colors.green.shade800;
                    icon = Icons.favorite;
                }

                return Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isError ? Colors.grey : (isAfib ? Colors.red : Colors.green),
                      width: 3,
                    ),
                  ),
                  child: Column(
                    children: [
                       Icon(icon, size: 80, color: textColor),
                      const SizedBox(height: 20),
                      Text(
                        controller.aiResult.value,
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
            }),
            
            const SizedBox(height: 40),
            
            // Row Selector
            DropdownButtonFormField<int>(
              value: _selectedRowIndex,
              decoration: const InputDecoration(
                labelText: "Select Test Data Row",
                border: OutlineInputBorder(),
              ),
              items: List.generate(20, (index) => 
                DropdownMenuItem(
                  value: index,
                  child: Text("Test Row $index"),
                )
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRowIndex = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Get data from controller
                List<int> rawData = controller.testData[_selectedRowIndex];
                // Convert to doubles
                List<double> rrData = rawData.map((e) => e.toDouble()).toList();
                
                controller.sendRRIntervals(rrData);
              },
              child: Text("Send Row $_selectedRowIndex"),
            ),
          ],
        ),
      ),
    );
  }
}