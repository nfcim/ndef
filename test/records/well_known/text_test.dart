import 'package:test/test.dart';

import 'package:ndef/ndef.dart';
import '../../helpers.dart';

void main() {
  group('TextRecord', () {
    test('encode and decode UTF-8', () {
      var hexStrings = [
        "d1010f5402656e48656c6c6f20576f726c6421",
      ];
      var messages = [
        [TextRecord(language: 'en', text: 'Hello World!')],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });

    test('encode and decode UTF-16', () {
      var hexStrings = [
        "d101145485656d6f6a69fffe3dd801de3dd802de3ed828dd",
      ];
      var messages = [
        [
          TextRecord(
            language: 'emoji',
            text: '😁😂🤨',
            encoding: TextEncoding.UTF16,
          ),
        ],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });

    test('payload length > 255 bytes', () {
      var hexStrings = [
        "c1010000013b5402656e4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a4142434445464748494a4b4c4d4e4f505152535455565758595a",
      ];
      var messages = [
        [
          TextRecord(
            language: 'en',
            text: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' * 12,
          ),
        ],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });
  });
}
