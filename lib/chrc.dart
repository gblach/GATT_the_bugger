import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'assigned_numbers.dart';
import 'widgets.dart';

class Chrc extends StatefulWidget {
  @override
  _ChrcState createState() => _ChrcState();
}

class _ChrcState extends State<Chrc> {
  ScanResult _result;
  Characteristic _chrc;
  DataType _data_type = DataType.hex;
  StreamSubscription<Uint8List> _notify_sub;
  TextEditingController _write_ctrl = TextEditingController();
  TextEditingController _read_ctrl = TextEditingController();
  TextEditingController _notify_ctrl = TextEditingController();

  @override
  Future<void> didChangeDependencies() async {
    if(_result == null || _chrc == null) {
      List args = ModalRoute.of(context).settings.arguments;
      _result = args[0];
      _chrc = args[1];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() => _data_type = DataType.values[prefs.getInt('data_type') ?? 0]);
    }
    super.didChangeDependencies();
  }

  @override
  Future<void> dispose() async {
    _notify_sub?.cancel();
    super.dispose();
  }

  Future<void> _on_data_type(DataType value) async {
    setState(() => _data_type = value);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('data_type', value.index);
  }

  Future<void> _on_write() async {
    Uint8List data;

    if(_data_type == DataType.hex) {
      List<int> hex_list = [];
      for(int i=0; i<_write_ctrl.text.length; i+=3) {
        hex_list.add(int.parse(_write_ctrl.text[i] + _write_ctrl.text[i+1], radix: 16));
      }
      data = Uint8List.fromList(hex_list);
    } else {
      data = Uint8List.fromList(_write_ctrl.text.codeUnits);
    }

    if(data.length > 0) {
      _result.peripheral.writeCharacteristic(
          _chrc.service.uuid, _chrc.uuid,
          data, _chrc.isWritableWithResponse
      );
    }
  }

  Future<void> _on_read() async {
    CharacteristicWithValue data =
      await _result.peripheral.readCharacteristic(_chrc.service.uuid, _chrc.uuid);

    if(_data_type == DataType.hex) {
      setState(() {
        _read_ctrl.text = '';
        for(int hex in data.value) {
          _read_ctrl.text += hex.toRadixString(16).padLeft(2, '0').padRight(3);
        }
      });
    } else {
      setState(() => _read_ctrl.text = String.fromCharCodes(data.value));
    }
  }

  Future<void> _on_notify() async {
    if(_notify_sub == null) {
      _notify_sub = _chrc.monitor().listen((Uint8List data) {
        if(_data_type == DataType.hex) {
          setState(() {
            _notify_ctrl.text = '';
            for(int hex in data) {
              _notify_ctrl.text += hex.toRadixString(16).padLeft(2, '0').padRight(3);
            }
          });
        } else {
          setState(() => _notify_ctrl.text = String.fromCharCodes(data));
        }
      });
      setState(() => null);
    } else {
      await _notify_sub.cancel();
      setState(() => _notify_sub = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_result.peripheral.name ?? _result.peripheral.identifier),
      ),
      body: build_body(),
    );
  }

  Widget build_body() {
    String service = service_lookup(_chrc.service.uuid);
    service = service != null ? '\n' + service : '';
    String characteristic = characteristic_lookup(_chrc.uuid);
    characteristic = characteristic != null ? '\n' + characteristic : '';

    return Column(children: [
      build_switches(),
      (_chrc.isWritableWithResponse || _chrc.isWritableWithoutResponse) ? build_write() : SizedBox(),
      _chrc.isReadable ? build_read() : SizedBox(),
      (_chrc.isNotifiable || _chrc.isIndicatable) ? build_notify() : SizedBox(),
      Expanded(child: SizedBox()),
      Divider(height: 0),
      Card(
        child: Column(children: [
          infobar(context, 'Service:', _chrc.service.uuid + service),
          Divider(height: 0),
          infobar(context, 'Characteristic:', _chrc.uuid + characteristic),
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
    return FlatButton(
      child: Row(children: [
        Radio(
          value: value,
          groupValue: _data_type,
          onChanged: _on_data_type,
        ),
        Text(label, style: TextStyle(fontSize: 16)),
      ]),
      padding: EdgeInsets.only(right: 16),
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
            RaisedButton(
              child: Text('Write'),
              textColor: Theme.of(context).textTheme.button.color,
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
            RaisedButton(
              child: Text('Read'),
              textColor: Theme.of(context).textTheme.button.color,
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
            RaisedButton(
              child: Text('Subscribe'),
              textColor: Theme.of(context).textTheme.button.color,
              color: _notify_sub != null ? Colors.indigoAccent[400] : null,
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
