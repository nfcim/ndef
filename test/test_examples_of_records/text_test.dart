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

  group('ndef message with text type', () {
    test('TextRecord Test', () {
      TextRecord tr = new TextRecord(language: 'emoji', text: 'Hello World!');

      expect(tr.minPayloadLength, equals(1));

      expect(tr.text, equals('Hello World!'));
      expect(tr.language, equals('emoji'));
      expect(tr.encoding, equals(TextEncoding.UTF8));
      expect(tr.encodingString, equals('UTF-8'));

      expect(tr.type, equals([84]));
      expect(tr.fullType, equals('urn:nfc:wkt:T'));
      expect(tr.decodedType, equals('T'));
      expect(tr.runtimeType, equals(TextRecord));

      expect(tr.tnf, equals(TypeNameFormat.nfcWellKnown));
      expect(tr.flags.runtimeType, equals(NDEFRecordFlags));
      expect(
          tr.basicInfoString,
          equals(
              'id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=T '));
    });
  });
}
