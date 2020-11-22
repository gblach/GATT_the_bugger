import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DataType { hex, string }

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

class HexFormatter extends TextInputFormatter {
  RegExp filter = RegExp(r"[^0-9a-fA-F]+");
  RegExp hexpair = RegExp(r"([0-9a-fA-F]{2})");
  DataType data_type;

  HexFormatter(this.data_type);

  formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if(this.data_type == DataType.hex) {
      String newText = newValue.text.replaceAll(filter, '');
      newText = newText.replaceAllMapped(hexpair, (Match m) => m[1] + ' ');
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