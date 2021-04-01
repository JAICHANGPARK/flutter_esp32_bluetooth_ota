
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';


class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _deviceConnected = false;
  late StreamSubscription _scanSubscription;
  StreamSubscription? _stateSubscription;

  FlutterBlue? flutterBlue = FlutterBlue.instance;
  late BluetoothCharacteristic binWriteCharacteristic;
  late BluetoothDevice bluetoothDevice;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  Future getPermission() async {
    if (await Permission.location.request().isGranted) {
      return;
    }
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
    ].request();
    print(statuses[Permission.location]);
  }

  late Uint8List binDate;
  var chunks = [];

  Future<void> readBinFile() async {
    ByteData result = await rootBundle.load('assets/update.bin');
    Uint8List tmp = result.buffer.asUint8List();
    print("파일 읽은 길이 : ${tmp.length}");
    binDate = tmp;
    var len = binDate.length;
    var size = 20;

    for (var i = 0; i < len; i += size) {
      var end = (i + size < len) ? i + size : len;
      chunks.add(binDate.sublist(i, end));
    }
    print(chunks);
    print("chunks길이: ${chunks.length}");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPermission();
    readBinFile().then((value) {
      _scanSubscription = flutterBlue!.scan().listen((results) async {
        // do something with scan results
        print(results.device.name);
        if (results.device.name == "UARTService") {
          print("Device Find");
          bluetoothDevice = results.device;
          await flutterBlue!.stopScan();
          await bluetoothDevice.connect(autoConnect: false);
          setState(() {
            _deviceConnected = true;
          });

          bluetoothDevice.discoverServices().then((value) async {
            for (BluetoothService service in value) {
              print("service: $service");
              for (BluetoothCharacteristic bluetoothCharacteristic in service.characteristics) {
                print("char: ${bluetoothCharacteristic.uuid.toString()}");
                if (bluetoothCharacteristic.uuid.toString().toLowerCase() == "0000ff26-0000-1000-8000-00805f9b34fb") {
                  binWriteCharacteristic = bluetoothCharacteristic;
                }
              }
            }
          });
        }
      });
    });
    // Listen to scan results
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scanSubscription.cancel();
    flutterBlue!.stopScan();
    flutterBlue = null;

    // bleManager.destroyClient();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            MaterialButton(
                child: Text("연결 종료"),
                onPressed: () async {
                  bluetoothDevice.disconnect();
                }),
            SizedBox(
              height: 24,
            ),
            MaterialButton(
                child: Text("보내기"),
                onPressed: () async {
                  for (int i = 0; i < chunks.length; i++) {
                    Future.delayed(Duration(milliseconds: 250), () async{
                      print("인덱스 : $i");
                      await binWriteCharacteristic.write(chunks[i], withoutResponse: true);
                    });
                  }
                }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_deviceConnected) {
            bluetoothDevice.disconnect();
            setState(() {
              _deviceConnected = false;
            });
          }
        },
        tooltip: 'Increment',
        backgroundColor: _deviceConnected ? Colors.green : Colors.red,
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}