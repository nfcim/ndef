import 'package:test/test.dart';

import 'package:ndef/ndef.dart';
import '../../helpers.dart';

void main() {
  group('DeviceInformationRecord', () {
    test('encode and decode', () {
      var hexStrings = [
        "d1023b446900056e6663696d01096e666344657669636502076e66634e616d6503106361ae18d5b011ea9d0840a3ccfd09570405312e302e30ff054e4643494d",
      ];
      var messages = [
        [
          DeviceInformationRecord(
            vendorName: "nfcim",
            modelName: "nfcDevice",
            uniqueName: "nfcName",
            uuid: "6361ae18-d5b0-11ea-9d08-40a3ccfd0957",
            versionString: "1.0.0",
            undefinedData: [
              DataElement.fromString(255, "NFCIM"),
            ],
          ),
        ],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });
  });
}
