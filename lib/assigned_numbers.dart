import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:grizzly_io/io_loader.dart';

Map<int,String> AsgnVendor = {};
Map<int,String> AsgnService = {};
Map<int,String> AsgnCharacteristic = {};

Future<void> assigned_numbers_load() async {
  for(List data in await parseCsv(await rootBundle.loadString('assets/vendors.csv'))) {
    AsgnVendor[int.parse(data[0])] = data[1];
  }

  for(List data in await parseCsv(await rootBundle.loadString('assets/services.csv'))) {
    AsgnService[int.parse(data[0])] = data[1];
  }

  for(List data in await parseCsv(await rootBundle.loadString('assets/characteristics.csv'))) {
    AsgnCharacteristic[int.parse(data[0])] = data[1];
  }
}

String vendor_loopup(Uint8List data) {
  if(data != null) {
    final int id = data[0] + (data[1] << 8);
    if(AsgnVendor.containsKey(id)) return AsgnVendor[id];
  }
  return null;
}

String service_lookup(String uuid) {
  RegExp pattern = new RegExp(r'^0000([0-9a-f]{4})-0000-1000-8000-00805f9b34fb$', caseSensitive: false);
  RegExpMatch match = pattern.firstMatch(uuid);
  if(match != null) {
    final int id = int.parse(match.group(1), radix: 16);
    if(AsgnService.containsKey(id)) return AsgnService[id];
  }
  return null;
}

String characteristic_lookup(String uuid) {
  RegExp pattern = new RegExp(r'^0000([0-9a-f]{4})-0000-1000-8000-00805f9b34fb$', caseSensitive: false);
  RegExpMatch match = pattern.firstMatch(uuid);
  if(match != null) {
    final int id = int.parse(match.group(1), radix: 16);
    if(AsgnCharacteristic.containsKey(id)) return AsgnCharacteristic[id];
  }
  return null;
}
