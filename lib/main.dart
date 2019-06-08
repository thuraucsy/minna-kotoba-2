import 'dart:convert'; // json using
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // compute using
import 'package:flutter_tts/flutter_tts.dart';
import 'package:preferences/preferences.dart'; // setting page
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // floating action button
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:provider/provider.dart';
import 'package:minna_kotoba_2/Chapter.dart';
import 'package:minna_kotoba_2/AppModel.dart';

enum ConfirmAction { CANCEL, ACCEPT }
final List<String> listJapanese = ['Kana', 'Kanji', 'Romaji'],
    listMeaning = ['Myanmar', 'English'],
    listMemorizing = ['Japanese', 'Meaning'];
final FlutterTts flutterTts = FlutterTts();

void main() async {
  await PrefService.init(prefix: 'pref_');
  runApp(ChangeNotifierProvider(
    builder: (context) => AppModel(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) => new ThemeData(
              primarySwatch: Colors.amber,
              brightness: brightness,
            ),
        themedWidgetBuilder: (context, theme) {
          return new MaterialApp(
            title: "Minna Kotoba 2",
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
  int _drawerIndex = 0, _tabIndex = 0;
  bool isShowDrawerMenu = true,
      _isShowFavMenu = false,
      _isShowSearchMenu = true,
      _dialVisible = true,
      _isShuffle = false;
  List<String> _isShowKotoba = [];
  List<Chapter> _chapters;
  List<ListItem> _allWords = [];
  List<Vocal> _allVocals = [];
  ScrollController _scrollController = new ScrollController();
  TextEditingController _searchController = TextEditingController(text: "");

  void _toggleTheShuffle() {
    if (_isShuffle) {
      _chapters[_drawerIndex].words.shuffle();
    } else {
      _chapters[_drawerIndex].words.sort((a, b) => int.parse(a.no.split("/")[1])
          .compareTo(int.parse(b.no.split("/")[1])));
    }
  }

  List<Widget> _buildDrawerList(BuildContext context, List<Chapter> _chapters) {
    bool isDarkTheme = (PrefService.getString('ui_theme') != null && PrefService.getString('ui_theme') == "light") ? false : true;

    List<Widget> drawer = [
      DrawerHeader(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: isDarkTheme ? AssetImage('assets/logo_dark.png') : AssetImage('assets/logo.png'),
                fit: BoxFit.cover,
            ),
        )
      ),
    ];

    List<Widget> chapterTile = [];
    for (int i = 0; i < _chapters.length; i++) {
      Chapter chapter = _chapters[i];
      chapterTile.add(ListTile(
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
      ));
    }

    drawer.addAll(chapterTile);

    return drawer;
  }

  Widget _buildBodyList(BuildContext context) {
    String selectedJapanese =
        PrefService.getString("list_japanese") ?? listJapanese[0];
    String selectedMeaning =
        PrefService.getString("list_meaning") ?? listMeaning[0];
    String selectedMemorizing =
        PrefService.getString("list_memorizing") ?? listMemorizing[0];

    return Container(
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: _chapters[_drawerIndex].words.length,
        itemBuilder: (BuildContext context, int index) {
          Text japaneseText =
              Text(_chapters[_drawerIndex].words[index].hiragana);
          if (selectedJapanese == listJapanese[1]) {
            japaneseText = Text(_chapters[_drawerIndex].words[index].kanji);
          } else if (selectedJapanese == listJapanese[2]) {
            japaneseText = Text(_chapters[_drawerIndex].words[index].romaji);
          }

          Text meaningText = Text(_chapters[_drawerIndex].words[index].myanmar,
              style: isZawgyi() ? null : TextStyle(fontFamily: 'Masterpiece'));

          if (selectedMeaning == listMeaning[1]) {
            meaningText = Text(_chapters[_drawerIndex].words[index].english);
          }

          // favorite condition
          bool isFav =
              Provider.of<AppModel>(context).isFav(_chapters[_drawerIndex].words[index].no);

          return buildCard(
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
                opacity: (selectedMemorizing != listMemorizing[0] ||
                        (_isShowKotoba.length == 0 ||
                            (_isShowKotoba.contains(
                                _chapters[_drawerIndex].words[index].no))))
                    ? 1.0
                    : 0.0,
                duration: Duration(milliseconds: 500),
                child: japaneseText,
              ),
              subtitle: AnimatedOpacity(
                opacity: (selectedMemorizing != listMemorizing[1] ||
                        (_isShowKotoba.length == 0 ||
                            (_isShowKotoba.contains(
                                _chapters[_drawerIndex].words[index].no))))
                    ? 1.0
                    : 0.0,
                duration: Duration(milliseconds: 500),
                child: meaningText,
              ),
              onTap: () {
                speak(_chapters[_drawerIndex].words[index].kanji, context);
                setState(() {
                  if (_isShowKotoba.length > 0) {
                    int removeInd = _isShowKotoba.indexOf(_chapters[_drawerIndex].words[index].no);
                    if (removeInd > -1) {
                      _isShowKotoba.removeAt(removeInd);
                      print('_isShowKotoba removeInd $removeInd');
                    } else {
                      _isShowKotoba.add(_chapters[_drawerIndex].words[index].no);
                      print('_isShowKotoba add ${_chapters[_drawerIndex].words[index].no}');
                    }
                  }
                });
              },
              onLongPress: () {
                Provider.of<AppModel>(context).toggle(_chapters[_drawerIndex].words[index].no, isFav);
              },
            ),
          );
        },
      ),
    );
  }

  Container _buildSearchBodyList(BuildContext context,
      {bool isFavPage = false}) {
    Set favoriteList = Provider.of<AppModel>(context).get();
    List<Vocal> favVocals = [];

    if (isFavPage) {
      if (favoriteList.length > 0) {
        favVocals = Provider.of<AppModel>(context).getFavVocal(_allWords);
      } else {
        return Container(
          child: Center(
            child: Text("Please long press on the word to save as favorite ❤️"),
          ),
        );
      }
    }

    Widget makeList(Vocal vocal, bool isFav) {

      Text myanmarText = Text(vocal.myanmar, style: isZawgyi() ? null : TextStyle(fontFamily: 'Masterpiece'));

      return buildCard(ListTile(
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
            myanmarText,
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
          speak(vocal.hiragana, context);
        },
        onLongPress: () {
          Provider.of<AppModel>(context).toggle(vocal.no, isFav);
        },
      ));
    }

    return Container(
      child: ListView.builder(
          controller: _scrollController,
          itemCount: isFavPage ? favVocals.length : _allWords.length,
          itemBuilder: (context, index) {
            if (isFavPage) {
              return makeList(favVocals[index], true);
            } else {
              if (_allWords[index] is ChapterTitle) {
                ChapterTitle chapterTitle = _allWords[index] as ChapterTitle;
                return ListTile(
                    title: Text(
                  chapterTitle.title,
                  style: Theme.of(context).textTheme.headline,
                ));
              } else if (_allWords[index] is Vocal) {
                Vocal vocal = _allWords[index] as Vocal;

                // favorite condition
                bool isFav = Provider.of<AppModel>(context).isFav(vocal.no);

                return makeList(vocal, isFav);
              }
            }
          }),
    );
  }

  PreferencePage _preferencePage(BuildContext context) {
    return PreferencePage([
      PreferenceTitle("List"),
      DropdownPreference(
        'Japanese',
        'list_japanese',
        defaultVal: listJapanese[0],
        values: listJapanese,
      ),
      DropdownPreference(
        'Meaning',
        'list_meaning',
        defaultVal: listMeaning[0],
        values: listMeaning,
      ),
      DropdownPreference(
        'Memorizing',
        'list_memorizing',
        defaultVal: listMemorizing[0],
        values: listMemorizing,
      ),
      PreferenceTitle('Sound'),
      SwitchPreference('Text To Speech for Japanese', 'switch_tts',
          defaultVal: true),
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
      PreferenceTitle('Myanmar Font'),
      SwitchPreference('Zawgyi', 'switch_zawgyi', onChange: () {
        _chapters.clear();
        _allWords.clear();
        _allVocals.clear();
        initializeVar();
      },)
    ]);
  }

  void initializeVar() {
    fetchPhotos(context).then((data) {
      setState(() {
        _chapters = data;
      });

      for (int i = 0; i < _chapters.length; i++) {
        _allWords.add(ChapterTitle(_chapters[i].title));
        _allWords.addAll(_chapters[i].words);
        _allVocals.addAll(_chapters[i].words);
      }
      print('_allWords ${_allWords.length}');
    }).catchError((error) {
      print('fetchPhotos error $error');
    });

    _drawerIndex = PrefService.getInt("drawer_index") ?? 0;
  }

  @override
  void initState() {
    print('initState');
    initializeVar();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appTitle = 'Minna Kotoba 2';

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
          appBar: AppBar(
            title: Text(appTitle),
            actions: <Widget>[
              Visibility(
                visible: _isShowSearchMenu,
                child: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                        context: context,
                        delegate: (_tabIndex == 0)
                            ? VocalSearch(_chapters[_drawerIndex].words)
                            : ( _tabIndex == 1 ? VocalSearch(_allVocals) : VocalSearch(Provider.of<AppModel>(context).getFavVocal(_allWords)) )
                    );
                  },
                ),
              ),
              Visibility(
                visible: _isShowFavMenu,
                child: IconButton(
                    icon: Icon(Icons.delete_outline),
                    onPressed: () async {
                      ConfirmAction action = await _clearFav();
                      print('ConfirmAction $action');

                      if (action == ConfirmAction.ACCEPT) {
                        print('Clearing the favorite list');
                        Provider.of<AppModel>(context).clear();
                        PrefService.setStringList("list_favorite", []);
                      }
                    }),
              )
            ],
          ),
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
            _tabIndex = index;

            setState(() {
              isShowDrawerMenu = false;
              _isShowFavMenu = false;
              _isShowSearchMenu = false;
              _dialVisible = false;
            });

            if (index == 0) {
              setState(() {
                isShowDrawerMenu = true;
                _isShowSearchMenu = true;
                _dialVisible = true;
              });
            } else if (index == 1) {
              setState(() {
                _isShowSearchMenu = true;
              });
            } else if (index == 2) {
              setState(() {
                _isShowFavMenu = true;
                _isShowSearchMenu = true;
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
                backgroundColor: _isShuffle ? Colors.amber : Colors.white,
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
              backgroundColor:
                  _isShowKotoba.length > 0 ? Colors.redAccent : Colors.white,
              foregroundColor:
                  _isShowKotoba.length > 0 ? Colors.white : Colors.black,
              label: _isShowKotoba.length > 0 ? 'Memorizing' : 'Memorize',
              labelStyle: TextStyle(color: Colors.black),
              onTap: () {
                print('Memorizing');
                setState(() {
                  if (_isShowKotoba.length == 0) {
                    print('on');
                    _isShowKotoba.add("");
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

bool isZawgyi() {
  return PrefService.getBool("switch_zawgyi") ?? false;
}

Future<List<Chapter>> fetchPhotos(context) async {

  String loadString = isZawgyi() ? 'dataZawgyi.json' : 'data.json';

  final response =
      await DefaultAssetBundle.of(context).loadString('assets/$loadString');
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

Future speak(text, context) async {
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

Widget buildCard(ListTile listTile) {
  return Card(
      elevation: 2.0,
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(child: listTile));
}

Widget makeSearchList(Vocal vocal, {BuildContext context}) {

  bool isFav =  Provider.of<AppModel>(context).isFav(vocal.no);

  Text myanmarText = Text(vocal.myanmar, style: isZawgyi() ? null : TextStyle(fontFamily: 'Masterpiece'));

  return buildCard(ListTile(
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
        myanmarText,
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
      speak(vocal.hiragana, context);
    },
    onLongPress: () {
      Provider.of<AppModel>(context).toggle(vocal.no, isFav);
    },
  ));
}

class VocalSearch extends SearchDelegate<Vocal> {
  final List<Vocal> vocals;

  VocalSearch(this.vocals);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Vocal> searchList = filterSearch(query);
    return ListView.builder(
        itemCount: searchList.length,
        itemBuilder: (BuildContext context, int index) {
          return makeSearchList(searchList[index], context: context);
        });
  }

  List<Vocal> filterSearch(String query) {
    List<Vocal> searchList = List<Vocal>();
    searchList.addAll(vocals);
    if (query.isNotEmpty) {
      List<Vocal> searchListFound = List<Vocal>();

      searchList.forEach((item) {
        if (item is Vocal &&
            (item.romaji.toLowerCase().startsWith(query) ||
                item.hiragana.contains(query) ||
                item.kanji.contains(query) ||
                item.english.contains(query) ||
                item.myanmar.contains(query))) {
          searchListFound.add(item);
        }
      });

      searchList.clear();
      searchList.addAll(searchListFound);
    }
    return searchList;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Vocal> searchList = filterSearch(query);
    return ListView.builder(
        itemCount: searchList.length,
        itemBuilder: (BuildContext context, int index) {
          return makeSearchList(searchList[index], context: context);
        });
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context);
  }
}
