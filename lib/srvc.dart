import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'assigned_numbers.dart';
import 'widgets.dart';

class Srvc extends StatefulWidget {
  @override
  _SrvcState createState() => _SrvcState();
}

class _SrvcState extends State<Srvc> {
  Peripheral _device;
  Map<Service,List<Characteristic>> _services = {};

  @override
  Future<void> didChangeDependencies() async {
    if(_device == null) {
      _device = ModalRoute.of(context).settings.arguments;
      for(Service service in await _device.services()) {
        _services[service] = await service.characteristics();
      }
      setState(() => null);
    }
    super.didChangeDependencies();
  }

  void _goto_character(Characteristic chrc) {
    Navigator.pushNamed(context, '/chrc', arguments: [_device, chrc]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_device.name ?? _device.identifier)),
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

    final Service srvc = _services.keys.elementAt(index - 1);
    final String srvc_name = service_lookup(srvc.uuid);

    List<ListTile> tiles = [
      ListTile(
        title: Text(srvc.uuid),
        subtitle: srvc_name != null ? Text(srvc_name) : null,
        trailing: Text('srv', style: TextStyle(color: Colors.grey)),
      )
    ];

    for(Characteristic chrc in _services.values.elementAt(index - 1)) {
      String chrc_name = characteristic_lookup(chrc.uuid);
      chrc_name = chrc_name != null ? chrc_name + '\n' : '';

      List<String> props = [];
      if(chrc.isWritableWithResponse) props.add('write');
      if(chrc.isWritableWithoutResponse) props.add('write without response');
      if(chrc.isReadable) props.add('read');
      if(chrc.isNotifiable) props.add('notify');
      if(chrc.isIndicatable) props.add('indicate');

      tiles.add(ListTile(
        title: Text(chrc.uuid, style: TextStyle(fontSize: 15)),
        subtitle: Text(chrc_name + props.join(', '), style: TextStyle(height: 1.4)),
        trailing: Icon(Icons.chevron_right),
        isThreeLine: chrc_name.length > 0,
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
