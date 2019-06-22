import 'package:flutter/material.dart';
import 'package:transformer_page_view/transformer_page_view.dart';
import 'package:provider/provider.dart';
import 'package:minna_kotoba_2/Chapter.dart';
import 'package:minna_kotoba_2/Speak.dart';
import 'package:minna_kotoba_2/GlobalVar.dart';
import 'package:minna_kotoba_2/AppModel.dart';

class FlashCard extends StatefulWidget {
  final List<Vocal> words;
  final String selectedJapanese;
  final String selectedMeaning;
  final String selectedMemorizing;
  final String appBar;

  FlashCard(this.words, this.selectedJapanese, this.selectedMeaning,
      this.selectedMemorizing, this.appBar);

  @override
  _FlashCardState createState() => new _FlashCardState(appBar);
}

class _FlashCardState extends State<FlashCard> {

  final List<String> toggleNo = [];
  Speak speak = Speak();
  final String appBar;

  _FlashCardState(this.appBar);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(this.appBar),
        centerTitle: false,
      ),
      body: Center(
          child: new TransformerPageView(
              itemBuilder: (BuildContext context, int index) {

                String japanese = widget.words[index].hiragana;
                String meaning = widget.words[index].myanmar;

                if (widget.selectedJapanese == listJapanese[1]) {
                  japanese = widget.words[index].kanji;
                } else if (widget.selectedJapanese == listJapanese[2]) {
                  japanese = widget.words[index].romaji;
                }

                if (widget.selectedMeaning == listMeaning[1]) {
                  meaning = widget.words[index].english;
                }

                Text noText = Text(widget.words[index].no);
                Text hideText= Text(meaning, style: (widget.selectedMeaning == listMeaning[0]) ?
                TextStyle(fontSize: 30.0, fontFamily: 'Masterpiece') :
                TextStyle(fontSize: 30.0));
                Text showText = Text(japanese, style: TextStyle(fontSize: 30.0));

                if (widget.selectedMemorizing == listMemorizing[1]) {
                  Text tmpText = showText;
                  showText = hideText;
                  hideText = tmpText;
                }

                bool isFav =  Provider.of<AppModel>(context).isFav(widget.words[index].no);

                return GestureDetector(
                  child: Card(
                      elevation: 5.0,
                      margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Expanded(
                              child: noText,
                              flex: 5,
                            ),
                            Expanded(
                              child: showText,
                              flex: 35,
                            ),
                            Expanded(
                              child: AnimatedOpacity(
                                opacity: toggleNo.contains(widget.words[index].no) ? 1.0 : 0.0,
                                duration: Duration(milliseconds: 500),
                                child: hideText,
                              ),
                              flex: 50,
                            ),
                            Expanded(
                              child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.redAccent),
                              flex: 10,
                            )
                          ],
                        ),
                      )
                  ),
                  onTap: () {

                    if (toggleNo.contains(widget.words[index].no)) {
                      print('adding ${widget.words[index].no}');
                      setState(() {
                        toggleNo.removeAt(toggleNo.indexOf(widget.words[index].no));
                      });
                    } else {
                      print('removing ${widget.words[index].no}');
                      setState(() {
                        toggleNo.add(widget.words[index].no);
                      });
                    }

                    speak.tts(widget.words[index], context);
                  },
                  onLongPress: () {
                    print('onLongPress');
                    Provider.of<AppModel>(context).toggle(widget.words[index].no, isFav);
                  },
                );
              },
              itemCount: widget.words.length)
      ),
    );
  }
}