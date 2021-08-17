import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/uri.dart';

void main() {
  test('ndef message with uri type', () {
    List<String> hexStrings = [
      "91011655046769746875622e636f6d2f6e6663696d2f6e64656651010b55046769746875622e636f6d",
    ];

    List<List<NDEFRecord>> messages = [
      [
        UriRecord.fromString("http://github.com/nfcim/ndef"),
        UriRecord.fromString("http://github.com/nfcim/ndef"),
        UriRecord.fromString("https://github.com/nfcim/ndef")
      ],
    ];
    print(NDEFRecord.classTnf.toString());
  });
}
