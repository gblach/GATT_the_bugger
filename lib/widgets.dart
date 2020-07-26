import 'package:flutter/material.dart';

ThemeData app_theme() {
  return ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: Colors.grey[200],
    textTheme: TextTheme(
      button: TextStyle(fontSize: 15, color: Colors.white),
    ),
    cardTheme: CardTheme(color: Colors.white),
    buttonTheme: ButtonThemeData(
      height: 40,
      minWidth: 100,
      buttonColor: Colors.indigo[400],
    ),
  );
}

Widget infobar(BuildContext context, String left, [String right]) {
  TextStyle style = TextStyle(color: Theme.of(context).textTheme.caption.color);

  return Container(
    child: Row(
      children: [
        Text(left, style: style),
        right != null ? Text(right, style: style) : SizedBox(),
      ],
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
    ),
    color: Theme.of(context).cardTheme.color,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  );
}

Widget loader(String title, String subtitle) {
  return Center(child: Card(
    child: Padding(
      child: ListTile(
        leading: CircularProgressIndicator(),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    ),
    margin: EdgeInsets.only(bottom: 80),
    shape: RoundedRectangleBorder(),
  ));
}
