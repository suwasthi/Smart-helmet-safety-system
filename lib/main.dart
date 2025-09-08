import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'alcohol_level_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Helmet Emergency',
      theme: ThemeData(primarySwatch: Colors.red),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _statusMessage = '';
  String _hospitalPhone = '';
  bool _loading = false;

  double _latestVoltage = 0.0;
  double? _latitude;
  double? _longitude;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _dataCharacteristic;
  BluetoothCharacteristic? _phoneCharacteristic;
  bool _bleConnected = false;

  StreamSubscription<List<ScanResult>>? _scanSub;
  bool _fetchingHospital = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    scanAndConnect();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> scanAndConnect() async {
    setState(() => _statusMessage = "Scanning for SmartHelmet-BLE...");

    // Start BLE scan using static method
    FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

    // Listen to scan results using static stream
    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        if (r.device.name == "SmartHelmet-BLE") {
          _device = r.device;

          // Stop scanning using static method
          await FlutterBluePlus.stopScan();
          _scanSub?.cancel();

          try {
            await _device!.connect(autoConnect: false);
            List<BluetoothService> services = await _device!.discoverServices();

            for (var s in services) {
              for (var c in s.characteristics) {
                if (c.uuid.toString() ==
                    "abcd1234-5678-90ab-cdef-1234567890ab") {
                  _dataCharacteristic = c;
                  await _dataCharacteristic!.setNotifyValue(true);

                  _dataCharacteristic!.value.listen((value) {
                    String data = utf8.decode(value);
                    List<String> parts = data.split(',');
                    if (parts.length >= 3) {
                      double? voltage = double.tryParse(parts[0]);
                      double? lat = double.tryParse(parts[1]);
                      double? lon = double.tryParse(parts[2]);
                      if (voltage != null && lat != null && lon != null) {
                        setState(() {
                          _latestVoltage = voltage;
                          _latitude = lat;
                          _longitude = lon;
                        });

                        if (!_fetchingHospital) {
                          _fetchingHospital = true;
                          fetchNearestHospital(lat, lon).whenComplete(() {
                            _fetchingHospital = false;
                          });
                        }
                      }
                    }
                  });
                } else if (c.uuid.toString() ==
                    "56781234-1234-1234-1234-1234567890ab") {
                  _phoneCharacteristic = c;
                }
              }
            }

            setState(() {
              _bleConnected = true;
              _statusMessage = "Connected to SmartHelmet-BLE";
            });
          } catch (e) {
            print("BLE connection error: $e");
            setState(() => _statusMessage = "BLE connection failed");
          }
          break; // stop after connecting to one device
        }
      }
    });
  }

  Future<void> fetchNearestHospital(double lat, double lon) async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _statusMessage = "Searching nearest hospital...";
    });

    const apiKey =
        'AIzaSyDj0SPu8hkab0sZ2Bj6d-rBcCGwytf6rkI'; // <-- Replace with your Google Maps API key
    final nearbyUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lon&radius=5000&type=hospital&key=$apiKey';

    try {
      final nearbyRes = await http.get(Uri.parse(nearbyUrl));
      final nearbyData = json.decode(nearbyRes.body);

      if (nearbyData['results'] != null && nearbyData['results'].isNotEmpty) {
        String placeId = nearbyData['results'][0]['place_id'];
        final detailsUrl =
            'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_phone_number&key=$apiKey';
        final detailsRes = await http.get(Uri.parse(detailsUrl));
        final detailsData = json.decode(detailsRes.body);

        String? phone = detailsData['result']?['formatted_phone_number'];
        String? name = detailsData['result']?['name'];

        setState(() {
          _hospitalPhone = phone ?? "Phone not available";
          _statusMessage = name ?? "Hospital found";
          _loading = false;
        });

        if (phone != null && _phoneCharacteristic != null) {
          await _phoneCharacteristic!.write(utf8.encode(phone));
        }
      } else {
        setState(() {
          _hospitalPhone = "";
          _statusMessage = "No hospital found nearby";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Failed to fetch hospital info";
        _loading = false;
      });
      print(e);
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _device?.disconnect();
    super.dispose();
  }

  //   @override
  //   Widget build(BuildContext context) {
  //     return Scaffold(
  //       appBar: AppBar(
  //         title: Text("Smart Helmet Emergency"),
  //         backgroundColor: Colors.red[800],
  //       ),
  //       body: Center(
  //         child: Padding(
  //           padding: const EdgeInsets.all(20),
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Icon(Icons.local_hospital, size: 60, color: Colors.red),
  //               SizedBox(height: 20),
  //               Text(
  //                 _statusMessage.isNotEmpty
  //                     ? _statusMessage
  //                     : "Waiting for data...",
  //                 style: TextStyle(fontSize: 18),
  //                 textAlign: TextAlign.center,
  //               ),
  //               if (_latestVoltage > 0)
  //                 Card(
  //                   child: Padding(
  //                     padding: const EdgeInsets.all(16.0),
  //                     child: Text(
  //                       "Alcohol Voltage: $_latestVoltage V",
  //                       style: TextStyle(fontSize: 18),
  //                     ),
  //                   ),
  //                 ),
  //               SizedBox(height: 20),
  //               if (_hospitalPhone.isNotEmpty)
  //                 ElevatedButton.icon(
  //                   onPressed: () async {
  //                     if (_phoneCharacteristic != null) {
  //                       // Send hospital phone to ESP32 only when button is pressed
  //                       await _phoneCharacteristic!.write(
  //                         utf8.encode(_hospitalPhone),
  //                       );
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         SnackBar(
  //                           content: Text("Hospital number sent to SmartHelmet!"),
  //                         ),
  //                       );
  //                     }
  //                   },
  //                   icon: Icon(Icons.phone),
  //                   label: Text("Call Nearest Hospital: $_hospitalPhone"),
  //                 ),
  //               SizedBox(height: 30),
  //               ElevatedButton.icon(
  //                 onPressed: () {
  //                   if (_dataCharacteristic != null) {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder:
  //                             (_) => AlcoholPage(
  //                               dataCharacteristic: _dataCharacteristic!,
  //                             ),
  //                       ),
  //                     );
  //                   } else {
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       SnackBar(content: Text("BLE device not connected yet.")),
  //                     );
  //                   }
  //                 },
  //                 icon: Icon(Icons.local_bar),
  //                 label: Text("View Alcohol Level"),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     );
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Helmet Emergency"),
        backgroundColor: Colors.red[800],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_hospital, size: 60, color: Colors.red),
              SizedBox(height: 20),
              Text(
                _statusMessage.isNotEmpty
                    ? _statusMessage
                    : "Press the button to find the nearest hospital",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_latitude != null && _longitude != null) {
                    await fetchNearestHospital(_latitude!, _longitude!);
                    if (_phoneCharacteristic != null &&
                        _hospitalPhone.isNotEmpty) {
                      await _phoneCharacteristic!.write(
                        utf8.encode(_hospitalPhone),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Hospital number sent to SmartHelmet!"),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Waiting for helmet data (alcohol level & location)...",
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.phone),
                label: Text("Find Nearest Hospital"),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (_dataCharacteristic != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AlcoholPage(
                              dataCharacteristic: _dataCharacteristic!,
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("BLE device not connected yet.")),
                    );
                  }
                },
                icon: Icon(Icons.local_bar),
                label: Text("View Alcohol Level"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
