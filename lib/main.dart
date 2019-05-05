import 'dart:convert'; // json using
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // compute using
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(MyApp());

Future<List<Chapter>> fetchPhotos(context) async {
  final response =
      await DefaultAssetBundle.of(context).loadString('assets/data.json');
  return compute(parseChapters, response);
}

List<Chapter> parseChapters(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Chapter>((json) => Chapter.fromJson(json)).toList();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int drawerIndex = 0;
  bool isShowDrawerMenu = true;
  List<Chapter> chapters;
  FlutterTts flutterTts;
  ScrollController _scrollController = new ScrollController();

  Future _speak(text) async {
    // ～
    text = text.replaceAll(new RegExp(r'～'), '　');
    var result = await flutterTts.speak(text);
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
          _scrollController.animateTo(0.0, duration: Duration(milliseconds: 500), curve: Curves.easeOut);
        },
      ));
    }

    drawer.addAll(chapterTile);

    return drawer;
  }

  ListView _buildBodyList(BuildContext context, Chapter chapter) {
    return ListView.builder(
        controller: _scrollController,
        itemCount: chapter.words.length,
        itemBuilder: (context, index) {
          return ListTile(
            trailing: Text("${drawerIndex + 1}/${index + 1}"),
            title: Text(chapter.words[index].hiragana),
            subtitle: Text(
              chapter.words[index].myanmar,
              style: TextStyle(fontFamily: 'Masterpiece'),
            ),
//            selected: true,
//            isThreeLine: true,
//            contentPadding: EdgeInsets.symmetric(vertical: 5),
            onTap: () {
              _speak(chapter.words[index].hiragana);
            },
            onLongPress: () {},
          );
        });
  }

  @override
  void initState() {
    super.initState();
    print('initState');
    fetchPhotos(context).then((data) {
      print('initState data ${data.length}');
      setState(() {
        chapters = data;
      });
    }).catchError((error) {
      print('initState error $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTitle = 'Minna Kotoba 2';
    flutterTts = FlutterTts();
    flutterTts.isLanguageAvailable("ja-JP").then((res) {
      print('ja-JP TTS lang available $res');
      if (res) flutterTts.setLanguage("ja-JP");
    });

    return MaterialApp(
      title: appTitle,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(title: Text(appTitle)),
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
              chapters != null
                  ? _buildBodyList(context, chapters[drawerIndex])
                  : Center(child: CircularProgressIndicator()),
              Icon(Icons.settings),
            ],
            physics: NeverScrollableScrollPhysics(),
          ),
          bottomNavigationBar: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.format_list_numbered_rtl)),
              Tab(icon: Icon(Icons.search)),
              Tab(icon: Icon(Icons.settings)),
            ],
            onTap: (int index) {
              print('tab index $index');
              if (index == 0) {
                setState(() {
                  isShowDrawerMenu = true;
                });
              } else {
                setState(() {
                  isShowDrawerMenu = false;
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

class Vocal {
  final String romaji;
  final String hiragana;
  final String kanji;
  final String english;
  final String myanmar;

  Vocal({this.romaji, this.hiragana, this.kanji, this.english, this.myanmar});

  factory Vocal.fromJson(Map<String, dynamic> json) {
    return Vocal(
      romaji: json['romaji'] as String,
      hiragana: json['hiragana'] as String,
      kanji: json['kanji'] as String,
      english: json['english'] as String,
      myanmar: json['myanmar'] as String,
    );
  }
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
