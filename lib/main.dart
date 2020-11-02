import 'dart:async';
import 'dart:io';
import 'package:circle_wave_progress/circle_wave_progress.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:location/location.dart';
import 'srvc.dart';
import 'chrc.dart';
import 'assigned_numbers.dart';
import 'widgets.dart';

enum Connection { connecting, discovering }

class BleDevice {
  ScanResult result;
  DateTime when;
  BleDevice(this.result, this.when);
}

void main() => runApp(App());

class App extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GATT the bugger',
      home: Main(),
      routes: {
        '/srvc': (BuildContext context) => Srvc(),
        '/chrc': (BuildContext context) => Chrc(),
      },
      theme: app_theme(),
    );
  }
}

class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> with WidgetsBindingObserver {
  BleManager _bleManager = BleManager();
  List<BleDevice> _devices = [];
  Connection _connection = null;
  StreamSubscription<PeripheralConnectionState> _conn_sub;
  Timer _cleanup_timer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(ModalRoute.of(context).isCurrent) {
      switch(state) {
        case AppLifecycleState.paused: _stop_scan(); break;
        case AppLifecycleState.resumed: _start_scan(); break;
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
      }
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    initStateAsync();
    super.initState();
  }

  Future<void> initStateAsync() async {
    await assigned_numbers_load();
    await _bleManager.createClient();
    _start_scan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop_scan();
    _bleManager.destroyClient();
    super.dispose();
  }

  Future<void> _start_scan() async {
    if(Platform.isAndroid) {
      if(await _bleManager.bluetoothState() == BluetoothState.POWERED_OFF) {
        await _bleManager.enableRadio();
      }

      AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
      if(androidInfo.version.sdkInt >= 23) {
        Location location = Location();
        while(await location.hasPermission() != PermissionStatus.granted) {
          await location.requestPermission();
        }
        if(! await location.serviceEnabled()) {
          await location.requestService();
        }
      }

      _cleanup_timer = Timer.periodic(Duration(seconds: 2), _cleanup);
    }

    _bleManager.startPeripheralScan(scanMode: ScanMode.balanced)
      .listen((ScanResult result) {
        BleDevice device = BleDevice(result, DateTime.now());
        int index = _devices.indexWhere((dynamic _device) =>
          _device.result.peripheral.identifier == device.result.peripheral.identifier);

        setState(() {
          if(index < 0) _devices.add(device);
          else _devices[index] = device;
        });
      });
  }

  void _cleanup(Timer timer) {
    DateTime limit = DateTime.now().subtract(Duration(seconds: 5));
    for(int i = _devices.length - 1; i >= 0; i--) {
      if(_devices[i].when.isBefore(limit)) setState(() => _devices.removeAt(i));
    }
  }

  Future<void> _stop_scan() async {
    await _cleanup_timer?.cancel();
    await _bleManager.stopPeripheralScan();
    setState(() => _devices.clear());
  }

  Future<void> _restart_scan() async {
    if(Platform.isAndroid) {
      setState(() => _devices.clear());
    } else {
      await _stop_scan();
      _start_scan();
    }
  }

  Future<void> _goto_device(int index) async {
    ScanResult result = _devices[index].result;
    _stop_scan();

    try {
      setState(() => _connection = Connection.connecting);
      await result.peripheral.connect(refreshGatt: true, timeout: Duration(seconds: 15));
      _conn_sub = result.peripheral.observeConnectionState(completeOnDisconnect: true)
        .listen((PeripheralConnectionState state) {
          if(state == PeripheralConnectionState.disconnected) {
            Navigator.popUntil(context, ModalRoute.withName('/'));
          }
        });
      await result.peripheral.requestMtu(251);

      setState(() => _connection = Connection.discovering);
      await result.peripheral.discoverAllServicesAndCharacteristics();

      Navigator.pushNamed(context, '/srvc', arguments: result).whenComplete(() async {
        _conn_sub?.cancel();
        if(await result.peripheral.isConnected()) {
          result.peripheral.disconnectOrCancelConnection();
        }
        setState(() => _connection = null);
        _start_scan();
      });
    } on BleError {
      _conn_sub?.cancel();
      setState(() => _connection = null);
      _start_scan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GATT the bugger'),
        actions: [IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _connection == null ? _restart_scan : null,
        )],
      ),
      body: build_body(),
    );
  }

  Widget build_body() {
    if(_connection != null) {
      switch(_connection) {
        case Connection.connecting: return loader('Connecting ...', 'Wait while connecting');
        case Connection.discovering: return loader('Connecting ...', 'Wait while discovering services');
      }
    }
    if(_devices.length == 0) return build_intro();
    return build_list();
  }

  Widget build_intro() {
    final screen = MediaQuery.of(context).size;

    return Column(
      children: [
        Stack(
          children: [
            Material(
              child: CircleWaveProgress(
                size: screen.width * .80,
                borderWidth: 10.0,
                backgroundColor: Colors.transparent,
                borderColor: Colors.white,
                waveColor: Colors.white70,
                progress: 50,
              ),
              elevation: 3,
              color: Colors.grey[200],
              shape: CircleBorder(),
            ),
            Opacity(
              child: Padding(
                child: Icon(
                  Icons.bluetooth_searching,
                  color: Colors.indigo,
                  size: screen.width / 2,
                ),
                padding: EdgeInsets.only(left: screen.width / 14),
              ),
              opacity: .90,
            ),
          ],
          alignment: AlignmentDirectional.center,
        ),
        Text(
          'No BLE devices found',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        Padding(
          child: Text(
            'Wait while looking for BLE devices.\nThis should take a few seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4),
          ),
          padding: EdgeInsets.only(bottom: screen.height * .02),
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.stretch,
    );
  }

  Widget build_list() {
    return RefreshIndicator(
      child: ListView.separated(
        itemCount: _devices.length + 1,
        itemBuilder: build_list_item,
        separatorBuilder: (BuildContext context, int index) => Divider(height: 0),
      ),
      onRefresh: _restart_scan,
    );
  }

  Widget build_list_item(BuildContext context, int index) {
    if(index == 0) return infobar(context, 'BLE devices');

    ScanResult result = _devices[index - 1].result;
    String vendor = vendor_loopup(result.advertisementData.manufacturerData);
    vendor = vendor != null ? '\n' + vendor : '';

    return Card(
      child: ListTile(
        leading: Column(
          children: [Text('${result.rssi.toString()} dB')],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
        title: result.peripheral.name != null
          ? Text(result.peripheral.name)
          : Text('Unnamed', style: TextStyle(color: Theme.of(context).textTheme.caption.color)),
        subtitle: Text(result.peripheral.identifier + vendor, style: TextStyle(height: 1.35)),
        trailing: Column(
          children: [Icon(Icons.chevron_right)],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
        isThreeLine: vendor.length > 0,
        onTap: () => _goto_device(index - 1),
      ),
      margin: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(),
    );
  }
}
