import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/bluetooth.dart';

import '../ndef_test.dart';

void main() {
  group('decode and encode', () {
    test('main function', () {
      List<String> hexStrings = [
        "d2200b6170706c69636174696f6e2f766e642e626c7565746f6f74682e65702e6f6f620b0006050403020102ff61",
      ];

      List<List<NDEFRecord>> messages = [
        [
          BluetoothEasyPairingRecord(
              address: EPAddress(address: "06:05:04:03:02:01"),
              attributes: {
                EIRType.ManufacturerSpecificData: Uint8List.fromList([97])
              })
        ],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });
  });
}
