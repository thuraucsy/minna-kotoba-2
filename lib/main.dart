import 'dart:convert'; // json using
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // computer using

void main() => runApp(MyApp());

Future<List<Chapter>> fetchPhotos(context) async {
  final response = await DefaultAssetBundle.of(context).loadString('assets/data.json');
  return compute(parseChapters, response);
}

List<Chapter> parseChapters(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Chapter>((json) => Chapter.fromJson(json)).toList();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appTitle = 'Minna Kotoba 2';

    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: Text(appTitle),
        ),
        body: FutureBuilder(
            future: fetchPhotos(context),
            builder: (context, snapshot) {
              if (snapshot.hasError) print(snapshot.error);

              return snapshot.hasData
                  ? VocalList(chapters: snapshot.data)
                  : Center(child: CircularProgressIndicator());
            }
        )
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

class VocalList extends StatelessWidget {
  final List<Chapter> chapters;

  VocalList({Key key, this.chapters}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final vocal = chapters[index];

          return Text(vocal.title);
        }
    );
  }
}