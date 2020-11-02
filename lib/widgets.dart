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
  RegExp filter = RegExp(r"[0-9a-fA-F]");
  DataType data_type;

  HexFormatter(this.data_type);

  formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if(this.data_type == DataType.hex) {
      int len = newValue.text.length;
      String last = len > 0 ? newValue.text.substring(len - 1) : '';

      if(oldValue.text.length < newValue.text.length) {
        if(! filter.hasMatch(last)) {
          return TextEditingValue(
            text: newValue.text.substring(0, len - 1),
            selection: TextSelection.collapsed(offset: len - 1),
          );
        }
        if(len % 3 == 0) {
          return TextEditingValue(
            text: newValue.text.substring(0, len - 1) + ' ' + newValue.text.substring(len - 1),
            selection: TextSelection.collapsed(offset: len + 1),
          );
        }
      } else if(oldValue.text.length > newValue.text.length) {
        if(last == ' ') {
          return TextEditingValue(
            text: newValue.text.substring(0, len - 1),
            selection: TextSelection.collapsed(offset: len - 1),
          );
        }
      }
    }

    return newValue;
  }
}