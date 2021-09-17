import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/text.dart';

import '../ndef_test.dart';

void main() {
  group('encode and decode', () {
    test("main function", () {
      List<String> hexStrings = [
        "d1010f5402656e48656c6c6f20576f726c6421",
        "d101145485656d6f6a69fffe3dd801de3dd802de3ed828dd"
      ];

      List<List<NDEFRecord>> messages = [
        [TextRecord(language: 'en', text: 'Hello World!')],
        [
          TextRecord(
              language: 'emoji', text: '😁😂🤨', encoding: TextEncoding.UTF16)
        ],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });
  });
}