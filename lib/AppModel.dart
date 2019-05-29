import 'package:flutter/foundation.dart';
import 'package:preferences/preferences.dart';
import 'package:minna_kotoba_2/Chapter.dart';

class AppModel extends ChangeNotifier {
  Set _favoriteList;

  AppModel() {
    _favoriteList = Set<String>();
    if (PrefService.getStringList("list_favorite") != null) {
      _favoriteList = PrefService.getStringList("list_favorite").toSet();
    }
  }

  Set get() {
    return _favoriteList;
  }

  List<Vocal> getFavVocal(allWords) {
    List<Vocal> favVocals = [];

    for (int i = 0; i < allWords.length; i++) {
      if (allWords[i] is Vocal) {
        Vocal word = allWords[i] as Vocal;
        if (_favoriteList.contains(word.no)) {
          favVocals.add(word);
        }
      }
    }
    return favVocals;
  }

  void toggle(no, isFav) {
    if (isFav) {
      _favoriteList.remove(no);
    } else {
      _favoriteList.add(no);
    }
    PrefService.setStringList("list_favorite", _favoriteList.toList());
    notifyListeners();
  }

  void clear() {
    _favoriteList.clear();
    PrefService.setStringList("list_favorite", _favoriteList.toList());
    notifyListeners();
  }

  bool isFav(no) {
    return _favoriteList.contains(no);
  }
}