import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'assigned_numbers.dart';
import 'globals.dart';
import 'widgets.dart';

class Device extends StatefulWidget {
  @override
  _DeviceState createState() => _DeviceState();
}

class _DeviceState extends State<Device> {
  void _goto_characteristic(BluetoothCharacteristic c) {
    characteristic = c;
    Navigator.pushNamed(context, '/characteristic');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device_name())),
      body: _build_list(),
    );
  }

  Widget _build_list() {
    return ListView.separated(
      itemCount: services.length + 1,
      itemBuilder: _build_list_item,
      separatorBuilder: (BuildContext context, int index) => Divider(height: 0),
    );
  }

  Widget _build_list_item(BuildContext context, int index) {
    if(index == 0) return infobar(context, 'Services & characteristics', null, Brightness.dark);

    final BluetoothService s = services[index-1];
    final String sname = service_lookup(s.uuid);

    List<ListTile> tiles = [
      ListTile(
        title: Text(s.uuid.toString()),
        subtitle: sname.isNotEmpty ? Text(sname) : null,
      )
    ];

    for(BluetoothCharacteristic c in s.characteristics) {
      String cname = characteristic_lookup(c.uuid);
      if(cname.isNotEmpty) cname += '\n';

      List<String> props = [];
      if(c.properties.write) props.add('write');
      if(c.properties.writeWithoutResponse) props.add('write without response');
      if(c.properties.read) props.add('read');
      if(c.properties.notify) props.add('notify');
      if(c.properties.indicate) props.add('indicate');

      tiles.add(ListTile(
        title: Text(c.uuid.toString(), style: TextStyle(fontSize: 15)),
        subtitle: Text(cname + props.join(', '), style: TextStyle(height: 1.4)),
        trailing: Icon(Icons.chevron_right),
        isThreeLine: cname.isNotEmpty,
        onTap: () => _goto_characteristic(c),
      ));
    }

    return Card(
      child: Column(children: tiles),
      margin: EdgeInsets.only(bottom: index < services.length ? 16 : 0),
      shape: RoundedRectangleBorder(),
    );
  }
}
