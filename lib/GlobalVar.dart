import 'dart:io';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';
import 'package:zawgyi_converter/zawgyi_converter.dart';

enum ConfirmAction { CANCEL, ACCEPT }
final String appTitle = "Minna Kotoba 2";
final List<String> listJapanese = ['Kana', 'Kanji', 'Romaji'],
    listMeaning = ['Myanmar', 'English'],
    listMemorizing = ['Meaning', 'Japanese'],
    listTtsSource = ['TTS Engine', 'JapanesePod101'];
final ZawgyiConverter zawgyiConverter = ZawgyiConverter();


bool isZawgyi() {
  return PrefService.getBool("switch_zawgyi") ?? false;
}

String getAppId() {
  if (Platform.isIOS) {
    return 'ca-app-pub-3940256099942544~1458002511';
  } else if (Platform.isAndroid) {
    return 'ca-app-pub-3940256099942544~3347511713';
  }
  return null;
}

String getBannerAdUnitId() {
  if (Platform.isIOS) {
    return 'ca-app-pub-3940256099942544/2934735716';
  } else if (Platform.isAndroid) {
    return 'ca-app-pub-3940256099942544/6300978111';
  }
  return null;
}

Widget getAdmobBanner() {
  return Positioned(
      bottom: 16.0,
      left: 8.0,
      child: AdmobBanner(
        adUnitId: getBannerAdUnitId(),
        adSize: AdmobBannerSize.BANNER,
      )
  );
}