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