import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'spp_discovery_page.dart';

class SppUpdatePage extends StatefulWidget {
  @override
  _SppUpdatePageState createState() => _SppUpdatePageState();
}

class _SppUpdatePageState extends State<SppUpdatePage> {
  BluetoothDevice _selectedDevice;
  BluetoothConnection _bluetoothConnection ;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

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
                    final BluetoothDevice selectedDevice =
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
                    await BluetoothConnection.toAddress(_selectedDevice.address);
                  } else {
                    print("장치 선택 필요");
                  }
                },
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
