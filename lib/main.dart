import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ap_updater/spp_update_page.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_update_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SelectPage(),
    );
  }
}

class SelectPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            title: Text("BLE UPDATE (TEST)"),
            onTap: (){
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => MyHomePage(title: "ble update",)));
            },
          ),
          ListTile(
            title: Text("BLUETOOTH UPDATE (TEST)"),
            onTap: (){
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => SppUpdatePage()));
            },
          )
        ],
      ),
    );
  }
}
