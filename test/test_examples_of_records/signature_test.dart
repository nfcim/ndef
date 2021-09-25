import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/signature.dart';
import 'package:ndef/utilities.dart';

import '../ndef_test.dart';

void main() {
  group('encode and decode', () {
    test('main function', () {
      List<String> hexStrings = [
        "d10306536967200002000000",
        "d1034d536967200b0200473045022100a410c28fd9437fd24f6656f121e62bcc5f65e36257f5faadf68e3e83d40d481a0220335b1dff8d6fe722fcf7018be9684d2de5670b256fdfc02aa25bdae16f624b8000",
      ];

      List<List<NDEFRecord>> messages = [
        [SignatureRecord()],
        [
          SignatureRecord(
              signatureType: 'ECDSA-P256',
              signature: ByteUtils.hexStringToBytes(
                  "3045022100a410c28fd9437fd24f6656f121e62bcc5f65e36257f5faadf68e3e83d40d481a0220335b1dff8d6fe722fcf7018be9684d2de5670b256fdfc02aa25bdae16f624b80"))
        ],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });
  });
  group('ndef message with signature type', () {
    test('SignatureRecord Test', () {
      SignatureRecord sr = new SignatureRecord(
          signatureType: 'ECDSA-P256',
          signature: ByteUtils.hexStringToBytes(
              "3045022100a410c28fd9437fd24f6656f121e62bcc5f65e36257f5faadf68e3e83d40d481a0220335b1dff8d6fe722fcf7018be9684d2de5670b256fdfc02aa25bdae16f624b80"));

      expect(sr.minPayloadLength, equals(6));

      expect(sr.certificateFormat, equals('X.509'));
      expect(sr.certificateFormatIndex, equals(0));
      expect(sr.certificateStore, equals([]));
      expect(sr.certificateURI, equals(''));
      expect(sr.hashTypeIndex, equals(2));

      expect(sr.tnf, equals(TypeNameFormat.nfcWellKnown));
      expect(sr.flags.runtimeType, equals(NDEFRecordFlags));
      expect(sr.signatureURI, equals(''));
      expect(sr.basicInfoString, equals('id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=Sig '));

      expect(sr.type, equals([83, 105, 103]));
      expect(sr.fullType, equals('urn:nfc:wkt:Sig'));
      expect(sr.hashType, equals('SHA-256'));
      expect(sr.runtimeType, equals(SignatureRecord));
      expect(sr.decodedType, equals('Sig'));
      expect(sr.signatureType, equals('ECDSA-P256'));
      expect(sr.signatureTypeIndex, equals(11));
    });
  });
}
