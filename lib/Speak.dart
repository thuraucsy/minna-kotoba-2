import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:preferences/preferences.dart';
import 'package:minna_kotoba_2/GlobalVar.dart';

class Speak {
  final FlutterTts flutterTts = FlutterTts();

  Future tts(text, context) async {
    bool switchTts = PrefService.getBool("switch_tts");
    if (switchTts == null || switchTts) {
      String ttsLang = "ja-JP";
      bool isLangAva = await flutterTts.isLanguageAvailable(ttsLang);

      if (isLangAva) {
        flutterTts.setLanguage(ttsLang);
        text = text.replaceAll(new RegExp(r'～'), '　'); // ～ remove in speaking
        await flutterTts.speak(text);
      } else {
        print('language not available');
        return showDialog(
          context: context,
          builder: (BuildContext context) {
            // return object of type Dialog
            return AlertDialog(
              title: new Text("Text To Speech for Japanese is not available :("),
              content: new Text(
                  "Please install the Text To Speech engine for Japanese first, then restart the app. For Android, Google TTS is available on the Play Store."),
              actions: <Widget>[
                // usually buttons at the bottom of the dialog
                FlatButton(
                  child: new Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop(ConfirmAction.CANCEL);
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

}