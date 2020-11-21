import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

Map<int,String> AsgnVendor = {};
Map<String,String> AsgnService = {};
Map<String,String> AsgnCharacteristic = {};
RegExp pattern = RegExp(r'^0000([0-9a-f]{4})-0000-1000-8000-00805f9b34fb$', caseSensitive: false);

Future<void> assigned_numbers_load() async {
  final vendors = await rootBundle.loadString('bluetooth-numbers-database/v1/company_ids.json');
  for(final data in jsonDecode(vendors)) {
    AsgnVendor[data['code']] = data['name'];
  }

  final services = await rootBundle.loadString('bluetooth-numbers-database/v1/service_uuids.json');
  for(final data in jsonDecode(services)) {
    AsgnService[data['uuid']] = data['name'];
  }

  final characteristics = await rootBundle.loadString('bluetooth-numbers-database/v1/characteristic_uuids.json');
  for(final data in jsonDecode(characteristics)) {
    AsgnCharacteristic[data['uuid']] = data['name'];
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
  RegExpMatch match = pattern.firstMatch(uuid);
  if(match != null) uuid = match.group(1);
  uuid = uuid.toUpperCase();
  if(AsgnService.containsKey(uuid)) return AsgnService[uuid];
  return null;
}

String characteristic_lookup(String uuid) {
  RegExpMatch match = pattern.firstMatch(uuid);
  if(match != null) uuid = match.group(1);
  uuid = uuid.toUpperCase();
  if(AsgnCharacteristic.containsKey(uuid)) return AsgnCharacteristic[uuid];
  return null;
}
