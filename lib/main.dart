import 'dart:convert'; // json using
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // compute using
import 'package:flutter_tts/flutter_tts.dart';
import 'package:preferences/preferences.dart'; // setting page
import 'package:minna_kotoba_2/Chapter.dart';

void main() async {
  await PrefService.init(prefix: 'pref_');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _drawerIndex = 0;
  bool isShowDrawerMenu = true;
  bool _isShowFavMenu = false;
  List<Chapter> _chapters;
  List<ListItem> _allWords;
  List<ListItem> _allWordsBackup = [];
  ScrollController _scrollController = new ScrollController();
  TextEditingController _searchController = TextEditingController(text: "");
  Set _favoriteList = Set<String>();
  FlutterTts _flutterTts;
  // setting variables
  final List<String> _listJapanese = ['Kana', 'Kanji', 'Romaji'];
  final List<String> _listMeaning = ['Myanmar', 'English'];

  Future _speak(text) async {
    // ～ remove in speaking
    text = text.replaceAll(new RegExp(r'～'), '　');
    var result = await _flutterTts.speak(text);
  }

  void _toggleFav(no, isFav) {
    setState(() {
      if (isFav) {
        _favoriteList.remove(no);
      } else {
        _favoriteList.add(no);
      }
    });
    print('long press $no $isFav');
    PrefService.setStringList("list_favorite", _favoriteList.toList());
  }

  void _filterSearchResults(String value) {
    List<ListItem> searchList = List<ListItem>();
    searchList.addAll(_allWordsBackup);
    if (value.isNotEmpty) {
      List<ListItem> searchListFound = List<ListItem>();

      searchList.forEach((item) {
        if (item is Vocal &&
            (item.romaji.contains(value) ||
                item.hiragana.contains(value) ||
                item.kanji.contains(value) ||
                item.english.contains(value) ||
                item.myanmar.contains(value))) {
          searchListFound.add(item);
        }
      });

      setState(() {
        _allWords.clear();
        _allWords.addAll(searchListFound);
      });
    } else {
      setState(() {
        _allWords.clear();
        _allWords.addAll(searchList);
      });
    }
  }

  List<Widget> _buildDrawerList(BuildContext context, List<Chapter> _chapters) {
    List<Widget> drawer = [
      DrawerHeader(
        child: Text('Drawer Header'),
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
      ),
    ];

    List<Widget> chapterTile = [];
    for (int i = 0; i < _chapters.length; i++) {
      Chapter chapter = _chapters[i];
      chapterTile.add(new ListTile(
        title: Text(chapter.title),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          setState(() {
            _drawerIndex = i;
          });
          print('drawer index $i $_drawerIndex');
          Navigator.of(context).pop(); // dismiss the navigator
          _scrollController.animateTo(0.0,
              duration: Duration(milliseconds: 500), curve: Curves.easeOut);
        },
      ));
    }

    drawer.addAll(chapterTile);

    return drawer;
  }

  ListView _buildBodyList(BuildContext context, Chapter chapter) {
    print(
        'pref ${PrefService.getString("list_japanese")} ${PrefService.getString("list_meaning")} ${PrefService.getStringList("list_favorite")}');

    String selectedJapanese = _listJapanese[0];
    String selectedMeaning = _listMeaning[0];

    if (PrefService.getString("list_japanese") != null) {
      selectedJapanese = PrefService.getString("list_japanese");
    }
    if (PrefService.getString("list_meaning") != null) {
      selectedMeaning = PrefService.getString("list_meaning");
    }

    if (PrefService.getStringList("list_favorite") != null) {
      _favoriteList = PrefService.getStringList("list_favorite").toSet();
    }

    return ListView.builder(
        controller: _scrollController,
        itemCount: chapter.words.length,
        itemBuilder: (context, index) {
          Text japaneseText = Text(chapter.words[index].hiragana);
          if (selectedJapanese == _listJapanese[1]) {
            japaneseText = Text(chapter.words[index].kanji);
          } else if (selectedJapanese == _listJapanese[2]) {
            japaneseText = Text(chapter.words[index].romaji);
          }

          Text meaningText = Text(chapter.words[index].myanmar,
              style: TextStyle(fontFamily: 'Masterpiece'));
          if (selectedMeaning == _listMeaning[1]) {
            meaningText = Text(chapter.words[index].english);
          }

          // favorite condition
          bool isFav = _favoriteList.contains(chapter.words[index].no);

          return ListTile(
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent),
                Text(chapter.words[index].no),
              ],
            ),
            title: japaneseText,
            subtitle: meaningText,
            onTap: () {
              _speak(chapter.words[index].hiragana);
            },
            onLongPress: () {
              _toggleFav(chapter.words[index].no, isFav);
            },
          );
        });
  }

  Container _buildSearchBodyList(BuildContext context,
      {bool isFavPage = false}) {
    List<Vocal> favWords = [];
    if (isFavPage) {
      if (_favoriteList.length > 0) {
        for (int i = 0; i < _allWords.length; i++) {
          if (_allWords[i] is Vocal) {
            Vocal word = _allWords[i] as Vocal;
            if (_favoriteList.contains(word.no)) {
              favWords.add(word);
            }
          }
        }
      } else {
        return Container(
          child: Center(
            child: Text("Please long press on the word to save as favorite ❤️"),
          ),
        );
      }
    }

    return Container(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              style: TextStyle(fontFamily: 'Masterpiece'),
              controller: _searchController,
              onChanged: (value) {
                print('search onChanged $value');
                _filterSearchResults(value);
              },
              decoration: InputDecoration(
                  labelText: "Search",
                  hintText: "watashi",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)))
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
                controller: _scrollController,
                itemCount: isFavPage ? favWords.length : _allWords.length,
                itemBuilder: (context, index) {
                  if (isFavPage) {
                    return ListTile(
                      title: Text(favWords[index].hiragana),
                      subtitle: Text(
                        favWords[index].myanmar,
                        style: TextStyle(fontFamily: 'Masterpiece'),
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.favorite, color: Colors.redAccent),
                          Text(favWords[index].no),
                        ],
                      ),
//                      trailing: Text(favWords[index].no),
                      onTap: () {
                        _speak(favWords[index].hiragana);
                      },
                      onLongPress: () {
                        _toggleFav(favWords[index].no, true);
                      },
                    );
                  } else {
                    if (_allWords[index] is ChapterTitle) {
                      ChapterTitle chapterTitle =
                          _allWords[index] as ChapterTitle;
                      return ListTile(
                          title: Text(
                        chapterTitle.title,
                        style: Theme.of(context).textTheme.headline,
                      ));
                    } else if (_allWords[index] is Vocal) {
                      Vocal vocal = _allWords[index] as Vocal;

                      // favorite condition
                      bool isFav = _favoriteList.contains(vocal.no);

                      return ListTile(
                        title: Text(vocal.hiragana),
                        subtitle: Text(
                          vocal.myanmar,
                          style: TextStyle(fontFamily: 'Masterpiece'),
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                                isFav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent),
                            Text(vocal.no),
                          ],
                        ),
                        onTap: () {
                          _speak(vocal.hiragana);
                        },
                        onLongPress: () {
                          _toggleFav(vocal.no, isFav);
                        },
                      );
                    }
                  }
                }),
          )
        ],
      ),
    );
  }

  PreferencePage _preferencePage() {
    return PreferencePage([
      PreferenceTitle("List"),
      DropdownPreference(
        'Japanese',
        'list_japanese',
        defaultVal: _listJapanese[0],
        values: _listJapanese,
      ),
      DropdownPreference(
        'Meaning',
        'list_meaning',
        defaultVal: _listMeaning[0],
        values: _listMeaning,
      )
    ]);
  }

  @override
  void initState() {
    print('initState');
    _allWords = [];

    fetchPhotos(context).then((data) {
      setState(() {
        _chapters = data;
      });

      for (int i = 0; i < _chapters.length; i++) {
        _allWords.add(ChapterTitle(_chapters[i].title));
        _allWords.addAll(_chapters[i].words);
      }
      print('_allWords ${_allWords.length}');
      _allWordsBackup.addAll(_allWords);
    }).catchError((error) {
      print('initState error $error');
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appTitle = 'Minna Kotoba 2';
    _flutterTts = FlutterTts();
    _flutterTts.isLanguageAvailable("ja-JP").then((res) {
      print('ja-JP TTS lang available $res');
      if (res) _flutterTts.setLanguage("ja-JP");
    });

    void _clearFav() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text("Alert Dialog title"),
            content: new Text("Alert Dialog body"),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    return MaterialApp(
      title: appTitle,
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: _isShowFavMenu
              ? AppBar(
                  title: Text(appTitle),
                  actions: <Widget>[
                    IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  child: Text('Dialog.'),
                                );
                              });
                        }
                    )
                  ],
                )
              : AppBar(title: Text(appTitle)),
          drawer: isShowDrawerMenu
              ? Builder(builder: (context) {
                  return _chapters != null
                      ? Drawer(
                          child: ListView(
                              padding: EdgeInsets.zero,
                              children: _buildDrawerList(context, _chapters)),
                        )
                      : Center(child: CircularProgressIndicator());
                })
              : null,
          body: TabBarView(
            children: [
              _chapters != null
                  ? _buildBodyList(context, _chapters[_drawerIndex])
                  : Center(child: CircularProgressIndicator()),
              _allWords != null
                  ? _buildSearchBodyList(context)
                  : Center(child: CircularProgressIndicator()),
              _allWords != null
                  ? _buildSearchBodyList(context, isFavPage: true)
                  : Center(child: CircularProgressIndicator()),
              _preferencePage(),
            ],
            physics: NeverScrollableScrollPhysics(),
          ),
          bottomNavigationBar: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.format_list_numbered_rtl)),
              Tab(icon: Icon(Icons.search)),
              Tab(icon: Icon(Icons.favorite, color: Colors.redAccent)),
              Tab(icon: Icon(Icons.settings)),
            ],
            onTap: (int index) {
              print('tab index $index');

              setState(() {
                isShowDrawerMenu = false;
                _isShowFavMenu = false;
              });

              if (index == 0) {
                setState(() {
                  isShowDrawerMenu = true;
                });
              } else if (index == 2) {
                setState(() {
                  _isShowFavMenu = true;
                });
              }
            },
            labelColor: Colors.black,
            isScrollable: false,
          ),
        ),
      ),
    );
  }
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
