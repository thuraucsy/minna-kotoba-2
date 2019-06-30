import 'dart:io';
import 'dart:convert'; // json using
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:preferences/preferences.dart';
import 'package:zawgyi_converter/zawgyi_converter.dart';
import 'Chapter.dart';

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

String logoByTheme() {
  return (PrefService.getString('ui_theme') == null ||
          PrefService.getString('ui_theme') == "light")
      ? 'assets/logo.png'
      : 'assets/logo_dark.png';
}

Widget logoImg() {
  return Image.asset(logoByTheme());
}

AssetImage logoAsset() {
  return AssetImage(logoByTheme());
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


Future<List<Chapter>> fetchPhotos(context) async {
  final response =
  await DefaultAssetBundle.of(context).loadString('assets/data.json');
  return compute(parseChapters, response);
}

List<Chapter> parseChapters(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Chapter>((json) => Chapter.fromJson(json)).toList();
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onTap;
  final AppBar appBar;

  const CustomAppBar({Key key, this.onTap, this.appBar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: appBar);
  }

  // TODO: implement preferredSize
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

Widget buildCard(ListTile listTile) {
  return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(child: listTile));
}
