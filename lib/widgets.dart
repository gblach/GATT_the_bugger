import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DataType { hex, string }

ThemeData app_theme() {
  return ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: Colors.grey[200],
    cardTheme: CardTheme(color: Colors.white),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
      textStyle: TextStyle(fontSize: 16),
      primary: Colors.indigo[800],
      padding: EdgeInsets.only(right: 16),
    )),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      textStyle: TextStyle(fontSize: 15),
      primary: Colors.indigo[400],
      minimumSize: Size(100, 40),
    )),
  );
}

Widget infobar(BuildContext context, String left,
  [String? right, Brightness brightness=Brightness.light]) {
  late TextStyle style;
  late Color background;

  switch(brightness) {
    case Brightness.light:
      style = TextStyle(color: Theme.of(context).textTheme.caption!.color);
      background = Theme.of(context).cardTheme.color!;
      break;

    case Brightness.dark:
      style = TextStyle(color: Colors.grey[100]);
      background = Colors.indigo[600]!;
      break;
  }

  return Container(
    child: Row(
      children: [
        Text(left, style: style),
        right != null ? Text(right, style: style) : SizedBox(),
      ],
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
    ),
    color: background,
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

class HexFormatter extends TextInputFormatter {
  final RegExp filter = RegExp(r"[^0-9a-fA-F]+");
  final RegExp hexpair = RegExp(r"([0-9a-fA-F]{2})");
  DataType data_type;

  HexFormatter(this.data_type);

  formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if(this.data_type == DataType.hex) {
      String newText = newValue.text.replaceAll(filter, '');
      newText = newText.replaceAllMapped(hexpair, (Match m) => m[1]! + ' ');
      newText = newText.trimRight();

      int offset = newValue.selection.baseOffset;
      if(oldValue.text.length < newValue.text.length) {
        if(oldValue.text.length == newText.length) offset--;
        else if(offset % 3 == 0) offset++;
      } else if(oldValue.text.length > newValue.text.length) {
        if(offset % 3 == 0) offset--;
      }

      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: offset),
      );
    }

    return newValue;
  }
}