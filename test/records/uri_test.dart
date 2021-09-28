import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/ndef.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/uri.dart';

import '../common.dart';

void main() {
  group('encode and decode', () {
    test('uri record', () {
      final urlName = "https://github.com/nfcim/ndef";
      final urlName2 = "https://github.com";

      List<String> hexStrings = [
        "91011655046769746875622e636f6d2f6e6663696d2f6e64656651010b55046769746875622e636f6d",
      ];

      List<List<NDEFRecord>> messages = [
        [UriRecord.fromString(urlName), UriRecord.fromString(urlName2)],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });
  });

  group('ndef message with uri type', () {
    final urlName = "https://github.com/nfcim/ndef";

    test('test the all parts of a record', () {
      expect(UriRecord.fromString(urlName).id, equals(null));
      expect(UriRecord.fromString(urlName).uri, equals(Uri.parse(urlName)));

      expect(UriRecord.fromString(urlName).uriString, equals(urlName));
      expect(UriRecord.fromString(urlName).iriString, equals(urlName));

      List<String> hexStringsTest = [
        "046769746875622e636f6d2f6e6663696d2f6e646566",
      ];
      expect(UriRecord.fromString(urlName).payload,
          equals(hexStringsTest[0].toBytes()));
      expect(UriRecord.fromString(urlName).tnf,
          equals(TypeNameFormat.nfcWellKnown));
      expect(UriRecord.fromString(urlName).flags.runtimeType,
          equals(NDEFRecordFlags));

      var comparisonValue;
      for (int i = 0; i < UriRecord.prefixMap.length; i++) {
        if (UriRecord.prefixMap[i] == UriRecord.fromString(urlName).prefix) {
          comparisonValue = UriRecord.prefixMap[i];
        }
      }
      var actualValue = UriRecord.fromString(urlName).prefix;
      expect(UriRecord.fromString(urlName).prefix, equals(comparisonValue));
      expect(UriRecord.fromString(urlName).content,
          equals(urlName.replaceAll("$actualValue", "")));

      expect(UriRecord.fromString(urlName).type, equals([85]));
      expect(UriRecord.fromString(urlName).fullType, equals('urn:nfc:wkt:U'));
      expect(UriRecord.fromString(urlName).decodedType, equals('U'));
      expect(UriRecord.fromString(urlName).runtimeType, equals(UriRecord));

      expect(
          UriRecord.fromString(urlName).basicInfoString,
          equals(
              'id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=U '));
      expect(UriRecord.fromString(urlName).maxPayloadLength, equals(null));
      expect(UriRecord.fromString(urlName).minPayloadLength, equals(1));

      expect(UriRecord.fromString(urlName).idString, equals('(empty)'));
      expect(
          UriRecord.fromString(urlName).toString(),
          equals(
              'UriRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=U uri=https://github.com/nfcim/ndef'));
    });

    test('test some exceptions', () {
      final urlWrongPrefix = "http://github.com/nfcim/ndef";
      expect(() {
        UriRecord.fromString(urlWrongPrefix).prefix = "htttp://";
      }, throwsArgumentError);
    });
  });
}
