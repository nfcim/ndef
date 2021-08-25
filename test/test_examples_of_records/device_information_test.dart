import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/deviceinfo.dart';

import '../ndef_test.dart';

void main(){
  group('encode and decode', (){
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

    test('test the all parts of a record', (){
      expect(deviceInfoRecord.id, equals(null));
      expect(deviceInfoRecord.payload, equals([0, 5, 110, 102, 99, 105, 109, 1, 9, 110, 102, 99, 68, 101, 118, 105, 99, 101, 2, 7, 110, 102, 99, 78, 97, 109, 101, 3, 16, 99, 97, 174, 24, 213, 176, 17, 234, 157, 8, 64, 163, 204, 253, 9, 87, 4, 5, 49, 46, 48, 46, 48, 255, 5, 78, 70, 67, 73, 77]));
      expect(deviceInfoRecord.uuidData, equals([99, 97, 174, 24, 213, 176, 17, 234, 157, 8, 64, 163, 204, 253, 9, 87]));

      expect(deviceInfoRecord.tnf, equals(TypeNameFormat.nfcWellKnown));
      expect(deviceInfoRecord.flags.runtimeType, equals(NDEFRecordFlags));

      expect(deviceInfoRecord.type, equals([68, 105]));
      expect(deviceInfoRecord.fullType, equals('urn:nfc:wkt:Di'));
      expect(deviceInfoRecord.decodedType, equals('Di'));

      expect(deviceInfoRecord.basicInfoString, equals('id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=Di '));
      expect(deviceInfoRecord.maxPayloadLength, equals(null));
      expect(deviceInfoRecord.minPayloadLength, equals(2));
    });

    test('test some exceptions', (){
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

      expect((){
        var value = [1, 9, 110, 102, 99, 68, 101, 118, 105, 99, 101, 2, 7, 110, 102, 99, 78, 97, 109, 101, 3, 16, 99, 97, 174, 24, 213, 176, 17, 234, 157, 8, 64, 163, 204, 253, 9, 87, 4, 5, 49, 46, 48, 46, 48, 255, 5, 78, 70, 67, 73, 77];
        deviceInfoRecord.payload = Uint8List.fromList(value);      }, throwsArgumentError);
    });
  });
}