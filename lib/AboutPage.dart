import 'package:flutter/material.dart';
import 'GlobalVar.dart';

class AboutPage extends StatelessWidget {
  Widget createContainer(input) {
    return Container(
      margin: EdgeInsets.only(top: 16.0),
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            input,
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("$appTitle $appVersion"),
        ),
        body: Padding(
            padding: EdgeInsets.all(16.0),
            child: ListView(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    logoImg(),
                    createContainer(
                        "The app is for who learning the Japanese Language. Although it\'s mainly focused for Myanmar people, it\'s prepared for English too. The app is very simple and added easy to use features such as tapping the title and go back to the top of the list, shuffle the vocabularies, flash card etc. When we learn a new language, trying to remember the vocabularies is difficult and big challenge. I hope this app will help you remembering the vocabularies (total 2353) easily. \n\nAll the best"),
                    createContainer("CREATED BY THURA AUNG"),
                    createContainer("THANKS TO NONO AND PAUL DENISOWSKI"),
                    createContainer("Facebook page https://fb.com/minnakotoba"),
                    createContainer("Resource from \nhttp://www.denisowski.org/Japanese/Japanese.html,\nWin Japanese Language School (Minna I) and \nYaYaYa Japanese School (Minna II)")
                  ],
                )
              ],
            )));
  }
}
