import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_blue/flutter_blue.dart';

Map<int,String> AsgnVendor = {};
Map<String,String> AsgnService = {};
Map<String,String> AsgnCharacteristic = {};
final RegExp pattern = RegExp(
  r'^0000([0-9a-f]{4})-0000-1000-8000-00805f9b34fb$', caseSensitive: false);

Future<void> assigned_numbers_load() async {
  final vendors = await rootBundle.loadString(
    'bluetooth-numbers-database/v1/company_ids.json');
  for(final rec in jsonDecode(vendors)) {
    AsgnVendor[rec['code']] = rec['name'];
  }

  final services = await rootBundle.loadString(
    'bluetooth-numbers-database/v1/service_uuids.json');
  for(final rec in jsonDecode(services)) {
    AsgnService[rec['uuid']] = rec['name'];
  }

  final characteristics = await rootBundle.loadString(
    'bluetooth-numbers-database/v1/characteristic_uuids.json');
  for(final rec in jsonDecode(characteristics)) {
    AsgnCharacteristic[rec['uuid']] = rec['name'];
  }
}

String vendor_lookup(int id) {
  if(AsgnVendor.containsKey(id)) return AsgnVendor[id]!;
  return '';
}

String service_lookup(Guid uuid) {
  RegExpMatch? match = pattern.firstMatch(uuid.toString());
  String key = match != null ? match.group(1)! : uuid.toString();
  key = key.toUpperCase();
  if(AsgnService.containsKey(key)) {
    return AsgnService[key]!;
  }
  return '';
}

String characteristic_lookup(Guid uuid) {
  RegExpMatch? match = pattern.firstMatch(uuid.toString());
  String key = match != null ? match.group(1)! : uuid.toString();
  key = key.toUpperCase();
  if(AsgnCharacteristic.containsKey(key)) {
    return AsgnCharacteristic[key]!;
  }
  return '';
}
