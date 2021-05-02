import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
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
  StreamSubscription? _indexSubscription;

  FlutterBlue? flutterBlue = FlutterBlue.instance;
  late BluetoothCharacteristic binWriteCharacteristic;
  late BluetoothCharacteristic binSizeWriteCharacteristic;
  late BluetoothCharacteristic indexNotifyCharacteristic;
  late BluetoothDevice bluetoothDevice;

  int totalBinSize = 0;
  double _percent = 0.0;

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
  var chunkSize = 512;
  num chunksLength = 0;
  String progressText = "";
  String progressTimeText = "";

  Future<void> readBinFile() async {
    ByteData result = await rootBundle.load('assets/update250.bin');
    Uint8List tmp = result.buffer.asUint8List();
    print("파일 읽은 길이 : ${tmp.length}");
    binDate = tmp;
    var len = binDate.length;
    totalBinSize = len;

    for (var i = 0; i < len; i += chunkSize) {
      var end = (i + chunkSize < len) ? i + chunkSize : len;
      chunks.add(binDate.sublist(i, end));
    }
    print(chunks);
    chunksLength = chunks.length;
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
        if (results.device.name == "UART Service") {
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
                if (bluetoothCharacteristic.uuid.toString().toLowerCase() == "0000ff01-0000-1000-8000-00805f9b34fb") {
                  binWriteCharacteristic = bluetoothCharacteristic;
                } else if (bluetoothCharacteristic.uuid.toString().toLowerCase() ==
                    "0000ff03-0000-1000-8000-00805f9b34fb") {
                  binSizeWriteCharacteristic = bluetoothCharacteristic;
                } else if (bluetoothCharacteristic.uuid.toString().toLowerCase() ==
                    "0000ff02-0000-1000-8000-00805f9b34fb") {
                  indexNotifyCharacteristic = bluetoothCharacteristic;
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
    _indexSubscription?.cancel();

    flutterBlue!.stopScan();
    flutterBlue = null;

    // bleManager.destroyClient();
    super.dispose();
  }

  int startTime = 0;
  int endTime = 0;

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
            // Text(
            //   'You have pushed the button this many times:',
            // ),
            // Text(
            //   '$_counter',
            //   style: Theme.of(context).textTheme.headline4,
            // ),
            MaterialButton(
                color: _deviceConnected ? Colors.red : Colors.grey,
                child: Text("연결 종료"),
                onPressed: () async {
                  if (_deviceConnected) {
                    bluetoothDevice.disconnect();
                  }
                }),
            SizedBox(
              height: 24,
            ),
            ElevatedButton(
                child: Text("Mtu 설정"),
                onPressed: () async {
                  await bluetoothDevice.requestMtu(chunkSize);
                }),

            ElevatedButton(
                child: Text("PSRAM 세팅"),
                onPressed: () async {
                  await binSizeWriteCharacteristic.write([
                    (totalBinSize >> 24) & 0xFF,
                    (totalBinSize >> 16) & 0xFF,
                    (totalBinSize >> 8) & 0xFF,
                    (totalBinSize) & 0xFF,
                    (chunksLength.toInt() >> 24) & 0xFF,
                    (chunksLength.toInt() >> 16) & 0xFF,
                    (chunksLength.toInt() >> 8) & 0xFF,
                    (chunksLength.toInt()) & 0xFF,
                  ]);
                }),

            ElevatedButton(
                child: Text("PSRAM 해제"),
                onPressed: () async {
                  await binSizeWriteCharacteristic.write([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
                }),
            ElevatedButton(
                child: Text("Index Notify"),
                onPressed: () async {
                  await indexNotifyCharacteristic.setNotifyValue(true);
                  _indexSubscription = indexNotifyCharacteristic.value.listen((event) {
                    if (event.length > 0) {
                      print(event);
                      int _index = ((event[3] << 24) & 0xff000000) |
                          ((event[2] << 16) & 0x00ff0000) |
                          ((event[1] << 8) & 0x0000ff00) |
                          (event[0] & 0x000000ff);
                      print("Notify index : $_index");

                      if (_index == chunksLength.toInt()) {
                        print(">>> stop _index == chunksLength.toInt()");
                        endTime = DateTime.now().millisecondsSinceEpoch;
                        print("총 소요시간: ${endTime - startTime}");

                        setState(() {
                          progressTimeText = (endTime - startTime).toString();
                        });
                      } else {
                        binWriteCharacteristic.write(chunks[_index]);
                      }
                      setState(() {
                        _percent = (_index / chunksLength);
                        progressText = "$_index / $chunksLength";
                      });
                    }
                  });
                }),
            ElevatedButton(
                child: Text("보내기"),
                onPressed: () async {
                  startTime = DateTime.now().millisecondsSinceEpoch;
                  await binWriteCharacteristic.write(chunks[0]);
                  // for (int i = 0; i < chunks.length; i++) {
                  //   print("인덱스: $i");
                  //   await Future.delayed(Duration(milliseconds: 10));
                  //   await binWriteCharacteristic.write(chunks[i]);
                  //   setState(() {
                  //     progressText = "$i / $chunksLength";
                  //   });
                  // }
                  // int endTime = DateTime.now().millisecondsSinceEpoch;
                  // print("총 소요시간: ${endTime - startTime}");
                  //
                  // setState(() {
                  //   progressTimeText = (endTime - startTime).toString();
                  // });
                }),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Now/Total: $progressText",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "소요시간(ms): $progressTimeText ms (${chunks.length}조각 $chunkSize) ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "소요시간(분): ${((endTime - startTime) ~/ 1000) ~/ 60} 분",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            CircularPercentIndicator(
              radius: 120.0,
              lineWidth: 12.0,
              percent: _percent,
              center: Text(
                "${(_percent * 100).toStringAsFixed(1)} %",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              progressColor: Colors.green,
            )
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
        child: _deviceConnected ? Icon(Icons.clear) : Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
