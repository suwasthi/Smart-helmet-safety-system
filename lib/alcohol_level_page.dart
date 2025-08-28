// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:async';

// class AlcoholLevelPage extends StatefulWidget {
//   final double initialLevel;

//   const AlcoholLevelPage({Key? key, this.initialLevel = 0}) : super(key: key);

//   @override
//   State<AlcoholLevelPage> createState() => _AlcoholLevelPageState();
// }

// class _AlcoholLevelPageState extends State<AlcoholLevelPage> {
//   double alcoholLevel = 0;
//   BluetoothConnection? connection;
//   bool isConnecting = true;
//   bool isConnected = false;

//   final String esp32Address = "EC:E3:34:46:83:4A"; // Replace with your ESP32 MAC
//   Timer? reconnectTimer;

//   @override
//   void initState() {
//     super.initState();
//     alcoholLevel = widget.initialLevel;
//     requestBluetoothPermissions().then((granted) {
//       if (granted) connectToESP32();
//     });
//   }

//   Future<bool> requestBluetoothPermissions() async {
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.location,
//     ].request();

//     bool granted = statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
//         statuses[Permission.bluetoothConnect] == PermissionStatus.granted;

//     if (!granted) {
//       print("❌ Bluetooth permissions not granted!");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Bluetooth permissions are required")),
//       );
//     }

//     return granted;
//   }

//   void connectToESP32() async {
//     setState(() {
//       isConnecting = true;
//     });

//     try {
//       connection = await BluetoothConnection.toAddress(esp32Address);
//       print('✅ Connected to ESP32');

//       setState(() {
//         isConnected = true;
//         isConnecting = false;
//       });

//       connection!.input!.listen((data) {
//         String received = String.fromCharCodes(data).trim();
//         double? newValue = double.tryParse(received);
//         if (newValue != null) updateAlcoholLevel(newValue);
//       }).onDone(() {
//         print('⚠️ Disconnected by remote device');
//         setState(() {
//           isConnected = false;
//           isConnecting = false;
//         });
//         _scheduleReconnect();
//       });
//     } catch (e) {
//       print('❌ Cannot connect: $e');
//       setState(() {
//         isConnecting = false;
//         isConnected = false;
//       });
//       _scheduleReconnect();
//     }
//   }

//   void _scheduleReconnect() {
//     reconnectTimer?.cancel();
//     reconnectTimer = Timer(Duration(seconds: 5), () {
//       print("🔄 Attempting to reconnect...");
//       requestBluetoothPermissions().then((granted) {
//         if (granted) connectToESP32();
//       });
//     });
//   }

//   void updateAlcoholLevel(double newLevel) {
//     setState(() {
//       alcoholLevel = newLevel;
//     });
//   }

//   String getAlcoholStatus(double level) {
//     if (level <= 0.5) return "Safe";
//     if (level <= 2) return "Caution";
//     if (level <= 5) return "Avoid Driving";
//     if (level <= 10) return "Dangerous – Do NOT Ride";
//     return "Critical – Do NOT Ride";
//   }

//   Color getStatusColor(double level) {
//     if (level <= 2) return Colors.green;
//     return Colors.red;
//   }

//   @override
//   void dispose() {
//     reconnectTimer?.cancel();
//     connection?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Alcohol Level Monitor"),
//         backgroundColor: Colors.red[800],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.local_bar, size: 80, color: Colors.redAccent),
//             const SizedBox(height: 20),
//             const Text(
//               "Current Alcohol Level:",
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               isConnecting
//                   ? "Connecting..."
//                   : isConnected
//                       ? "${alcoholLevel.toStringAsFixed(2)} %"
//                       : "Disconnected",
//               style: const TextStyle(
//                 fontSize: 36,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 20),
//             if (isConnected)
//               Text(
//                 getAlcoholStatus(alcoholLevel),
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: getStatusColor(alcoholLevel),
//                 ),
//               ),
//             const SizedBox(height: 30),
//             LinearProgressIndicator(
//               value: alcoholLevel / 100,
//               minHeight: 20,
//               backgroundColor: Colors.grey[300],
//               color: Colors.red,
//             ),
//             const SizedBox(height: 30),
//             if (!isConnected && !isConnecting)
//               ElevatedButton(
//                 onPressed: connectToESP32,
//                 child: Text("Retry Connection"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red[700],
//                   padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class AlcoholLevelPage extends StatefulWidget {
  final double initialLevel;

  const AlcoholLevelPage({Key? key, this.initialLevel = 0}) : super(key: key);

  @override
  State<AlcoholLevelPage> createState() => _AlcoholLevelPageState();
}


class _AlcoholLevelPageState extends State<AlcoholLevelPage> {
  double alcoholLevel = 0;
  bool isConnecting = true;``
  bool isConnected = false;

  final String targetDeviceName = "SmartHelmet-BLE"; // ESP32 name
  final String serviceUUID = "12345678-1234-1234-1234-1234567890ab"; // same as ESP32
  final String charUUID = "abcd1234-5678-90ab-cdef-1234567890ab";   // same as ESP32

  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;

  @override
  void initState() {
    super.initState();
    _startScanAndConnect();
  }

  void _startScanAndConnect() async {
    print("🔍 Scanning for BLE devices...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name == targetDeviceName) {
          print("✅ Found $targetDeviceName, connecting...");
          device = r.device;
          FlutterBluePlus.stopScan();

          await device!.connect();
          setState(() {
            isConnecting = false;
            isConnected = true;
          });

          // Discover services
          List<BluetoothService> services = await device!.discoverServices();
          for (var service in services) {
            if (service.uuid.toString() == serviceUUID) {
              for (var c in service.characteristics) {
                if (c.uuid.toString() == charUUID) {
                  characteristic = c;
                  await characteristic!.setNotifyValue(true);
                  characteristic!.value.listen((value) {
                    if (value.isNotEmpty) {
                      String received = String.fromCharCodes(value).trim();
                      double? newVal = double.tryParse(received);
                      if (newVal != null) {
                        setState(() {
                          alcoholLevel = newVal;
                        });
                      }
                    }
                  });
                  print("📡 Subscribed to alcohol level updates");
                }
              }
            }
          }
        }
      }
    });
  }

  String getAlcoholStatus(double level) {
    if (level <= 0.5) return "Safe";
    if (level <= 2) return "Caution";
    if (level <= 5) return "Avoid Driving";
    if (level <= 10) return "Dangerous – Do NOT Ride";
    return "Critical – Do NOT Ride";
  }

  Color getStatusColor(double level) {
    if (level <= 2) return Colors.green;
    return Colors.red;
  }

  @override
  void dispose() {
    device?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alcohol Level Monitor (BLE)"),
        backgroundColor: Colors.red[800],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_bar, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text(
              isConnecting
                  ? "Connecting..."
                  : isConnected
                      ? "${alcoholLevel.toStringAsFixed(2)} %"
                      : "Disconnected",
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            if (isConnected)
              Text(
                getAlcoholStatus(alcoholLevel),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: getStatusColor(alcoholLevel),
                ),
              ),
            const SizedBox(height: 30),
            LinearProgressIndicator(
              value: alcoholLevel / 100,
              minHeight: 20,
              backgroundColor: Colors.grey[300],
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

