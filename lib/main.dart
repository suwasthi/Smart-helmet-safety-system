import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'alcohol_level_page.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';



void main() => runApp(SmartHelmetApp());

class SmartHelmetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Helmet Emergency',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: HospitalPhonePage(),
    );
  }
}

class HospitalPhonePage extends StatefulWidget {
  @override
  _HospitalPhonePageState createState() => _HospitalPhonePageState();
}

class _HospitalPhonePageState extends State<HospitalPhonePage> {
  String _hospitalPhone = '';
  String _statusMessage = '';
  bool _loading = false;
  double? lat, lon;

  @override
  void initState() {
    super.initState();
    requestBluetoothPermissions(); // <--- add this here
  }

  Future<void> _handlePermissions() async {
    var status = await Permission.location.request();
    if (!status.isGranted) {
      setState(() {
        _statusMessage = 'Location permission denied.';
      });
    }
  }

  Future<void> requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
       // some Bluetooth operations require location
    ].request();

    if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
      print("Bluetooth permissions not granted!");
    } else {
      print("Bluetooth permissions granted!");
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      _statusMessage = 'Getting location...';
    });

    try {
      await _handlePermissions();
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      lat = position.latitude;
      lon = position.longitude;

      print("📍 Location acquired: $lat, $lon");

      setState(() {
        _statusMessage = 'Location acquired!';
      });
    } catch (e) {
      print("❌ Error getting location: $e");
      setState(() {
        _statusMessage = 'Error getting location';
        _loading = false;
      });
    }
  }
Future<void> _findNearestHospitalPhone() async {
  if (lat == null || lon == null) {
    setState(() {
      _statusMessage = "Location not available";
    });
    return;
  }

  setState(() {
    _loading = true;
    _statusMessage = "Searching nearest hospital...";
  });

  const apiKey = 'AIzaSyDj0SPu8hkab0sZ2Bj6d-rBcCGwytf6rkI'; // Google Maps API Key
  final nearbyUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lon&radius=5000&type=hospital&key=$apiKey';

  try {
    final nearbyRes = await http.get(Uri.parse(nearbyUrl));
    final nearbyData = json.decode(nearbyRes.body);
    print("✅ Nearby search response: ${nearbyRes.body}");

    if (nearbyData['results'] != null && nearbyData['results'].length > 0) {
      String placeId = nearbyData['results'][0]['place_id'];

      final detailsUrl =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_phone_number&key=$apiKey';

      final detailsRes = await http.get(Uri.parse(detailsUrl));
      final detailsData = json.decode(detailsRes.body);
      print("☎️ Place details response: ${detailsRes.body}");

      String? phone = detailsData['result']?['formatted_phone_number'];
      String? name = detailsData['result']?['name'];

      setState(() {
        _hospitalPhone = phone ?? 'Phone not available';
        _statusMessage = name ?? 'Hospital found';
        _loading = false;
      });
    } else {
      setState(() {
        _hospitalPhone = "";
        _statusMessage = "No hospital found nearby.";
        _loading = false;
      });
    }
  } catch (e) {
    print("❌ Error fetching hospital: $e");
    setState(() {
      _hospitalPhone = "";
      _statusMessage = "Failed to fetch hospital info.";
      _loading = false;
    });
  }
}


  Future<void> _fetchHospitalPhone() async {
    await _getLocation();
    await _findNearestHospitalPhone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Helmet Emergency"),
        backgroundColor: Colors.red[800],
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child:
              _loading
                  ? CircularProgressIndicator()
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_hospital, size: 60, color: Colors.red),
                      SizedBox(height: 20),
                      Text(
                        _statusMessage.isEmpty
                            ? 'Press the button to find help'
                            : _statusMessage,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      if (_hospitalPhone.isNotEmpty)
                        Card(
                          color: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  "Nearest Hospital Phone:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _hospitalPhone,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _fetchHospitalPhone,
                        icon: Icon(Icons.search),
                        label: Text("Find Nearest Hospital"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 16), // optional spacing
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlcoholLevelPage(initialLevel: 0),
                            ),
                          );
                        },
                        icon: Icon(Icons.local_bar),
                        label: Text("View Alcohol Level"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),

                    ],
                  ),
        ),
      ),
    );
  }
}