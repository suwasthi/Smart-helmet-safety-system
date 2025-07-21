# Smart Helmet with Alcohol Detection and Emergency Alert System

## Introduction
This project enhances rider safety by integrating advanced sensors and communication modules into a motorcycle helmet. The smart helmet detects alcohol consumption, verifies helmet usage, and senses crashes. If alcohol is detected, the system disables the vehicle ignition to prevent drunk driving. In case of an accident, it sends the rider's GPS location to a mobile app, which finds the nearest hospital and sends back the contact number. The helmet then automatically calls the hospital via the SIM800L GSM module and optionally sends an emergency SMS to a family member.

## Features
- Alcohol detection to prevent drunk driving by disabling vehicle ignition
- Helmet wearing detection to ensure safety compliance
- Crash detection for immediate emergency response
- GPS location tracking and transmission
- Mobile app integration to locate the nearest hospital
- Automatic calling and SMS alerts via SIM800L GSM module

## How It Works
1. The helmet sensors monitor the rider’s alcohol level, helmet status, and detect collisions.
2. If alcohol is detected, the microcontroller disables the vehicle ignition to prevent drunk driving.
3. Upon detecting a crash, the GPS module provides the rider’s location.
4. The ESP32 sends this location to the mobile app via Bluetooth.
5. The mobile app determines the nearest hospital and sends the hospital’s contact number back to the ESP32.
6. The SIM800L GSM module automatically calls the hospital and sends an optional SMS alert to a family member.

![System Block Diagram](images/block_diagram.png)

## Usage
- Wear the helmet properly to enable all safety features.
- The system will monitor alcohol levels and disable ignition if alcohol is detected.
- In case of an accident, emergency calls and alerts will be triggered automatically.

## 14-Week Project Timeline

| Week | Tasks                                                                                   |
|-------|-----------------------------------------------------------------------------------------|
| 1     | Requirement analysis, literature review, and finalizing components                      |
| 2     | Research and order hardware modules (ESP32, sensors, SIM800L, GPS, etc.)                |
| 3     | Initial setup of microcontroller and sensors; prototype alcohol sensor integration     |
| 4     | Helmet wearing detection implementation and testing                                    |
| 5     | Crash detection sensor setup and data acquisition                                      |
| 6     | GPS module integration and location tracking testing                                  |
| 7     | Develop communication between ESP32 and mobile app via Bluetooth                       |
| 8     | Mobile app development: receive GPS and send hospital contact                          |
| 9     | SIM800L GSM module integration for automatic calls and SMS                            |
| 10    | Implement vehicle ignition control logic (stop on alcohol detection)                   |
| 11    | System integration: combine sensors, communication, and control logic                  |
| 12    | Initial system testing and debugging                                                  |
| 13    | Final testing and validation                                                          |
| 14    | Documentation and project report preparation                                          |
