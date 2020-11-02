import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'assigned_numbers.dart';
import 'widgets.dart';

class Srvc extends StatefulWidget {
  @override
  _SrvcState createState() => _SrvcState();
}

class _SrvcState extends State<Srvc> {
  ScanResult _result;
  Map<Service,List<Characteristic>> _services = {};

  @override
  Future<void> didChangeDependencies() async {
    if(_result == null) {
      _result = ModalRoute.of(context).settings.arguments;
      for(Service service in await _result.peripheral.services()) {
        _services[service] = await service.characteristics();
      }
      setState(() => null);
    }
    super.didChangeDependencies();
  }

  void _goto_character(Characteristic chrc) {
    Navigator.pushNamed(context, '/chrc', arguments: [_result, chrc]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_result.peripheral.name ?? _result.peripheral.identifier),
      ),
      body: build_list(),
    );
  }

  Widget build_list() {
    return ListView.builder(
      itemCount: _services.length + 1,
      itemBuilder: build_list_item,
    );
  }

  Widget build_list_item(BuildContext context, int index) {
    if(index == 0) return infobar(context, 'Services & characteristics');

    String service = service_lookup(_services.keys.elementAt(index - 1).uuid);

    List<ListTile> tiles = [
      ListTile(
        title: Text(_services.keys.elementAt(index - 1).uuid),
        subtitle: service != null ? Text(service) : null,
        trailing: Text('srv', style: TextStyle(color: Colors.grey)),
      )
    ];

    for(Characteristic chrc in _services.values.elementAt(index - 1)) {
      String characteristic = characteristic_lookup(chrc.uuid);
      characteristic = characteristic != null ? characteristic + '\n' : '';

      List<String> props = [];
      if(chrc.isWritableWithResponse) props.add('write');
      if(chrc.isWritableWithoutResponse) props.add('write without response');
      if(chrc.isReadable) props.add('read');
      if(chrc.isNotifiable) props.add('notify');
      if(chrc.isIndicatable) props.add('indicate');

      tiles.add(ListTile(
        title: Text(chrc.uuid, style: TextStyle(fontSize: 15)),
        subtitle: Text(characteristic + props.join(', '), style: TextStyle(height: 1.4)),
        trailing: Icon(Icons.chevron_right),
        isThreeLine: characteristic.length > 0,
        contentPadding: EdgeInsets.only(left: 28, right: 16),
        onTap: () => _goto_character(chrc),
      ));
    }

    return Card(
      child: Column(children: tiles),
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(),
    );
  }
}
