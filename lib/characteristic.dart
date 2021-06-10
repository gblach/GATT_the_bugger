import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'assigned_numbers.dart';
import 'globals.dart';
import 'widgets.dart';

class Characteristic extends StatefulWidget {
  @override
  _CharacteristicState createState() => _CharacteristicState();
}

class _CharacteristicState extends State<Characteristic> {
  DataType _data_type = DataType.hex;
  StreamSubscription<List<int>>? _notify_sub;
  TextEditingController _write_ctrl = TextEditingController();
  TextEditingController _read_ctrl = TextEditingController();
  TextEditingController _notify_ctrl = TextEditingController();

  @override
  Future<void> didChangeDependencies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _data_type = DataType.values[prefs.getInt('data_type') ?? 0]);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _notify_sub?.cancel();
    if(characteristic.properties.notify || characteristic.properties.indicate) {
      characteristic.setNotifyValue(false);
    }
    super.dispose();
  }

  Future<void> _on_data_type(DataType? value) async {
    setState(() => _data_type = value!);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('data_type', value!.index);
  }

  Future<void> _on_write() async {
    List<int> value = [];

    if(_data_type == DataType.hex) {
      for(int i=0; i<_write_ctrl.text.length; i+=3) {
        value.add(int.parse(_write_ctrl.text[i] + _write_ctrl.text[i+1], radix: 16));
      }
    } else {
      value = Uint8List.fromList(_write_ctrl.text.codeUnits);
    }

    if(value.isNotEmpty) {
      characteristic.write(value,
        withoutResponse: characteristic.properties.writeWithoutResponse);
    }
  }

  String _value_to_text(List<int> value) {
    String text = '';
    if(_data_type == DataType.hex) {
      for(int hex in value) {
        text += hex.toRadixString(16).padLeft(2, '0').padRight(3);
      }
    } else {
      text = String.fromCharCodes(value);
    }
    return text;
  }

  Future<void> _on_read() async {
    List<int> value = await characteristic.read();
    setState(() => _read_ctrl.text = _value_to_text(value));
  }

  Future<void> _on_notify() async {
    if(_notify_sub == null) {
      _notify_sub = characteristic.value.listen((List<int> value) {
        setState(() => _notify_ctrl.text = _value_to_text(value));
      });
      characteristic.setNotifyValue(true);
      setState(() => null);
    } else {
      _notify_sub?.cancel();
      characteristic.setNotifyValue(false);
      setState(() => _notify_sub = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device_name())),
      body: _build_body(),
    );
  }

  Widget _build_body() {
    final CharacteristicProperties props = characteristic.properties;
    String sname = service_lookup(characteristic.serviceUuid);
    if(sname.isNotEmpty) sname = '\n' + sname;
    String cname = characteristic_lookup(characteristic.uuid);
    if(cname.isNotEmpty) cname = '\n' + cname;

    return Column(children: [
      _build_switches(),
      (props.write || props.writeWithoutResponse) ? _build_write() : SizedBox(),
      props.read ? _build_read() : SizedBox(),
      (props.notify || props.indicate) ? _build_notify() : SizedBox(),
      Expanded(child: SizedBox()),
      Divider(height: 0),
      Card(
        child: Column(children: [
          infobar(context, 'Service:', characteristic.serviceUuid.toString() + sname),
          Divider(height: 0),
          infobar(context, 'Characteristic:', characteristic.uuid.toString() + cname),
        ]),
        margin: EdgeInsets.all(0),
      ),
    ]);
  }

  Widget _build_switches() {
    return Card(
      child: Row(
        children: [
          _build_switch('Hex', DataType.hex),
          _build_switch('String', DataType.string),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      color: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.only(top: 24, bottom: 12, left: 8, right: 8),
    );
  }

  Widget _build_switch(String label, DataType value) {
    return TextButton(
      child: Row(children: [
        Radio(
          value: value,
          groupValue: _data_type,
          onChanged: _on_data_type,
        ),
        Text(label),
      ]),
      style: TextButton.styleFrom(
        primary: value != _data_type ? Colors.grey[800] : null,
      ),
      onPressed: () => _on_data_type(value),
    );
  }

  Widget _build_button(List<Widget> children) {
    return Card(
      child: Padding(
        child: Row(children: children),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    );
  }

  Widget _build_write() {
    return _build_button([
      Expanded(child: TextField(
        controller: _write_ctrl,
        style: TextStyle(fontFamily: 'monospace'),
        inputFormatters: [HexFormatter(_data_type)],
      )),
      SizedBox(width: 12),
      ElevatedButton(
        child: Text('Write'),
        onPressed: _on_write,
      ),
    ]);
  }

  Widget _build_read() {
    return _build_button([
      ElevatedButton(
        child: Text('Read'),
        onPressed: _on_read,
      ),
      SizedBox(width: 12),
      Expanded(child: TextField(
        controller: _read_ctrl,
        readOnly: true,
        style: TextStyle(fontFamily: 'monospace'),
      )),
    ]);
  }

  Widget _build_notify() {
    return _build_button([
      ElevatedButton(
        child: Text('Subscribe'),
        style: ElevatedButton.styleFrom(
          primary: _notify_sub != null ? Colors.indigoAccent[400] : null,
        ),
        onPressed: _on_notify,
      ),
      SizedBox(width: 12),
      Expanded(child: TextField(
        controller: _notify_ctrl,
        readOnly: true,
        style: TextStyle(fontFamily: 'monospace'),
      )),
    ]);
  }
}
