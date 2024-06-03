import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'characteristic_info.dart';

// 전처리 된 데이터 리스트화
class ListItem extends StatelessWidget {
  final BluetoothService service;
  final Map<String, List<int>> notifyDatas;

  ListItem({
    required this.service,
    required this.notifyDatas,
  });

  @override
  Widget build(BuildContext context) {
    return CharacteristicInfo(
      service: service,
      notifyDatas: notifyDatas,
    );
  }
}