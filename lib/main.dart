import 'dart:convert'; // json using
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // compute using
import 'package:flutter_tts/flutter_tts.dart';
import 'package:preferences/preferences.dart'; // setting page

void main() async {
  await PrefService.init(prefix: 'pref_');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int drawerIndex = 0;
  bool isShowDrawerMenu = true;
  bool isShowFavMenu = false;
  List<Chapter> chapters;
  List<ListItem> allWords;
  FlutterTts flutterTts;
  List<ListItem> allWordsBackup = [];
  ScrollController _scrollController = new ScrollController();
  Set _favoriteList = Set<String>();
  TextEditingController _searchController = TextEditingController(text: "");
  // setting variables
  final List<String> listJapanese = ['Hiragana', 'Kanji', 'Romaji'];
  final List<String> listMeaning = ['Myanmar', 'English'];

  Future _speak(text) async {
    // ～
    text = text.replaceAll(new RegExp(r'～'), '　');
    var result = await flutterTts.speak(text);
  }

  void _toggleFav(no, isFav) {
    setState(() {
      if (isFav) {
        _favoriteList.remove(no);
      } else {
        _favoriteList.add(no);
      }
    });
    print('long press ${no} $isFav');
    PrefService.setStringList("list_favorite", _favoriteList.toList());
  }

  List<Widget> _buildDrawerList(BuildContext context, List<Chapter> chapters) {
    List<Widget> drawer = [
      DrawerHeader(
        child: Text('Drawer Header'),
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
      ),
    ];

    List<Widget> chapterTile = [];
    for (int i = 0; i < chapters.length; i++) {
      Chapter chapter = chapters[i];
      chapterTile.add(new ListTile(
        title: Text(chapter.title),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          setState(() {
            drawerIndex = i;
          });
          print('index $i $drawerIndex');
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

    String selectedJapanese = listJapanese[0];
    String selectedMeaning = listMeaning[0];

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
          if (selectedJapanese == listJapanese[1]) {
            japaneseText = Text(chapter.words[index].kanji);
          } else if (selectedJapanese == listJapanese[2]) {
            japaneseText = Text(chapter.words[index].romaji);
          }

          Text meaningText = Text(chapter.words[index].myanmar,
              style: TextStyle(fontFamily: 'Masterpiece'));
          if (selectedMeaning == listMeaning[1]) {
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

  void filterSearchResults(String value) {
    List<ListItem> searchList = List<ListItem>();
    searchList.addAll(allWordsBackup);
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
        allWords.clear();
        allWords.addAll(searchListFound);
      });
    } else {
      setState(() {
        allWords.clear();
        allWords.addAll(searchList);
      });
    }
  }

  Container _buildSearchBodyList(BuildContext context,
      {bool isFavPage = false}) {
    List<Vocal> favWords = [];
    if (isFavPage) {
      for (int i = 0; i < allWords.length; i++) {
        if (allWords[i] is Vocal) {
          Vocal word = allWords[i] as Vocal;
          if (_favoriteList.contains(word.no)) {
            favWords.add(word);
          }
        }
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
                filterSearchResults(value);
              },
              decoration: InputDecoration(
                  labelText: "Search",
                  hintText: "watashi",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)))),
            ),
          ),
          Expanded(
            child: ListView.builder(
                controller: _scrollController,
                itemCount: isFavPage ? favWords.length : allWords.length,
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
                    if (allWords[index] is ChapterTitle) {
                      ChapterTitle chapterTitle =
                          allWords[index] as ChapterTitle;
                      return ListTile(
                          title: Text(
                        chapterTitle.title,
                        style: Theme.of(context).textTheme.headline,
                      ));
                    } else if (allWords[index] is Vocal) {
                      Vocal vocal = allWords[index] as Vocal;

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
        defaultVal: listJapanese[0],
        values: listJapanese,
      ),
      DropdownPreference(
        'Meaning',
        'list_meaning',
        defaultVal: listMeaning[0],
        values: listMeaning,
      )
    ]);
  }

  @override
  void initState() {
    print('initState');
    allWords = [];

    fetchPhotos(context).then((data) {
      print('initState data ${data.length}');
      setState(() {
        chapters = data;
      });

      for (int i = 0; i < chapters.length; i++) {
        allWords.add(ChapterTitle(chapters[i].title));
        allWords.addAll(chapters[i].words);
      }
      print('allWords ${allWords.length}');
      allWordsBackup.addAll(allWords);
    }).catchError((error) {
      print('initState error $error');
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appTitle = 'Minna Kotoba 2';
    flutterTts = FlutterTts();
    flutterTts.isLanguageAvailable("ja-JP").then((res) {
      print('ja-JP TTS lang available $res');
      if (res) flutterTts.setLanguage("ja-JP");
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
          appBar: isShowFavMenu
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
                  return chapters != null
                      ? Drawer(
                          child: ListView(
                              padding: EdgeInsets.zero,
                              children: _buildDrawerList(context, chapters)),
                        )
                      : Center(child: CircularProgressIndicator());
                })
              : null,
          body: TabBarView(
            children: [
              chapters != null
                  ? _buildBodyList(context, chapters[drawerIndex])
                  : Center(child: CircularProgressIndicator()),
              allWords != null
                  ? _buildSearchBodyList(context)
                  : Center(child: CircularProgressIndicator()),
              allWords != null
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
                isShowFavMenu = false;
              });

              if (index == 0) {
                setState(() {
                  isShowDrawerMenu = true;
                });
              } else if (index == 2) {
                setState(() {
                  isShowFavMenu = true;
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

// The base class for the different types of items the List can contain
abstract class ListItem {}

class Vocal implements ListItem {
  final String no;
  final String romaji;
  final String hiragana;
  final String kanji;
  final String english;
  final String myanmar;

  Vocal(
      {this.no,
      this.romaji,
      this.hiragana,
      this.kanji,
      this.english,
      this.myanmar});

  factory Vocal.fromJson(Map<String, dynamic> json) {
    return Vocal(
      no: json['no'] as String,
      romaji: json['romaji'] as String,
      hiragana: json['hiragana'] as String,
      kanji: json['kanji'] as String,
      english: json['english'] as String,
      myanmar: json['myanmar'] as String,
    );
  }
}

class ChapterTitle implements ListItem {
  final String title;

  ChapterTitle(this.title);
}

class Chapter {
  final String title;
  final List<Vocal> words;

  Chapter({this.title, this.words});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    var list = json['words'] as List;
    List<Vocal> vocalList = list.map((i) => Vocal.fromJson(i)).toList();

    return Chapter(
      title: json['title'] as String,
      words: vocalList,
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
