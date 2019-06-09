import 'package:preferences/preferences.dart';

enum ConfirmAction { CANCEL, ACCEPT }
final String appTitle = "Minna Kotoba 2";
final List<String> listJapanese = ['Kana', 'Kanji', 'Romaji'],
    listMeaning = ['Myanmar', 'English'],
    listMemorizing = ['Japanese', 'Meaning'];


bool isZawgyi() {
  return PrefService.getBool("switch_zawgyi") ?? false;
}