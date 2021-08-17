import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/ndef.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/uri.dart';

import 'ndef_test.dart';

void main() {
  test('ndef message with uri type', () {
    List<String> hexStrings = [
      "9101165504676974    6875622e    636f6d2f6e6663696d2f6e64656651010b55046769746875622e636f6d",
    ];

    List<List<NDEFRecord>> messages = [
      [
        UriRecord.fromString("https://github.com/nfcim/ndef"),
        UriRecord.fromString("https://github.com")
      ],
    ];

    String hex = hexStrings[0].splitMapJoin(" ", onMatch: (Match match) {
      return "";
    });

    var result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      // print(int.parse(hex.substring(i, i + 2), radix: 16));
      print(int.parse(hex.substring(i, i+2), radix: 16));
    }

    // print(hexStrings[0].toBytes());
    // print(decodeRawNdefMessage(hexStrings[0].toBytes()));
  });
}
