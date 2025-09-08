import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class AlcoholPage extends StatefulWidget {
  final BluetoothCharacteristic? dataCharacteristic;
  const AlcoholPage({Key? key, this.dataCharacteristic}) : super(key: key);

  @override
  State<AlcoholPage> createState() => _AlcoholPageState();
}

class _AlcoholPageState extends State<AlcoholPage> {
  double alcoholLevel = 0.0;
  StreamSubscription<List<int>>? _subscription;

  @override
  void initState() {
    super.initState();
    if (widget.dataCharacteristic != null) {
      _subscription = widget.dataCharacteristic!.value.listen((value) {
        String data = utf8.decode(value);
        List<String> parts = data.split(',');
        if (parts.isNotEmpty) {
          double? voltage = double.tryParse(parts[0]);
          if (voltage != null) {
            setState(() => alcoholLevel = voltage);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = (alcoholLevel / 3.3).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text("Alcohol Sensor"), backgroundColor: Colors.red[800]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_bar, size: 80, color: Colors.redAccent),
              SizedBox(height: 20),
              Text("${alcoholLevel.toStringAsFixed(2)} V",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              LinearProgressIndicator(value: progress, minHeight: 20, backgroundColor: Colors.grey[300], color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}
