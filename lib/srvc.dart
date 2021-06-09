import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'assigned_numbers.dart';
import 'widgets.dart';

class Srvc extends StatefulWidget {
  @override
  _SrvcState createState() => _SrvcState();
}

class _SrvcState extends State<Srvc> {
  late BluetoothDevice _device;
  late List<BluetoothService> _services;

  @override
  void didChangeDependencies() {
    List args = ModalRoute.of(context)!.settings.arguments as List;
    _device = args[0];
    _services = args[1];
    super.didChangeDependencies();
  }

  void _goto_character(BluetoothCharacteristic chrc) {
    Navigator.pushNamed(context, '/chrc', arguments: [_device, chrc]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_device.name.isNotEmpty ? _device.name : _device.id.toString())),
      body: build_list(),
    );
  }

  Widget build_list() {
    return ListView.separated(
      itemCount: _services.length + 1,
      itemBuilder: build_list_item,
      separatorBuilder: (BuildContext context, int index) => Divider(height: 0),
    );
  }

  Widget build_list_item(BuildContext context, int index) {
    if(index == 0) return infobar(context, 'Services & characteristics');

    final BluetoothService srvc = _services[index - 1];
    final String srvc_name = service_lookup(srvc.uuid.toString());

    List<ListTile> tiles = [
      ListTile(
        title: Text(srvc.uuid.toString()),
        subtitle: srvc_name.isNotEmpty ? Text(srvc_name) : null,
        trailing: Text('srv', style: TextStyle(color: Colors.grey)),
      )
    ];

    for(BluetoothCharacteristic chrc in _services[index - 1].characteristics) {
      String chrc_name = characteristic_lookup(chrc.uuid.toString());
      if(chrc_name.isNotEmpty) chrc_name += '\n';

      List<String> props = [];
      if(chrc.properties.write) props.add('write');
      if(chrc.properties.writeWithoutResponse) props.add('write without response');
      if(chrc.properties.read) props.add('read');
      if(chrc.properties.notify) props.add('notify');
      if(chrc.properties.indicate) props.add('indicate');

      tiles.add(ListTile(
        title: Text(chrc.uuid.toString(), style: TextStyle(fontSize: 15)),
        subtitle: Text(chrc_name + props.join(', '), style: TextStyle(height: 1.4)),
        trailing: Icon(Icons.chevron_right),
        isThreeLine: chrc_name.isNotEmpty,
        contentPadding: EdgeInsets.only(left: 28, right: 16),
        onTap: () => _goto_character(chrc),
      ));
    }

    return Card(
      child: Column(children: tiles),
      margin: EdgeInsets.only(bottom: index < _services.length ? 16 : 0),
      shape: RoundedRectangleBorder(),
    );
  }
}
