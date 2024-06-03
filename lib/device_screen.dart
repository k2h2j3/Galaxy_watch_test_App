import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wear/wear.dart';
import 'list_item.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  // 연결 상태 text
  String stateText = 'Connecting';
  // 연결 버튼 상태
  String connectButtonText = 'Disconnect';
  // 연결 상태
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;
  // 리스너
  StreamSubscription<BluetoothDeviceState>? _stateListener;
  List<BluetoothService> bluetoothService = [];
  Map<String, List<int>> notifyDatas = {};

  @override
  void initState() {
    super.initState();
    _stateListener = widget.device.state.listen((event) {
      debugPrint('event :  $event');
      if (deviceState == event) {
        return;
      }
      setBleConnectionState(event);
    });
    connect();
  }

  @override
  void dispose() {
    _stateListener?.cancel();
    disconnect();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  // 상태 관리
  setBleConnectionState(BluetoothDeviceState event) {
    switch (event) {
      case BluetoothDeviceState.disconnected:
        stateText = 'Disconnected';
        connectButtonText = 'Connect';
        break;
      case BluetoothDeviceState.disconnecting:
        stateText = 'Disconnecting';
        break;
      case BluetoothDeviceState.connected:
        stateText = 'Connected';
        connectButtonText = 'Disconnect';
        notifyDatas.clear();
        break;
      case BluetoothDeviceState.connecting:
        stateText = 'Connecting';
        break;
    }
    deviceState = event;
    setState(() {});
  }

  // 비밀번호 입력
  Future<void> writePassword() async {
    String password = "101010";
    List<int> passwordBytes = List<int>.filled(20, 0);

    for (int i = 0; i < password.length; i++) {
      passwordBytes[i + 1] = password.codeUnitAt(i);
    }

    passwordBytes[0] = 0x01;

    bool characteristicFound = false;

    for (BluetoothService service in bluetoothService) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == "0000fff3-0000-1000-8000-00805f9b34fb") {
          print('식별자확인');
          try {
            await characteristic.write(passwordBytes);
            print('Password written successfully');
            characteristicFound = true;
            break;
          } catch (e) {
            print('Failed to write password: $e');
            return;
          }
        }
      }
      if (characteristicFound) break;
    }

    if (!characteristicFound) {
      print('Failed to find characteristic to write password');
    }
  }

  // 디바이스 연결
  Future<bool> connect() async {
    Future<bool>? returnValue;
    setState(() {
      stateText = 'Connecting';
    });

    await widget.device
        .connect(autoConnect: false)
        .timeout(Duration(milliseconds: 15000), onTimeout: () {
      returnValue = Future.value(false);
      debugPrint('timeout failed');
      setBleConnectionState(BluetoothDeviceState.disconnected);
    }).then((data) async {
      bluetoothService.clear();
      if (returnValue == null) {
        debugPrint('connection successful');
        print('start discover service');
        List<BluetoothService> bleServices = await widget.device.discoverServices();
        setState(() {
          bluetoothService = bleServices;
        });
        for (BluetoothService service in bleServices) {
          print('============================================');
          print('Service UUID: ${service.uuid}');
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.properties.notify && c.descriptors.isNotEmpty) {
              for (BluetoothDescriptor d in c.descriptors) {
                print('BluetoothDescriptor uuid ${d.uuid}');
                if (d.uuid == BluetoothDescriptor.cccd) {
                  print('d.lastValue: ${d.lastValue}');
                }
              }

              if (!c.isNotifying) {
                try {
                  await c.setNotifyValue(true);
                  notifyDatas[c.uuid.toString()] = List.empty();
                  c.value.listen((value) {
                    print('${c.uuid}: $value');
                    setState(() {
                      notifyDatas[c.uuid.toString()] = value;
                    });
                  });
                } catch (e) {
                  print('error ${c.uuid} $e');
                }
              }
            }
          }
        }
        returnValue = Future.value(true);
        await writePassword();
      }
    });

    return returnValue ?? Future.value(false);
  }

  void disconnect() {
    try {
      setState(() {
        stateText = 'Disconnecting';
      });
      widget.device.disconnect();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        title: Text(
          widget.device.name,
          style: TextStyle(fontSize: 10),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: Container(
          alignment: Alignment.center,
          child: IconButton(
            onPressed: () {
              _stateListener?.cancel();
              disconnect();
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.arrow_back, size: 10),
          ),
        ),
        actions: [
          Icon(
            Icons.bluetooth,
            color: deviceState == BluetoothDeviceState.connected ? Colors.white : Colors.grey,
            size: 10,
          ),
        ],
      ),
      body: WatchShape(
        builder: (BuildContext context, WearShape shape, Widget? child) {
          return Container(
            color: Colors.lightBlue[100],
            child: Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          '$stateText',
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                      if (deviceState == BluetoothDeviceState.connecting)
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      if (deviceState != BluetoothDeviceState.connecting)
                        OutlinedButton(
                          onPressed: () {
                            if (deviceState == BluetoothDeviceState.connected) {
                              disconnect();
                            } else if (deviceState == BluetoothDeviceState.disconnected) {
                              connect();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(40, 20), // 버튼의 최소 크기 설정
                          ),
                          child: Text(
                            connectButtonText,
                            style: TextStyle(fontSize: 6),
                          ),
                        ),
                    ],
                  ),
                  if (deviceState == BluetoothDeviceState.connecting || deviceState == BluetoothDeviceState.disconnected)
                    Expanded(
                      child: WatchShape(
                        builder: (BuildContext context, WearShape shape, Widget? child) {
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 4.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.all(8),
                        children: bluetoothService.map((service) {
                          return ListItem(
                            service: service,
                            notifyDatas: notifyDatas,
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}