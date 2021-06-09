import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'assigned_numbers.dart';
import 'widgets.dart';

class Chrc extends StatefulWidget {
  @override
  _ChrcState createState() => _ChrcState();
}

class _ChrcState extends State<Chrc> {
  late BluetoothDevice _device;
  late BluetoothCharacteristic _chrc;
  DataType _data_type = DataType.hex;
  StreamSubscription<List<int>>? _notify_sub;
  TextEditingController _write_ctrl = TextEditingController();
  TextEditingController _read_ctrl = TextEditingController();
  TextEditingController _notify_ctrl = TextEditingController();

  @override
  Future<void> didChangeDependencies() async {
    List args = ModalRoute.of(context)!.settings.arguments as List;
    _device = args[0];
    _chrc = args[1];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _data_type = DataType.values[prefs.getInt('data_type') ?? 0]);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _chrc.setNotifyValue(false);
    _notify_sub?.cancel();
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
      _chrc.write(value, withoutResponse: _chrc.properties.writeWithoutResponse);
    }
  }

  Future<void> _on_read() async {
    List<int> value = await _chrc.read();

    if(_data_type == DataType.hex) {
      setState(() {
        _read_ctrl.text = '';
        for(int hex in value) {
          _read_ctrl.text += hex.toRadixString(16).padLeft(2, '0').padRight(3);
        }
      });
    } else {
      setState(() => _read_ctrl.text = String.fromCharCodes(value));
    }
  }

  Future<void> _on_notify() async {
    if(_notify_sub == null) {
      _notify_sub = _chrc.value.listen((List<int> value) {
        if(_data_type == DataType.hex) {
          setState(() {
            _notify_ctrl.text = '';
            for(int hex in value) {
              _notify_ctrl.text += hex.toRadixString(16).padLeft(2, '0').padRight(3);
            }
          });
        } else {
          setState(() => _notify_ctrl.text = String.fromCharCodes(value));
        }
      });
      _chrc.setNotifyValue(true);
      setState(() => null);
    } else {
      _chrc.setNotifyValue(false);
      _notify_sub?.cancel();
      setState(() => _notify_sub = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_device.name.isNotEmpty ? _device.name : _device.id.toString())),
      body: build_body(),
    );
  }

  Widget build_body() {
    String service = service_lookup(_chrc.serviceUuid.toString());
    if(service.isNotEmpty) service = '\n' + service;
    String characteristic = characteristic_lookup(_chrc.uuid.toString());
    if(characteristic.isNotEmpty) characteristic = '\n' + characteristic;

    return Column(children: [
      build_switches(),
      (_chrc.properties.write || _chrc.properties.writeWithoutResponse) ? build_write() : SizedBox(),
      _chrc.properties.read ? build_read() : SizedBox(),
      (_chrc.properties.notify || _chrc.properties.indicate) ? build_notify() : SizedBox(),
      Expanded(child: SizedBox()),
      Divider(height: 0),
      Card(
        child: Column(children: [
          infobar(context, 'Service:', _chrc.serviceUuid.toString() + service),
          Divider(height: 0),
          infobar(context, 'Characteristic:', _chrc.uuid.toString() + characteristic),
        ]),
        margin: EdgeInsets.all(0),
      ),
    ]);
  }

  Widget build_switches() {
    return Card(
      child: Row(
        children: [
          build_switch('Hex', DataType.hex),
          build_switch('String', DataType.string),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      color: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.only(top: 24, bottom: 12, left: 8, right: 8),
    );
  }

  Widget build_switch(String label, DataType value) {
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

  Widget build_write() {
    return Card(
      child: Padding(
        child: Row(
          children: [
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
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    );
  }

  Widget build_read() {
    return Card(
      child: Padding(
        child: Row(
          children: [
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
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    );
  }

  Widget build_notify() {
    return Card(
      child: Padding(
        child: Row(
          children: [
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
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    );
  }
}
