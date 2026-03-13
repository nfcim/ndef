import 'package:test/test.dart';

import 'package:ndef/ndef.dart';
import 'package:ndef/utilities.dart';
import '../../helpers.dart';

void main() {
  group('SignatureRecord', () {
    test('encode and decode empty signature', () {
      var hexStrings = [
        "d10306536967200002000000",
      ];
      var messages = [
        [SignatureRecord()],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });

    test('encode and decode ECDSA-P256 signature', () {
      var hexStrings = [
        "d1034d536967200b0200473045022100a410c28fd9437fd24f6656f121e62bcc5f65e36257f5faadf68e3e83d40d481a0220335b1dff8d6fe722fcf7018be9684d2de5670b256fdfc02aa25bdae16f624b8000",
      ];
      var messages = [
        [
          SignatureRecord(
            signatureType: 'ECDSA-P256',
            signature: ByteUtils.hexStringToBytes(
              "3045022100a410c28fd9437fd24f6656f121e62bcc5f65e36257f5faadf68e3e83d40d481a0220335b1dff8d6fe722fcf7018be9684d2de5670b256fdfc02aa25bdae16f624b80",
            ),
          ),
        ],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });
  });
}
