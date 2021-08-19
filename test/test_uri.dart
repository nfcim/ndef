import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/ndef.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/uri.dart';

import 'ndef_test.dart';

void main() {
  test('ndef message with uri type', () {
    List<String> hexStrings = [
      // test the robustness of function which handles the  hexStrings.
      "9101165504676974687 5622e636f6d2f6e 6663696d2f6e646566510 10b55046769746875622e636f6d",
    ];

    List<List<NDEFRecord>> messages = [
      [
        UriRecord.fromString("https://github.com/nfcim/ndef"),
        UriRecord.fromString("https://github.com")
      ],
    ];

    // Part I: test the function of ENCODE and DECODE.
    testParse(hexStrings, messages);
    testGenerate(hexStrings, messages);
  });

  test('ndef message with ', () {
    List<String> hexStrings = [
      // test the robustness of function which handles the  hexStrings.
      "910   11655046769746875622e636f6d2f   6e6663696d2f6e64656651010b55046769746875622e636f6d",
    ];

    List<List<NDEFRecord>> messages = [
      [
        UriRecord.fromUri(Uri.parse('https://github.com/nfcim/ndef')),
        UriRecord.fromUri(Uri.parse('https://github.com'))
      ],
    ];

    testParse(hexStrings, messages);
    testGenerate(hexStrings, messages);
  });
}
