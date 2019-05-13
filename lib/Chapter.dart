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