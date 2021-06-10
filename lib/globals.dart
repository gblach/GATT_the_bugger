import 'package:flutter_blue/flutter_blue.dart';

late BluetoothDevice device;
late List<BluetoothService> services;
late BluetoothCharacteristic characteristic;

String device_name() {
  return device.name.isNotEmpty ? device.name : device.id.toString();
}