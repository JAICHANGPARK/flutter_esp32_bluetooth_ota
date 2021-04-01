import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'spp_discovery_page.dart';

class SppUpdatePage extends StatefulWidget {
  @override
  _SppUpdatePageState createState() => _SppUpdatePageState();
}

class _SppUpdatePageState extends State<SppUpdatePage> {
  BluetoothDevice? _selectedDevice;
  late BluetoothConnection _bluetoothConnection;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  late Uint8List binDate;

  var chunks = [];

  Future<void> readBinFile() async {
    ByteData result = await rootBundle.load('assets/update.bin');
    Uint8List tmp = result.buffer.asUint8List();
    print("파일 읽은 길이 : ${tmp.length}");
    binDate = tmp;
    var len = binDate.length;
    var size = 24;

    for (var i = 0; i < len; i += size) {
      var end = (i + size < len) ? i + size : len;
      chunks.add(binDate.sublist(i, end));
    }
    print(chunks);
    print("chunks길이: ${chunks.length}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              ListTile(
                  title: Text("장치 검색"),
                  onTap: () async {
                    final BluetoothDevice? selectedDevice =
                        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => DiscoveryPage()));
                    if (selectedDevice != null) {
                      print('Discovery -> selected ' + selectedDevice.address);
                      _selectedDevice = selectedDevice;
                    } else {
                      print('Discovery -> no device selected');
                    }
                  }),
              ListTile(
                title: Text("장치 연결"),
                onTap: () async {
                  if (_selectedDevice != null) {
                    _bluetoothConnection = await BluetoothConnection.toAddress(_selectedDevice!.address);
                  } else {
                    print("장치 선택 필요");
                  }
                },
              ),
              Divider(
                height: 64,
                color: Colors.black,
              ),
              ListTile(
                title: Text("파일 읽기"),
                onTap: () async {
                  // if(binDate != null){
                  //   if(binDate.length > 0) binDate.clear();
                  // }
                  if (chunks.length > 0) chunks.clear();
                  readBinFile();
                },
              ),
              ListTile(
                title: Text("파일 전송"),
                onTap: () async {
                  for (int i = 0; i < chunks.length; i++) {
                    Future.delayed(Duration(seconds: 1), () async {
                      print("i : ${i} chunks : ${chunks[i]}");
                      _bluetoothConnection.output.add(Uint8List.fromList(chunks[i]));
                      await _bluetoothConnection.output.allSent;
                    });
                  }
                },
              ),
              ListTile(
                title: Text("파일 전송 중지"),
                onTap: () async {},
              ),
              Divider(
                height: 64,
                color: Colors.black,
              ),
              ListTile(
                title: Text("장치 종료"),
                onTap: () async {
                  if (_selectedDevice != null) {
                    _bluetoothConnection.finish();
                    _bluetoothConnection.close();
                  } else {
                    print("장치 선택 필요");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
