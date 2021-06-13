import 'dart:async';
import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:location/location.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';
import 'device.dart';
import 'globals.dart';
import 'characteristic.dart';
import 'assigned_numbers.dart';
import 'widgets.dart';

enum ConnStage { connecting, discovering }

class ResultTime {
  ScanResult result;
  DateTime time;
  ResultTime(this.result, this.time);
}

void main() => runApp(App());

class App extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GATT the bugger',
      home: Main(),
      routes: {
        '/device': (BuildContext context) => Device(),
        '/characteristic': (BuildContext context) => Characteristic(),
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
  static const platform = const MethodChannel('pl.blach.gatt_the_bugger/native');
  List<ResultTime> _results = [];
  ConnStage? _conn_stage;
  StreamSubscription<ScanResult>? _scan_sub;
  Timer? _cleanup_timer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(ModalRoute.of(context)!.isCurrent) {
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
    WidgetsBinding.instance!.addObserver(this);
    init_async();
    super.initState();
  }

  Future<void> init_async() async {
    await assigned_numbers_load();
    _start_scan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    _stop_scan();
    super.dispose();
  }

  Future<void> _start_scan() async {
    if(Platform.isAndroid) {
      if(! await FlutterBlue.instance.isOn) {
        await platform.invokeMethod('btenable');
        while(! await FlutterBlue.instance.isOn);
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

    _scan_sub = FlutterBlue.instance.scan(allowDuplicates: true).listen((ScanResult result) {
      final ResultTime result_time = ResultTime(result, DateTime.now());
      int index = _results.indexWhere((ResultTime _result_time) =>
        _result_time.result.device.id == result_time.result.device.id);

      setState(() {
        if(index < 0) _results.add(result_time);
        else _results[index] = result_time;
      });
    });
  }

  void _cleanup(Timer timer) {
    DateTime limit = DateTime.now().subtract(Duration(seconds: 5));
    for(int i = _results.length - 1; i >= 0; i--) {
      if(_results[i].time.isBefore(limit)) setState(() => _results.removeAt(i));
    }
  }

  Future<void> _stop_scan() async {
    _scan_sub?.cancel();
    _cleanup_timer?.cancel();
    await FlutterBlue.instance.stopScan();
    setState(() => _results.clear());
  }

  Future<void> _restart_scan() async {
    if(Platform.isAndroid) {
      setState(() => _results.clear());
    } else {
      await _stop_scan();
      _start_scan();
    }
  }

  Future<void> _goto_device(int index) async {
    late StreamSubscription<BluetoothDeviceState> _conn_sub;
    device = _results[index].result.device;
    _stop_scan();

    setState(() => _conn_stage = ConnStage.connecting);
    await device.connect(autoConnect: false);
    _conn_sub = device.state.listen((BluetoothDeviceState state) {
      if(state == BluetoothDeviceState.disconnected) {
        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    });

    setState(() => _conn_stage = ConnStage.discovering);
    await device.requestMtu(251);
    sleep(Duration(milliseconds: 500));
    services = await device.discoverServices();

    Navigator.pushNamed(context, '/device').whenComplete(() async {
      _conn_sub.cancel();
      await device.disconnect();
      setState(() => _conn_stage = null);
      _start_scan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GATT the bugger'),
        actions: [IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _conn_stage == null ? _restart_scan : null,
        )],
      ),
      body: _build_body(),
    );
  }

  Widget _build_body() {
    switch(_conn_stage) {
      case ConnStage.connecting:
        return loader('Connecting ...', 'Wait while connecting');

      case ConnStage.discovering:
        return loader('Connecting ...', 'Wait while discovering services');

      case null:
        return _results.isEmpty ? _build_intro() : _build_list();
    }
  }

  Widget _build_intro() {
    final screen = MediaQuery.of(context).size;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              child: Material(
                child: WaveWidget(
                  config: CustomConfig(
                    colors: [Colors.white30, Colors.white70],
                    durations: [5000, 7500],
                    heightPercentages: [0.40, 0.40],
                  ),
                  size: Size(double.infinity, double.infinity),
                ),
                clipBehavior: Clip.antiAlias,
                color: Colors.grey[200],
                elevation: 3,
                shape: CircleBorder(),
              ),
              width: screen.width * .80,
              height: screen.width * .80,
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

  Widget _build_list() {
    return RefreshIndicator(
      child: ListView.separated(
        itemCount: _results.length + 1,
        itemBuilder: _build_list_item,
        separatorBuilder: (BuildContext context, int index) => Divider(height: 0),
      ),
      onRefresh: _restart_scan,
    );
  }

  Widget _build_list_item(BuildContext context, int index) {
    if(index == 0) return infobar(context, 'BLE devices', null, Brightness.dark);

    final ScanResult result = _results[index - 1].result;
    String vendor = '';
    if(result.advertisementData.manufacturerData.isNotEmpty) {
      result.advertisementData.manufacturerData.forEach((int id, _) {
        vendor = vendor_lookup(id);
        if(vendor.isNotEmpty) vendor = '\n' + vendor;
      });
    }

    return Card(
      child: ListTile(
        leading: Column(
          children: [Text('${result.rssi.toString()} dB')],
          mainAxisAlignment: MainAxisAlignment.center,
        ),
        title: result.device.name.isNotEmpty
          ? Text(result.device.name)
          : Text('Unnamed', style: TextStyle(color: Theme.of(context).textTheme.caption!.color)),
        subtitle: Text(result.device.id.toString() + vendor, style: TextStyle(height: 1.35)),
        trailing: result.advertisementData.connectable ? Column(
          children: [Icon(Icons.chevron_right)],
          mainAxisAlignment: MainAxisAlignment.center,
        ) : SizedBox(),
        isThreeLine: vendor.isNotEmpty,
        onTap: result.advertisementData.connectable ? () => _goto_device(index-1) : null,
      ),
      margin: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(),
    );
  }
}
