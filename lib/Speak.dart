import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:preferences/preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:minna_kotoba_2/Chapter.dart';
import 'package:minna_kotoba_2/GlobalVar.dart';

class Speak {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  StreamSubscription errorSub;

  Future tts(Vocal vocal, context) async {
    bool switchTts = PrefService.getBool("switch_tts");
    if (switchTts == null || switchTts) {
      String ttsLang = "ja-JP";
      bool isLangAva = await flutterTts.isLanguageAvailable(ttsLang);
      String listSource = PrefService.getString("list_source") ?? listTtsSource[0];

      // ～ remove in speaking
      String kanji = vocal.kanji.replaceAll(new RegExp(r'～'), '　');
      String kana = vocal.hiragana.replaceAll(new RegExp(r'～'), '　');

      print('speaking ${vocal.kanji} ${vocal.hiragana}');

      if (listSource == listTtsSource[0]) {

        if (isLangAva) {

          flutterTts.setLanguage(ttsLang);
          await flutterTts.speak(kana);

        } else {
          print('language not available');
          showDialog(
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

      } else {
        await audioPlayer.play(Uri.encodeFull('https://assets.languagepod101.com/dictionary/japanese/audiomp3.php?kanji=$kanji&kana=$kana'));

        if (errorSub  == null) {
          errorSub = audioPlayer.onPlayerError.listen((msg) {
            print('audioPlayer error: $msg');

            showDialog(
              context: context,
              builder: (BuildContext context) {
                // return object of type Dialog
                return AlertDialog(
                  title: new Text("No internet :("),
                  content: new Text(
                      "Playback source for JapanesePod101 requires internet connection."),
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
          });
        }

      }
    }
  }

}