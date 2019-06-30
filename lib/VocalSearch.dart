import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:minna_kotoba_2/Chapter.dart';
import 'package:minna_kotoba_2/GlobalVar.dart';
import 'package:minna_kotoba_2/Speak.dart';
import 'package:minna_kotoba_2/AppModel.dart';

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

    if (isZawgyi()) {
      query = zawgyiConverter.zawgyiToUnicode(query);
    }

    print('filterSearchs $query');

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

Widget makeSearchList(Vocal vocal, {BuildContext context}) {

  Speak speak = Speak();

  bool isFav =  Provider.of<AppModel>(context).isFav(vocal.no);

  Text myanmarText = Text(vocal.myanmar, style: TextStyle(fontFamily: 'Masterpiece'));

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
      speak.tts(vocal, context);
    },
    onLongPress: () {
      Provider.of<AppModel>(context).toggle(vocal.no, isFav);
    },
  ));
}