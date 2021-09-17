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
}