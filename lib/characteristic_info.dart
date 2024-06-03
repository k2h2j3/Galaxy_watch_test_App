import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wearable_app/date_parser.dart';

class CharacteristicInfo extends StatefulWidget {
  final BluetoothService service;
  final Map<String, List<int>> notifyDatas;

  CharacteristicInfo({
    required this.service,
    required this.notifyDatas,
  });

  @override
  _CharacteristicInfoState createState() => _CharacteristicInfoState();
}

class _CharacteristicInfoState extends State<CharacteristicInfo> {
  List<int> prevResultList = List.filled(5, 0);

  @override
  Widget build(BuildContext context) {
    String name = '';
    String properties = '';
    String data = '';
    List<int> datalist = [];
    List<int> resultlist = [];

    for (BluetoothCharacteristic c in widget.service.characteristics) {
      properties = '';
      data = '';
      name += '\t\t${c.uuid}\n';
      datalist = [];

      if (c.properties.write) {
        properties += 'Write ';
      }
      if (c.properties.read) {
        properties += 'Read ';
      }
      if (c.properties.notify) {
        properties += 'Notify ';
        if (widget.notifyDatas.containsKey(c.uuid.toString())) {
          if (widget.notifyDatas[c.uuid.toString()]!.isNotEmpty) {
            data = widget.notifyDatas[c.uuid.toString()].toString();
            datalist = parseData(data);
            resultlist.add((datalist[2].toUnsigned(16) << 8) + datalist[3].toUnsigned(16));
            resultlist.add((datalist[4].toUnsigned(16) << 8) + datalist[5].toUnsigned(16));
            resultlist.add((datalist[6].toUnsigned(16) << 8) + datalist[7].toUnsigned(16));
            resultlist.add((datalist[8].toUnsigned(16) << 8) + datalist[9].toUnsigned(16));
            resultlist.add((datalist[10].toUnsigned(16) << 8) + datalist[11].toUnsigned(16));
          }
        }
      }
      if (c.properties.writeWithoutResponse) {
        properties += 'WriteWR ';
      }
      if (c.properties.indicate) {
        properties += 'Indicate ';
      }
      name += '\t\t\tProperties: $properties\n';
      if (data.isNotEmpty) {
        name += '\t\t\t\t$data\n';
      }
    }

    if (resultlist.isEmpty) {
      return Container();
    }

    List<Widget> dataWidgets = [];
    int temperatureIndex = 0; // 온도에 해당하는 인덱스

    if (resultlist.length > temperatureIndex) {
      double currentValue = resultlist[temperatureIndex] / 100;
      double prevValue = prevResultList[temperatureIndex] / 100;
      double diff = currentValue - prevValue;
      String arrow = (diff > 0)
          ? '▲'
          : (diff < 0)
          ? '▼'
          : '━';
      Color diffColor = (diff > 0)
          ? Colors.red
          : (diff < 0)
          ? Colors.blue
          : Colors.grey;

      dataWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                  padding: EdgeInsets.all(1),
                  child: Icon(Icons.thermostat, size: 24, color: Colors.red),
                ),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$currentValue',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 3),
                        Text(
                          '°C',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    prevResultList = resultlist;

    return Container(
      color: Colors.lightBlue[100],
      child: Padding(
        padding: const EdgeInsets.only(left: 3.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...dataWidgets,
          ],
        ),
      ),
    );
  }
}