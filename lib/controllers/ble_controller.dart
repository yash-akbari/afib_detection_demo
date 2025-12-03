import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart'; // For snackbar and Colors
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../screens/dashboard_screen.dart'; // Import for navigation
import '../screens/scan_screen.dart';     // Import for navigation

class BleController extends GetxController {
  // Observables
  var scanResults = <BluetoothDevice>[].obs;
  var isScanning = false.obs;
  var connectionStatus = "Disconnected".obs;
  var aiResult = "Waiting for data...".obs;
  var aiResultValue = RxnDouble();
  
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? dataRxChar;
  BluetoothCharacteristic? resultChar;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  
  bool _awaitingResult = false;

  // UUIDs from STM32 Code
  final String serviceUuid = "00000000-000E-11E1-9AB4-0002A5D5C51B";
  final String resultCharUuid = "00000001-000E-11E1-AC36-0002A5D5C51B";
  final String dataRxCharUuid = "00000002-000E-11E1-AC36-0002A5D5C51B";

  // Test Data
  final List<List<int>> testData = [
    [233, 231, 232, 233, 232, 227, 227, 231, 232, 229, 224, 227, 229, 226, 227, 227, 224, 226, 230, 228, 228, 225, 230, 231, 228, 229, 233, 232, 231, 223, 230, 220, 223, 227, 229, 231, 228, 229, 224, 230],
    [174, 110, 121, 98, 144, 117, 145, 128, 196, 138, 110, 218, 144, 115, 135, 138, 140, 113, 105, 114, 103, 130, 142, 181, 193, 115, 116, 116, 121, 118, 125, 165, 122, 126, 154, 126, 136, 208, 116, 89],
    [121, 215, 119, 215, 214, 126, 205, 130, 165, 155, 111, 221, 214, 174, 160, 113, 114, 111, 118, 213, 116, 221, 127, 208, 138, 203, 223, 223, 223, 223, 133, 148, 169, 218, 135, 205, 128, 210, 122, 111],
    [191, 191, 189, 191, 193, 190, 191, 192, 194, 193, 191, 192, 192, 192, 191, 192, 194, 192, 190, 193, 193, 191, 191, 192, 191, 192, 195, 190, 191, 191, 193, 192, 190, 193, 193, 193, 194, 193, 193, 190],
    [217, 216, 217, 221, 221, 218, 217, 221, 222, 221, 219, 217, 222, 223, 219, 220, 219, 223, 221, 218, 220, 222, 223, 222, 218, 220, 222, 221, 219, 217, 219, 221, 218, 217, 215, 219, 221, 218, 214, 218],
    [152, 189, 215, 180, 200, 174, 153, 121, 175, 198, 254, 244, 189, 124, 127, 154, 281, 168, 198, 113, 210, 136, 140, 190, 192, 145, 123, 204, 213, 169, 170, 158, 208, 170, 143, 167, 185, 167, 173, 193],
    [144, 140, 131, 170, 124, 173, 163, 116, 133, 131, 125, 123, 104, 118, 158, 162, 158, 169, 133, 192, 135, 143, 171, 170, 166, 147, 124, 129, 110, 130, 122, 196, 194, 201, 147, 200, 213, 132, 213, 170],
    [221, 158, 111, 181, 119, 141, 140, 160, 134, 191, 116, 170, 200, 182, 113, 121, 178, 136, 145, 160, 120, 201, 165, 146, 129, 179, 173, 131, 173, 181, 110, 96, 164, 123, 205, 116, 189, 123, 106, 173],
    [105, 106, 110, 111, 108, 98, 96, 93, 98, 116, 126, 127, 116, 109, 117, 105, 108, 92, 97, 111, 108, 105, 109, 162, 109, 106, 181, 118, 240, 138, 183, 210, 154, 218, 146, 107, 178, 104, 98, 92],
    [223, 224, 216, 219, 223, 222, 220, 216, 219, 224, 222, 219, 218, 222, 224, 220, 217, 222, 221, 221, 219, 217, 219, 220, 220, 218, 215, 222, 222, 216, 220, 219, 222, 225, 220, 219, 228, 226, 226, 222],
    [180, 161, 184, 167, 130, 188, 129, 193, 171, 120, 132, 210, 158, 179, 149, 126, 118, 113, 174, 127, 129, 177, 206, 142, 171, 188, 141, 167, 120, 174, 169, 143, 191, 123, 120, 158, 178, 166, 164, 122],
    [266, 266, 267, 267, 203, 61, 102, 160, 148, 100, 272, 265, 254, 278, 267, 260, 262, 273, 267, 262, 205, 59, 150, 102, 264, 264, 268, 266, 258, 259, 265, 264, 259, 262, 268, 264, 265, 262, 264, 267],
    [202, 210, 213, 214, 208, 209, 207, 205, 205, 203, 205, 207, 209, 210, 211, 211, 211, 213, 211, 210, 207, 207, 208, 208, 207, 208, 205, 206, 207, 206, 207, 206, 206, 203, 207, 211, 210, 209, 211, 212],
    [105, 112, 116, 160, 97, 119, 126, 108, 104, 121, 89, 174, 113, 107, 103, 105, 108, 114, 88, 85, 87, 96, 138, 109, 135, 139, 118, 93, 83, 117, 106, 95, 96, 162, 133, 93, 87, 126, 167, 93],
    [101, 95, 94, 153, 146, 112, 176, 142, 119, 175, 148, 139, 103, 97, 111, 184, 109, 107, 108, 151, 137, 181, 142, 222, 114, 185, 193, 113, 103, 163, 115, 101, 96, 143, 177, 207, 195, 107, 180, 185],
    [226, 230, 229, 230, 232, 228, 230, 235, 229, 231, 228, 229, 232, 232, 227, 226, 232, 235, 226, 227, 231, 233, 230, 223, 230, 231, 227, 227, 224, 228, 228, 226, 225, 224, 229, 231, 225, 226, 231, 236],
    [133, 139, 122, 116, 112, 118, 111, 127, 194, 218, 132, 123, 217, 137, 144, 119, 125, 129, 183, 149, 134, 193, 152, 196, 154, 198, 153, 201, 157, 136, 173, 158, 204, 156, 196, 234, 228, 144, 210, 230],
    [249, 231, 226, 218, 243, 221, 232, 232, 226, 227, 222, 233, 227, 226, 217, 232, 223, 227, 228, 213, 242, 225, 231, 232, 224, 224, 232, 225, 219, 230, 227, 224, 223, 229, 223, 227, 230, 222, 226, 226],
    [212, 214, 218, 217, 220, 227, 228, 226, 231, 232, 230, 230, 229, 231, 230, 225, 229, 228, 221, 224, 222, 225, 222, 217, 223, 222, 217, 221, 222, 224, 224, 221, 224, 225, 221, 222, 222, 226, 224, 218],
    [183, 184, 180, 176, 167, 175, 172, 161, 157, 157, 198, 181, 130, 185, 194, 186, 177, 173, 178, 171, 180, 171, 179, 173, 180, 183, 181, 173, 173, 176, 132, 165, 224, 178, 171, 179, 132, 151, 219, 129]
  ];

  @override
  void onInit() {
    super.onInit();
    
    // Listen to scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      scanResults.value = results.map((r) => r.device).toList();
    });

    FlutterBluePlus.isScanning.listen((state) {
      isScanning.value = state;
    });

    startScan();
  }
  
  @override
  void onClose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.onClose();
  }

  Future<void> checkPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void startScan() async {
    await checkPermissions();
    scanResults.clear();
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      print("Scan Error: $e");
      Get.snackbar("Scan Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    isScanning.value = false; 
    FlutterBluePlus.stopScan(); // Ensure scan stops
    
    connectionStatus.value = "Connecting...";
    
    try {
      await device.connect(license: License.free);// autoConnect: false is faster usually
      connectedDevice = device;
      connectionStatus.value = "Connected";
      
      // Listen for disconnection
      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
            handleDisconnection();
        }
      });

      await discoverServices(device);
      
      // Navigate only after successful connection setup
      Get.to(() => const DashboardScreen());
      
    } catch (e) {
      connectionStatus.value = "Connection Failed";
      print("Connect Error: $e");
      Get.snackbar("Connection Failed", "Could not connect to ${device.platformName}", snackPosition: SnackPosition.BOTTOM);
      connectedDevice = null;
    }
  }
  
  void handleDisconnection() {
      // Only act if we were actually connected
      if (connectedDevice != null) {
          print("Disconnected from ${connectedDevice!.platformName}");
          connectedDevice = null;
          dataRxChar = null;
          resultChar = null;
          connectionStatus.value = "Disconnected";
          aiResult.value = "Waiting for data...";
          
          // Notify user and navigate back
          Get.snackbar("Disconnected", "Device disconnected. Scanning for devices...", 
             snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orangeAccent, colorText: Colors.white);
             
          // Navigate back to scan screen (remove all other screens)
          Get.offAll(() => const ScanScreen());
          
          // Restart scan
          startScan();
      }
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      // Check for AI Service
      if (service.uuid.toString().toUpperCase() == serviceUuid.replaceFirst("00000000", "1B").replaceAll("-", "").toUpperCase() || 
          service.uuid.toString().toUpperCase().contains("000E-11E1-9AB4")) {
          
        print("Found AI Service");
        for (var characteristic in service.characteristics) {
          String uuid = characteristic.uuid.toString().toUpperCase();
          // Check Result Char
          if (uuid.contains("0001-000E-11E1-AC36") || uuid == resultCharUuid) {
            resultChar = characteristic;
            await resultChar!.setNotifyValue(true);
            resultChar!.lastValueStream.listen((value) {
              parseResult(value);
            });
            print("Found Result Char");
          }
          // Check Data RX Char
          if (uuid.contains("0002-000E-11E1-AC36") || uuid == dataRxCharUuid) {
            dataRxChar = characteristic;
            print("Found Data RX Char");
          }
        }
      }
    }
  }
  
  void parseResult(List<int> value) {
    print("DEBUG: Received Notification: $value");
    _awaitingResult = false; // Clear timeout flag

    if (value.length >= 4) {
      // Parse 4 bytes as Float32 (Little Endian)
      var byteData = ByteData.sublistView(Uint8List.fromList(value));
      double prob = byteData.getFloat32(0, Endian.little);
      
      aiResultValue.value = prob;
      
      if (prob > 0.5) {
        aiResult.value = "AFIB DETECTED!\n(Score: ${prob.toStringAsFixed(2)})";
      } else {
        aiResult.value = "Normal Rhythm\n(Score: ${prob.toStringAsFixed(2)})";
      }
    }
  }

  Future<void> sendRRIntervals(List<double> rrIntervals) async {
    if (dataRxChar == null) {
      aiResult.value = "Error: Device not ready.";
      return;
    }

    _awaitingResult = true;
    aiResult.value = "Sending data & waiting for analysis...";

    String dataString = "";
    for (var val in rrIntervals) {
      int intVal = val.toInt();
      if (intVal > 9999) intVal = 9999;
      if (intVal < 0) intVal = 0;
      
      String formatted = intVal.toString().padLeft(4, '0');
      dataString += "$formatted,";
    }
    
    List<int> bytes = dataString.codeUnits; 

    print("Sending String (${bytes.length} bytes): $dataString");

    int chunkSize = 20;
    try {
      for (int i = 0; i < bytes.length; i += chunkSize) {
        int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        List<int> chunk = bytes.sublist(i, end);
        await dataRxChar!.write(chunk, withoutResponse: true);
        await Future.delayed(const Duration(milliseconds: 50)); 
      }
    } catch (e) {
      print("Error sending data: $e");
      aiResult.value = "Error sending data.";
      _awaitingResult = false;
      return;
    }

    // Timeout Check
    Future.delayed(const Duration(seconds: 20), () {
      if (_awaitingResult) {
        _awaitingResult = false;
        aiResult.value = "Error: Timeout (20s). No response.";
      }
    });
  }
  
  void disconnect() {
    connectedDevice?.disconnect();
    // The listener will handle the state change and navigation
  }
}
