import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:ndef/ndef.dart';
import 'package:ndef/utilities.dart';

void main() {
  group('NDEFRecord blank construction', () {
    test('empty record defaults', () {
      var record = NDEFRecord();
      expect(record.tnf, TypeNameFormat.empty);
      expect(record.decodedType, isNull);
      expect(record.type, isNull);
      expect(record.fullType, isNull);
      expect(record.minPayloadLength, 0);
      expect(record.maxPayloadLength, isNull);
      expect(record.payload, isNull);
    });

    test('UriRecord defaults', () {
      var record = UriRecord();
      expect(record.tnf, TypeNameFormat.nfcWellKnown);
      expect(record.decodedType, 'U');
      expect(ByteUtils.bytesEqual(record.type, Uint8List.fromList([85])),
          isTrue);
      expect(record.fullType, "urn:nfc:wkt:U");
      expect(record.minPayloadLength, 1);
      expect(record.maxPayloadLength, isNull);
      expect(record.prefix, isNull);
      expect(record.iriString, isNull);
      expect(record.uriString, isNull);
      expect(record.uri, isNull);
      expect(record.payload, isNull);
    });

    test('TextRecord defaults', () {
      var record = TextRecord();
      expect(record.encoding, TextEncoding.UTF8);
      expect(record.encodingString, "UTF-8");
      expect(record.language, isNull);
      expect(record.text, isNull);
    });

    test('WellKnownRecord defaults', () {
      var record = WellKnownRecord();
      expect(record.tnf, TypeNameFormat.nfcWellKnown);
      expect(record.payload, isNull);
      expect(record.id, isNull);
    });
  });

  group('NDEFRecord exceptions', () {
    test('invalid URI prefix throws ArgumentError', () {
      expect(() {
        UriRecord().prefix = "test";
      }, throwsArgumentError);
    });
  });
}
