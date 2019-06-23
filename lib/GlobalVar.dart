import 'dart:io';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';
import 'package:zawgyi_converter/zawgyi_converter.dart';

enum ConfirmAction { CANCEL, ACCEPT }
final String appTitle = "Minna Kotoba 2";
final String appVersion = "Version 2.0";
final List<String> listJapanese = ['Kana', 'Kanji', 'Romaji'],
    listMeaning = ['Myanmar', 'English'],
    listMemorizing = ['Meaning', 'Japanese'],
    listTtsSource = ['TTS Engine', 'JapanesePod101'],
    searchFlashCardLevel = ['N5', 'N4'];
final ZawgyiConverter zawgyiConverter = ZawgyiConverter();

bool isZawgyi() {
  return PrefService.getBool("switch_zawgyi") ?? false;
}

bool isDarkTheme() {
  return (PrefService.getString('ui_theme') == null ||
          PrefService.getString('ui_theme') == "light")
      ? false
      : true;
}

String getAppId() {
  if (Platform.isIOS) {
    return 'ca-app-pub-5000919186848747~7217001778';
  } else if (Platform.isAndroid) {
    return 'ca-app-pub-5000919186848747~9280169707';
  }
  return null;
}

String getBannerAdUnitId() {
  if (Platform.isIOS) {
    return 'ca-app-pub-5000919186848747/9499661554';
  } else if (Platform.isAndroid) {
    return 'ca-app-pub-5000919186848747/5121378943';
  }
  return null;
}

Widget getAdmobBanner() {
  return Positioned(
      bottom: 16.0,
      left: 10.0,
      child: AdmobBanner(
        adUnitId: getBannerAdUnitId(),
        adSize: AdmobBannerSize.BANNER,
      ));
}
