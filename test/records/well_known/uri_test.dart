import 'package:test/test.dart';

import 'package:ndef/ndef.dart';
import '../../helpers.dart';

void main() {
  group('UriRecord', () {
    test('encode and decode', () {
      var hexStrings = [
        "91011655046769746875622e636f6d2f6e6663696d2f6e64656651010b55046769746875622e636f6d",
      ];
      var messages = [
        [
          UriRecord.fromString("https://github.com/nfcim/ndef"),
          UriRecord.fromString("https://github.com"),
        ],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });

    test('invalid prefix throws', () {
      expect(() {
        UriRecord().prefix = "test";
      }, throwsArgumentError);
    });
  });

  group('AbsoluteUriRecord', () {
    test('encode and decode', () {
      var hexStrings = [
        '931d0068747470733a2f2f6769746875622e636f6d2f6e6663696d2f6e64656653120068747470733a2f2f6769746875622e636f6d',
      ];
      var messages = [
        [
          AbsoluteUriRecord(uri: "https://github.com/nfcim/ndef"),
          AbsoluteUriRecord(uri: "https://github.com"),
        ],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });
  });
}
