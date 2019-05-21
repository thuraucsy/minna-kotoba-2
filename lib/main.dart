import 'dart:convert'; // json using
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // compute using
import 'package:flutter_tts/flutter_tts.dart';
import 'package:preferences/preferences.dart'; // setting page
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // floating action button
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:minna_kotoba_2/Chapter.dart';

enum ConfirmAction { CANCEL, ACCEPT }
final String appBarTitle = "Minna Kotoba 2";

void main() async {
  await PrefService.init(prefix: 'pref_');
  runApp(MaterialApp(
    title: appBarTitle,
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) => new ThemeData(
            primaryColor: Color.fromRGBO(58, 66, 86, 1.0),
//                backgroundColor: Color.fromRGBO(231, 231, 214, 1.0),
            brightness: brightness,
            accentColor: Colors.green),
        themedWidgetBuilder: (context, theme) {
          return new MaterialApp(
            title: appBarTitle,
            theme: theme,
            home: new MyHomePage(title: 'Minna Kotoba 2'),
          );
        });
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyHomePage> {
  int _drawerIndex = 0;
  bool isShowDrawerMenu = true, _isShowFavMenu = false, _dialVisible = true, _isShuffle = false;
  List<String> _isShowKotoba = [];
  List<Chapter> _chapters;
  List<ListItem> _allWords, _allWordsBackup = [];
  ScrollController _scrollController = new ScrollController();
  TextEditingController _searchController = TextEditingController(text: "");
  Set _favoriteList = Set<String>();
  FlutterTts _flutterTts;
  final List<String> _listJapanese = ['Kana', 'Kanji', 'Romaji'], _listMeaning = ['Myanmar', 'English'], _listMemorizing = ['Japanese', 'Meaning'];

  void _toggleTheShuffle() {
    if (_isShuffle) {
      _chapters[_drawerIndex].words.shuffle();
    } else {
      _chapters[_drawerIndex].words.sort((a, b) =>
          int.parse(a.no.split("/")[1])
              .compareTo(int.parse(b.no.split("/")[1])));
    }
  }

  void _toggleFav(no, isFav) {
    setState(() {
      if (isFav) {
        _favoriteList.remove(no);
      } else {
        _favoriteList.add(no);
      }
    });
    PrefService.setStringList("list_favorite", _favoriteList.toList());
  }

  void _filterSearchResults(String value) {
    List<ListItem> searchList = List<ListItem>();
    searchList.addAll(_allWordsBackup);
    if (value.isNotEmpty) {
      List<ListItem> searchListFound = List<ListItem>();

      searchList.forEach((item) {
        if (item is Vocal &&
            (item.romaji.startsWith(value) ||
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

  Future _speak(text) async {
    text = text.replaceAll(new RegExp(r'～'), '　'); // ～ remove in speaking
    var result = await _flutterTts.speak(text);
  }

  Widget _buildCard(ListTile listTile) {
    return Card(
//        elevation: 1.5,
        margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Container(child: listTile));
  }

  List<Widget> _buildDrawerList(BuildContext context, List<Chapter> _chapters) {
    List<Widget> drawer = [
      DrawerHeader(
        child: Text('Drawer Header'),
//        decoration: BoxDecoration(
//          color: Theme.of(context).primaryColor
//        ),
      ),
    ];

    List<Widget> chapterTile = [];
    for (int i = 0; i < _chapters.length; i++) {
      Chapter chapter = _chapters[i];
      chapterTile.add(
//          _buildCard(
          ListTile(
            title: Text(chapter.title),
            onTap: () {
              setState(() {
                _drawerIndex = i;
              });
              print('drawer index $i $_drawerIndex');
              PrefService.setInt("drawer_index", _drawerIndex);
              Navigator.of(context).pop(); // dismiss the navigator
              _scrollController.animateTo(0.0,
                  duration: Duration(milliseconds: 500), curve: Curves.easeOut);
              _toggleTheShuffle();
            },
          )
//          )
          );
    }

    drawer.addAll(chapterTile);

    return drawer;
  }

  Widget _buildBodyList(BuildContext context) {

    String selectedJapanese = PrefService.getString("list_japanese") ?? _listJapanese[0];
    String selectedMeaning = PrefService.getString("list_meaning") ?? _listMeaning[0];
    String selectedMemorizing = PrefService.getString("list_memorizing") ?? _listMemorizing[0];

    return Container(
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: _chapters[_drawerIndex].words.length,
        itemBuilder: (BuildContext context, int index) {
          Text japaneseText =
              Text(_chapters[_drawerIndex].words[index].hiragana);
          if (selectedJapanese == _listJapanese[1]) {
            japaneseText = Text(_chapters[_drawerIndex].words[index].kanji);
          } else if (selectedJapanese == _listJapanese[2]) {
            japaneseText = Text(_chapters[_drawerIndex].words[index].romaji);
          }

          Text meaningText = Text(_chapters[_drawerIndex].words[index].myanmar,
              style: TextStyle(fontFamily: 'Masterpiece'));
          if (selectedMeaning == _listMeaning[1]) {
            meaningText = Text(_chapters[_drawerIndex].words[index].english);
          }

          // favorite condition
          bool isFav =
              _favoriteList.contains(_chapters[_drawerIndex].words[index].no);

          return _buildCard(
            ListTile(
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(isFav ? Icons.favorite : Icons.favorite_border,
                      color: Colors.redAccent),
                  Text(_chapters[_drawerIndex].words[index].no),
                ],
              ),
              title: AnimatedOpacity(
                opacity: (selectedMemorizing != _listMemorizing[0] ||
                        (_isShowKotoba.length == 0 ||
                            (_isShowKotoba.contains(_chapters[_drawerIndex].words[index].no))))
                    ? 1.0
                    : 0.0,
                duration: Duration(milliseconds: 500),
                child: japaneseText,
              ),
              subtitle: AnimatedOpacity(
                opacity: (selectedMemorizing != _listMemorizing[1] ||
                        (_isShowKotoba.length == 0 ||
                            (_isShowKotoba.contains(_chapters[_drawerIndex].words[index].no))))
                    ? 1.0
                    : 0.0,
                duration: Duration(milliseconds: 500),
                child: meaningText,
              ),
              onTap: () {
                _speak(_chapters[_drawerIndex].words[index].kanji);
                setState(() {
                  if (_isShowKotoba.length > 0) {
                    _isShowKotoba[index] =
                        _chapters[_drawerIndex].words[index].no;
                    print('_isShowKotoba[index] ${_isShowKotoba[index]}');
                  }
                });
              },
              onLongPress: () {
                _toggleFav(_chapters[_drawerIndex].words[index].no, isFav);
              },
            ),
          );
        },
      ),
    );
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

    Widget makeList(Vocal vocal, bool isFav) {
      return _buildCard(ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${vocal.hiragana} ${vocal.romaji}'),
            Text(vocal.kanji),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              vocal.myanmar,
              style: TextStyle(fontFamily: 'Masterpiece'),
            ),
            Text(
              vocal.english,
            )
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: Colors.redAccent),
            Text(vocal.no),
          ],
        ),
        onTap: () {
          _speak(vocal.hiragana);
        },
        onLongPress: () {
          _toggleFav(vocal.no, isFav);
        },
      ));
    }

    return Container(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
//              style: TextStyle(fontFamily: 'Masterpiece'),
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
                      borderRadius: BorderRadius.all(Radius.circular(6.0)))),
            ),
          ),
          Expanded(
            child: ListView.builder(
                controller: _scrollController,
                itemCount: isFavPage ? favWords.length : _allWords.length,
                itemBuilder: (context, index) {
                  if (isFavPage) {
                    return makeList(favWords[index], true);
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

                      return makeList(vocal, isFav);
                    }
                  }
                }),
          )
        ],
      ),
    );
  }

  PreferencePage _preferencePage(BuildContext context) {
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
      ),
      DropdownPreference(
        'Memorizing',
        'list_memorizing',
        defaultVal: _listMemorizing[0],
        values: _listMemorizing,
      ),
      PreferenceTitle('Personalization'),
      RadioPreference(
        'Day Mode',
        'light',
        'ui_theme',
        isDefault: true,
        onSelect: () {
          DynamicTheme.of(context).setBrightness(Brightness.light);
        },
      ),
      RadioPreference(
        'Night Mode',
        'dark',
        'ui_theme',
        onSelect: () {
          DynamicTheme.of(context).setBrightness(Brightness.dark);
        },
      ),
    ]);
  }

  @override
  void initState() {
    print('initState');
    _allWords = [];

    fetchPhotos(context).then((data) {
      setState(() {
        _chapters = data;
        if (PrefService.getStringList("list_favorite") != null) {
          _favoriteList = PrefService.getStringList("list_favorite").toSet();
        }
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


    _drawerIndex = PrefService.getInt("drawer_index") ?? 0;

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

    Future<ConfirmAction> _clearFav() {
      // flutter defined function
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text("Empty favorite?"),
            content: new Text("This will clear the favorite list."),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop(ConfirmAction.CANCEL);
                },
              ),
              FlatButton(
                child: new Text("Clear"),
                onPressed: () {
                  Navigator.of(context).pop(ConfirmAction.ACCEPT);
                },
              ),
            ],
          );
        },
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomAppBar(
          appBar: _isShowFavMenu
              ? AppBar(
                  title: Text(appTitle),
                  actions: <Widget>[
                    IconButton(
                        icon: Icon(Icons.delete_outline),
                        onPressed: () async {
                          ConfirmAction action = await _clearFav();
                          print('ConfirmAction $action');

                          if (action == ConfirmAction.ACCEPT) {
                            print('Clearing the favorite list');
                            setState(() {
                              _favoriteList.clear();
                            });
                            PrefService.setStringList("list_favorite", []);
                          }
                        })
                  ],
                )
              : AppBar(title: Text(appTitle)),
          onTap: () {
            print('app bar tap');
            _scrollController.animateTo(0.0,
                duration: Duration(milliseconds: 500), curve: Curves.easeOut);
          },
        ),
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
                ? _buildBodyList(context)
                : Center(child: CircularProgressIndicator()),
            _allWords != null
                ? _buildSearchBodyList(context)
                : Center(child: CircularProgressIndicator()),
            _allWords != null
                ? _buildSearchBodyList(context, isFavPage: true)
                : Center(child: CircularProgressIndicator()),
            _preferencePage(context),
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
              _dialVisible = false;
            });

            if (index == 0) {
              setState(() {
                isShowDrawerMenu = true;
                _dialVisible = true;
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
        floatingActionButton: SpeedDial(
          // both default to 16
          marginRight: 18,
          marginBottom: 20,
          animatedIcon: AnimatedIcons.menu_close,
          animatedIconTheme: IconThemeData(size: 22.0),
          // this is ignored if animatedIcon is non null
          // child: Icon(Icons.add),
          visible: _dialVisible,
          // If true user is forced to close dial manually
          // by tapping main button and overlay is not rendered.
          closeManually: false,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          onOpen: () => print('OPENING DIAL'),
          onClose: () => print('DIAL CLOSED'),
          tooltip: 'Speed Dial',
          heroTag: 'speed-dial-hero-tag',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 8.0,
          shape: CircleBorder(),
          children: [
            SpeedDialChild(
                child: Icon(Icons.shuffle),
                backgroundColor: _isShuffle ? Colors.deepOrangeAccent : Colors.white,
                foregroundColor: _isShuffle ? Colors.white : Colors.black,
                label: _isShuffle ? 'Shuffling' : 'Shuffle',
                labelStyle: TextStyle(color: Colors.black),
                onTap: () {
                  setState(() {
                    _isShuffle = !_isShuffle;
                  });
                  print('_isShuffle $_isShuffle');
                  _toggleTheShuffle();

                }),
            SpeedDialChild(
              child: Icon(Icons.question_answer),
              backgroundColor: _isShowKotoba.length > 0 ? Colors.green : Colors.white,
              foregroundColor: _isShowKotoba.length > 0 ? Colors.white : Colors.black,
              label: _isShowKotoba.length > 0 ? 'Memorizing' : 'Memorize',
              labelStyle: TextStyle(color: Colors.black),
              onTap: () {
                print('Memorizing');
                setState(() {
                  if (_isShowKotoba.length == 0) {
                    print('on');
                    for (int i = 0;
                        i < _chapters[_drawerIndex].words.length;
                        i++) {
                      _isShowKotoba.add("");
                    }
                  } else {
                    print('off ${_isShowKotoba.length}');
                    _isShowKotoba = [];
                  }
                });
              },
            ),
          ],
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
  Size get preferredSize => new Size.fromHeight(kToolbarHeight);
}
