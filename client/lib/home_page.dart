import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:untitled/mosquitto_manager.dart';

import 'camera.dart';
import 'config.dart';
import 'login_page.dart';
import 'translation_page.dart';

class MyHomePage extends StatefulWidget {
  final MQTTClientManager? manager;

  const MyHomePage({super.key, required this.manager});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<Camera> cameras = [];


  @override
  void initState() {
    super.initState();
    // showCameras = false;
    // cameras = [];
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  TextButton getButtonExit() {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
      ),
      onPressed: () {
        widget.manager?.client.disconnect();
        Navigator.pop(context,
            MaterialPageRoute(builder:
                (context) => LoginPage(manager: widget.manager))
        );
      },
      child: const Text(
          'Выйти',
          style: TextStyle(
              fontSize: 24
          )
      ),
    );
  }

  TextButton getButtonCameraName(String name, MQTTClientManager? manager) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.green,
      ),
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder:
                (context) => TranslationPage(manager: manager, cameraName: name))
        );
      },
      child: Text(
          name,
          style: const TextStyle(
          fontSize: 20
        )
      ),
    );
  }

  List<Widget> getAllCameras() {
    List<Widget> camerasWidgets = [];
    for (var element in cameras) {
      if (element.type == 'online') {
        camerasWidgets.add(
            Row(
              children: [
                SizedBox(
                  width: 50.0,
                  height: 50.0,
                  child: Image.asset(
                      'assets/images/webcam.png',
                      width: 50.0,
                      height: 50.0,
                      fit: BoxFit.fill
                  ),
                ),
                Align(
                    alignment: Alignment.center,
                    child: getButtonCameraName(element.name, widget.manager)
                )
              ],
            )
        );
      }
    }
    //Добавить сообщение о том, что нет доступных камер
    if (camerasWidgets.isEmpty) {
      return const [
        Text(
            'Нет доступных камер',
            style: TextStyle(
                fontSize: 20,
                color: Colors.green
            ),
          )
      ];
    } else {
      return camerasWidgets;
    }
  }

  Widget camerasStateStream() {
    return StreamBuilder(
      stream: widget.manager?.client.updates,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row();
        } else {
          final event = snapshot.data;
          final recMess = event![0].payload as MqttPublishMessage;
          final topic = event[0].topic.split('/');
          if (topic.length == 3) {
            if (topic[2] == 'state') {
              final String message =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
              print('MQTTClient[topic] = ${event[0].topic}');
              print('MQTTClient[message] = $message');
              final cameraName = topic[1];
              final cameraType = message;
              final idx = widget.manager?.cameras.indexWhere((element) =>
              element.name == cameraName);
              if (idx == -1) {
                widget.manager?.cameras.add(Camera(cameraName, t: cameraType));
              } else {
                widget.manager?.cameras
                    .elementAt(idx ?? -1)
                    .type = message;
              }
            }
          }
        return Column(
          children: [const SizedBox(height: 10) , ...getAllCameras()],);
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    cameras = widget.manager?.cameras ?? [];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        title: Center(
          widthFactor: 50,
          child: SizedBox(
            width: 50,
            child: Image.asset('assets/images/title.png')
          )
        ),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: camerasStateStream(),
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: getButtonExit()
    );
  }
}