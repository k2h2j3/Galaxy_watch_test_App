import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wakelock/wakelock.dart';
import 'package:wear/wear.dart';
import 'device_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final title = 'BLE Scan & Connection';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      theme: ThemeData(
        textTheme: TextTheme(
          bodyText2: TextStyle(fontSize: 12),
        ),
      ),
      home: MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResultList = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // 화면보호기
    Wakelock.enable();
    initBle();
    startScan();
  }

  void initBle() {
    flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
      setState(() {});
    });
  }

  void startScan() async {
    // 스캔리스트 초기화
    scanResultList.clear();

    // 스캔
    flutterBlue.startScan();

    // 'XMW' 붙은 디바이스 필터링
    flutterBlue.scanResults.listen((results) {
      results.forEach((element) {
        if (element.device.name.startsWith('XMW')) {
          if (scanResultList.indexWhere((e) => e.device.id == element.device.id) < 0) {
            scanResultList.add(element);
          }
        }
      });
      setState(() {});
    });
  }

  // 신호세기 위젯
  Widget deviceSignal(ScanResult r) {
    return Text(r.rssi.toString());
  }

  // Mac 주소 위젯
  Widget deviceMacAddress(ScanResult r) {
    return Text(r.device.id.id);
  }

  // 디바이스 이름 위젯
  Widget deviceName(ScanResult r) {
    String name = '';

    if (r.device.name.isNotEmpty) {
      name = r.device.name;
    } else if (r.advertisementData.localName.isNotEmpty) {
      name = r.advertisementData.localName;
    } else {
      name = 'N/A';
    }
    return Text(name);
  }

  Widget leading(ScanResult r) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: CircleAvatar(
          radius: 12,
          child: Icon(
            Icons.bluetooth,
            color: Colors.white,
            size: 16,
          ),
          backgroundColor: Colors.cyan,
        ),
      ),
    );
  }

  // 감지된 디바이스 누를시 해당 디바이스 스크린으로 이동
  void onTap(ScanResult r) {
    print('${r.device.name}');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceScreen(device: r.device)),
    );
  }

  // 감지된 디바이스 정보 위젯
  Widget listItem(ScanResult r) {
    return ListTile(
      onTap: () => onTap(r),
      leading: leading(r),
      title: Center(child: deviceName(r)),
      subtitle: Center(child: deviceMacAddress(r)),
      trailing: deviceSignal(r),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 10),
        ),
        centerTitle: true,
      ),
      // 스마트워치에 맞게 위젯으로 감싸기
      body: WatchShape(
        builder: (BuildContext context, WearShape shape, Widget? child) {
          return scanResultList.isEmpty
              ? Center(
            child: _isScanning
                ? CircularProgressIndicator()
                : Text('No devices found'),
          )
              : ListView.separated(
            padding: EdgeInsets.all(8),
            itemCount: scanResultList.length,
            itemBuilder: (context, index) {
              return listItem(scanResultList[index]);
            },
            separatorBuilder: (BuildContext context, int index) {
              return Divider();
            },
          );
        },
      ),
    );
  }
}