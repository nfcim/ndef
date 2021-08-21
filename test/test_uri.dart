import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/ndef.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/uri.dart';

import 'ndef_test.dart';

void main() {
  group('ndef message with uri type', (){
    final urlName = "https://github.com/nfcim/ndef";
    final urlName2 = "https://github.com";
    List<String> hexStrings = [
      "91011655046769746875622e636f6d2f6e6663696d2f6e64656651010b55046769746875622e636f6d",
    ];

    List<String> hexStringsWithBlank = [
      // test the robustness of function which handles the  hexStrings.
      "910116550467  69746875622e636f6   d2f6e6663696d2f6e64656651010b55046769746875622e636f6d",
    ];

    List<List<NDEFRecord>> messagesString = [
      [
        UriRecord.fromString(urlName),
        UriRecord.fromString(urlName2)
      ],
    ];

    List<List<NDEFRecord>> messagesUri = [
      [
        UriRecord.fromUri(Uri.parse('https://github.com/nfcim/ndef')),
        UriRecord.fromUri(Uri.parse('https://github.com'))
      ],
    ];

    test('ndef message with uri type (format of String and Uri)', () {
      // Part I: test the function of ENCODE and DECODE.
      expect(testParse(hexStrings, messagesString), true);
      expect(testGenerate(hexStrings, messagesString), true);
      expect(testParse(hexStrings, messagesUri), true);
      expect(testGenerate(hexStrings, messagesUri), true);
    });

    test('A collection of situations that may occur', () {
      // Part I: test the function of ENCODE and DECODE.
      expect(testParse(hexStringsWithBlank, messagesString), true);
      expect(testGenerate(hexStringsWithBlank, messagesString), false);
    });

    test('test the all parts of a record', () {
      print(UriRecord.fromString(urlName).id);
      print(UriRecord.fromString(urlName).runtimeType);
      expect(UriRecord.fromString(urlName2).payload, [4, 103, 105, 116, 104, 117, 98, 46, 99, 111, 109]);
    });
  });
}
