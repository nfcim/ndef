import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/ndef.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/deviceinfo.dart';

import '../ndef_test.dart';

void main() {
  group('encode and decode', () {
    test('main function', () {
      List<String> hexStrings = [
        "d1023b446900056e6663696d01096e666344657669636502076e66634e616d6503106361ae18d5b011ea9d0840a3ccfd09570405312e302e30ff054e4643494d",
      ];

      List<List<NDEFRecord>> messages = [
        [
          DeviceInformationRecord(
              vendorName: "nfcim",
              modelName: "nfcDevice",
              uniqueName: "nfcName",
              uuid: "6361ae18-d5b0-11ea-9d08-40a3ccfd0957",
              versionString: "1.0.0",
              undefinedData: [
                DataElement.fromString(255, "NFCIM"),
              ])
        ],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });
  });

  group('ndef message with device information type', () {
    DeviceInformationRecord deviceInfoRecord = DeviceInformationRecord(
        vendorName: "nfcim",
        modelName: "nfcDevice",
        uniqueName: "nfcName",
        uuid: "6361ae18-d5b0-11ea-9d08-40a3ccfd0957",
        versionString: "1.0.0",
        undefinedData: [
          DataElement.fromString(255, "NFCIM"),
        ]);

    test('test the all parts of a record', () {
      expect(deviceInfoRecord.id, equals(null));

      String hexStringUsedInExpect1 = "00056e6663696d01096e666344657669636502076e66634e616d6503106361ae18d5b011ea9d0840a3ccfd09570405312e302e30ff054e4643494d";
      expect(deviceInfoRecord.payload, equals(hexStringUsedInExpect1.toBytes()));

      expect(deviceInfoRecord.tnf, equals(TypeNameFormat.nfcWellKnown));
      expect(deviceInfoRecord.flags.runtimeType, equals(NDEFRecordFlags));

      expect(deviceInfoRecord.type, equals([68, 105]));
      expect(deviceInfoRecord.fullType, equals('urn:nfc:wkt:Di'));
      expect(deviceInfoRecord.decodedType, equals('Di'));

      expect(
          deviceInfoRecord.basicInfoString,
          equals(
              'id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=Di '));
      expect(deviceInfoRecord.maxPayloadLength, equals(null));
      expect(deviceInfoRecord.minPayloadLength, equals(2));
    });

    test('test some exceptions', () {
      DeviceInformationRecord deviceInfoRecord = DeviceInformationRecord(
          vendorName: null,
          modelName: "nfcDevice",
          uniqueName: "nfcName",
          uuid: "6361ae18-d5b0-11ea-9d08-40a3ccfd0957",
          versionString: "1.0.0",
          undefinedData: [
            DataElement.fromString(255, "NFCIM"),
          ]);

      expect(() {
        deviceInfoRecord.payload;
      }, throwsArgumentError);

      expect(() {
        String hexStringUsedInExpect2 = "01096e666344657669636502076e66634e616d6503106361ae18d5b011ea9d0840a3ccfd09570405312e302e30ff054e4643494d";
        deviceInfoRecord.payload = hexStringUsedInExpect2.toBytes();
      }, throwsArgumentError);
    });
  });
}
