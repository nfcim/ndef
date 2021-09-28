import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/ndef.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/handover.dart';
import 'package:ndef/record/mime.dart';
import 'package:ndef/utilities.dart';

void main() {
  group('encode and decode', () {
    test('main function', () {
      List<String> hexStrings = [
        'd10201487211',
        '910211487212910202637212345102046163010131005a030201612f62310001',
        '91021248731391020461630101310051030265727201ff5a030201612f62310001',
        '91020a486d13d102046163010161005a0a0301746578742f706c61696e61000102',
        '91021148721291020263721234510204616301013100590205014863310203612f62'
      ];

      List<List<NDEFRecord>> messages = [
        [
          HandoverRequestRecord(versionString: "1.1"),
        ],
        [
          HandoverRequestRecord(
              versionString: "1.2",
              collisionResolutionNumber: 0x1234,
              alternativeCarrierRecordList: [
                AlternativeCarrierRecord(
                    carrierPowerState: CarrierPowerState.active,
                    carrierDataReference: latin1.encode('1'))
              ]),
          MimeRecord(
              decodedType: 'a/b',
              id: latin1.encode('1'),
              payload: ByteUtils.hexStringToBytes('0001'))
        ],
        [
          HandoverSelectRecord(
              error: ErrorRecord(
                  errorNum: 1, errorData: ByteUtils.intToBytes(255, 1)),
              alternativeCarrierRecordList: [
                AlternativeCarrierRecord(
                    carrierPowerState: CarrierPowerState.active,
                    carrierDataReference: latin1.encode('1'))
              ]),
          MimeRecord(
              decodedType: 'a/b',
              id: latin1.encode('1'),
              payload: ByteUtils.hexStringToBytes('0001'))
        ],
        [
          HandoverMediationRecord(
              versionString: '1.3',
              alternativeCarrierRecordList: [
                AlternativeCarrierRecord(
                    carrierPowerState: CarrierPowerState.active,
                    carrierDataReference: latin1.encode('a'))
              ]),
          MimeRecord(
              decodedType: 'text/plain',
              id: latin1.encode('a'),
              payload: ByteUtils.hexStringToBytes('000102'))
        ],
        [
          HandoverRequestRecord(
              versionString: "1.2",
              collisionResolutionNumber: 0x1234,
              alternativeCarrierRecordList: [
                AlternativeCarrierRecord(
                    carrierPowerState: CarrierPowerState.active,
                    carrierDataReference: latin1.encode('1'))
              ]),
          HandoverCarrierRecord(
              carrierTnf: TypeNameFormat.media,
              carrierType: 'a/b',
              carrierData: Uint8List(0),
              id: latin1.encode('1'))
        ]
      ];

      for (int i = 0; i < hexStrings.length; i++) {
        var decoded =
            decodeRawNdefMessage(ByteUtils.hexStringToBytes(hexStrings[i]));
        assert(decoded.length == messages[i].length);
        for (int j = 0; j < decoded.length; j++) {
          assert(decoded[j].isEqual(messages[i][j]));
        }
      }
      for (int i = 0; i < hexStrings.length; i++) {
        var decoded = decodeRawNdefMessage(encodeNdefMessage(messages[i]));
        assert(decoded.length == messages[i].length);
        for (int j = 0; j < decoded.length; j++) {
          assert(decoded[j].isEqual(messages[i][j]));
        }
      }
    });
    group('ndef message with handover type', () {
      test('AlternativeCarrierRecord Test', () {
        AlternativeCarrierRecord acr = new AlternativeCarrierRecord(
            carrierPowerState: CarrierPowerState.inactive,
            carrierDataReference: latin1.encode('0'));
        expect(acr.auxDataReferenceList, equals([]));
        expect(acr.carrierDataReference, equals([48]));
        expect(acr.carrierPowerState, equals(CarrierPowerState.inactive));
        expect(AlternativeCarrierRecord.classMinPayloadLength, equals(2));
        expect(AlternativeCarrierRecord.classType, equals('ac'));
      });

      test('CollisionResolutionRecord Test', () {
        // Randomly generate number
        var rng = new Random(10);
        var randomNum123 = rng.nextInt(100);

        CollisionResolutionRecord crr =
            new CollisionResolutionRecord(randomNumber: randomNum123);
        expect(crr.maxPayloadLength, equals(2));
        expect(crr.minPayloadLength, equals(2));

        expect(crr.randomNumber, equals(75));
        expect(
            crr.basicInfoString,
            equals(
                "id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=cr "));

        expect(crr.decodedType, equals('cr'));
        expect(crr.runtimeType, equals(CollisionResolutionRecord));
        expect(crr.fullType, equals('urn:nfc:wkt:cr'));
        expect(crr.type, equals([99, 114]));

        expect(crr.tnf, equals(TypeNameFormat.nfcWellKnown));
        expect(crr.flags.runtimeType, equals(NDEFRecordFlags));
        expect(crr.payload, equals([0, 75]));
      });

      test('ErrorRecord Test', () {
        int errorNum123 = 1;
        List<int> errorData123 = [1, 2, 3, 4, 5, 6, 7, 8];
        ErrorRecord er = new ErrorRecord(
            errorNum: errorNum123, errorData: Uint8List.fromList(errorData123));

        expect(er.minPayloadLength, equals(1));

        expect(er.errorData, equals([1, 2, 3, 4, 5, 6, 7, 8]));
        expect(er.errorNum, equals(1));
        expect(er.errorReason, equals(ErrorReason.temporarilyOutOfMemory));
        expect(
            er.basicInfoString,
            equals(
                'id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=err '));

        expect(er.decodedType, equals('err'));
        expect(er.runtimeType, equals(ErrorRecord));
        expect(er.fullType, equals('urn:nfc:wkt:err'));
        expect(er.type, equals([101, 114, 114]));

        expect(er.tnf, equals(TypeNameFormat.nfcWellKnown));
        expect(er.flags.runtimeType, equals(NDEFRecordFlags));
      });

      test('HandoverRecord Test', () {
        AlternativeCarrierRecord acr = new AlternativeCarrierRecord(
            carrierPowerState: CarrierPowerState.inactive,
            carrierDataReference: latin1.encode('0'));

        List<AlternativeCarrierRecord> listAcr = [acr];
        HandoverRecord hr =
            new HandoverRecord(alternativeCarrierRecordList: listAcr);

        expect(hr.minPayloadLength, equals(1));

        String allRecordListToString = hr.allRecordList.toString();
        expect(
            allRecordListToString,
            equals(
                '[AlternativeCarrierRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=ac carrierPowerState=CarrierPowerState.inactive carrierDataReference=[48] auxDataReferences=[]]'));
        String alternativeCarrierRecordListToString =
            hr.alternativeCarrierRecordList.toString();
        expect(
            alternativeCarrierRecordListToString,
            equals(
                '[AlternativeCarrierRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=ac carrierPowerState=CarrierPowerState.inactive carrierDataReference=[48] auxDataReferences=[]]'));
        expect(hr.unknownRecordList, equals([]));

        expect(hr.flags.runtimeType, equals(NDEFRecordFlags));
        expect(hr.tnf, equals(TypeNameFormat.nfcWellKnown));
        expect(
            hr.basicInfoString,
            equals(
                'id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=null '));

        expect(hr.runtimeType, equals(HandoverRecord));
      });

      test('HandoverRequestRecord Test', () {
        // CollisionResolutionRecord
        // Randomly generate number
        var rng = new Random(10);
        var randomNum123 = rng.nextInt(100);

        // AlternativeCarrierRecord
        AlternativeCarrierRecord acr = new AlternativeCarrierRecord(
            carrierPowerState: CarrierPowerState.inactive,
            carrierDataReference: latin1.encode('0'));

        List<AlternativeCarrierRecord> listAcr = [acr];
        HandoverRequestRecord hrr = new HandoverRequestRecord(
            collisionResolutionNumber: randomNum123,
            alternativeCarrierRecordList: listAcr);

        expect(hrr.minPayloadLength, equals(1));

        expect(hrr.collisionResolutionNumber, equals(75));

        String allRecordListToString = hrr.allRecordList.toString();
        expect(
            allRecordListToString,
            equals(
                '[AlternativeCarrierRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=ac carrierPowerState=CarrierPowerState.inactive carrierDataReference=[48] auxDataReferences=[], CollisionResolutionRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=cr randomNumber=75]'));
        expect(hrr.unknownRecordList, equals([]));
        String alternativeCarrierRecordListToString =
            hrr.alternativeCarrierRecordList.toString();
        expect(
            alternativeCarrierRecordListToString,
            equals(
                '[AlternativeCarrierRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=ac carrierPowerState=CarrierPowerState.inactive carrierDataReference=[48] auxDataReferences=[]]'));
        String collisionResolutionRecordListToString =
            hrr.collisionResolutionRecordList.toString();
        expect(
            collisionResolutionRecordListToString,
            equals(
                '[CollisionResolutionRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=cr randomNumber=75]'));

        expect(
            hrr.basicInfoString,
            equals(
                'id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=Hr '));
        expect(hrr.tnf, equals(TypeNameFormat.nfcWellKnown));
        expect(hrr.flags.runtimeType, equals(NDEFRecordFlags));

        expect(hrr.decodedType, equals('Hr'));
        expect(hrr.fullType, equals('urn:nfc:wkt:Hr'));
        expect(hrr.type, equals([72, 114]));
        expect(hrr.runtimeType, equals(HandoverRequestRecord));
      });

      test('HandoverSelectRecord Test', () {
        //TODO: waiting for handling the errorRecord();
        // AlternativeCarrierRecord
        AlternativeCarrierRecord acr = new AlternativeCarrierRecord(
            carrierPowerState: CarrierPowerState.inactive,
            carrierDataReference: latin1.encode('0'));

        List<AlternativeCarrierRecord> listAcr = [acr];

        // ErrorRecord
        int errorNum123 = 1;
        List<int> errorData123 = [1, 2, 3, 4, 5, 6, 7, 8];
        ErrorRecord er = new ErrorRecord(
            errorNum: errorNum123, errorData: Uint8List.fromList(errorData123));
        HandoverSelectRecord hsr = new HandoverSelectRecord(
            error: er, alternativeCarrierRecordList: listAcr);

        expect(hsr.minPayloadLength, equals(1));

        expect(
            hsr.error.toString(),
            equals(
                'ErrorRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=err error=temporarily out of memory, may retry after 72623859790382856 milliseconds'));

        expect(
            hsr.alternativeCarrierRecordList.toString(),
            equals(
                '[AlternativeCarrierRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=ac carrierPowerState=CarrierPowerState.inactive carrierDataReference=[48] auxDataReferences=[]]'));
        expect(
            hsr.allRecordList.toString(),
            equals(
                '[AlternativeCarrierRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=ac carrierPowerState=CarrierPowerState.inactive carrierDataReference=[48] auxDataReferences=[], ErrorRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=err error=temporarily out of memory, may retry after 72623859790382856 milliseconds]'));
        expect(
            hsr.errorRecordList.toString(),
            equals(
                '[ErrorRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=err error=temporarily out of memory, may retry after 72623859790382856 milliseconds]'));

        expect(hsr.tnf, equals(TypeNameFormat.nfcWellKnown));
        expect(
            hsr.basicInfoString,
            equals(
                'id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=Hs '));
        expect(hsr.flags.runtimeType, equals(NDEFRecordFlags));

        expect(hsr.type, equals([72, 115]));
        expect(hsr.fullType, equals('urn:nfc:wkt:Hs'));
        expect(hsr.decodedType, equals('Hs'));
        expect(hsr.runtimeType, equals(HandoverSelectRecord));
      });

      test('HandoverMediationRecord Test', () {
        // AlternativeCarrierRecord
        AlternativeCarrierRecord acr = new AlternativeCarrierRecord(
            carrierPowerState: CarrierPowerState.inactive,
            carrierDataReference: latin1.encode('0'));

        List<AlternativeCarrierRecord> listAcr = [acr];

        HandoverMediationRecord hmr =
            new HandoverMediationRecord(alternativeCarrierRecordList: listAcr);

        expect(hmr.minPayloadLength, equals(1));

        expect(
            hmr.alternativeCarrierRecordList.toString(),
            equals(
                '[AlternativeCarrierRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=ac carrierPowerState=CarrierPowerState.inactive carrierDataReference=[48] auxDataReferences=[]]'));
        expect(
            hmr.allRecordList.toString(),
            equals(
                '[AlternativeCarrierRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=ac carrierPowerState=CarrierPowerState.inactive carrierDataReference=[48] auxDataReferences=[]]'));
        expect(hmr.unknownRecordList, equals([]));

        expect(hmr.tnf, equals(TypeNameFormat.nfcWellKnown));
        expect(hmr.flags.runtimeType, equals(NDEFRecordFlags));

        expect(hmr.type, equals([72, 109]));
        expect(hmr.decodedType, equals('Hm'));
        expect(hmr.fullType, equals('urn:nfc:wkt:Hm'));
        expect(hmr.runtimeType, equals(HandoverMediationRecord));
      });

      test('HandoverInitiateRecord Test', () {
        // AlternativeCarrierRecord
        AlternativeCarrierRecord acr = new AlternativeCarrierRecord(
            carrierPowerState: CarrierPowerState.inactive,
            carrierDataReference: latin1.encode('0'));

        List<AlternativeCarrierRecord> listAcr = [acr];

        HandoverInitiateRecord hir =
            new HandoverInitiateRecord(alternativeCarrierRecordList: listAcr);

        expect(hir.minPayloadLength, equals(1));

        expect(
            hir.allRecordList.toString(),
            equals(
                '[AlternativeCarrierRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=ac carrierPowerState=CarrierPowerState.inactive carrierDataReference=[48] auxDataReferences=[]]'));
        expect(
            hir.alternativeCarrierRecordList.toString(),
            equals(
                '[AlternativeCarrierRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=ac carrierPowerState=CarrierPowerState.inactive carrierDataReference=[48] auxDataReferences=[]]'));
        expect(hir.unknownRecordList, equals([]));

        expect(hir.tnf, equals(TypeNameFormat.nfcWellKnown));
        expect(
            hir.basicInfoString,
            equals(
                'id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=Hi '));
        expect(hir.flags.runtimeType, equals(NDEFRecordFlags));

        expect(hir.type, equals([72, 105]));
        expect(hir.fullType, equals('urn:nfc:wkt:Hi'));
        expect(hir.decodedType, equals('Hi'));
        expect(hir.runtimeType, equals(HandoverInitiateRecord));
      });
    });

    test('HandoverCarrierRecord Test', () {
      List<int> carrierDataList = [1, 2, 3];
      HandoverCarrierRecord hcr = new HandoverCarrierRecord(
          carrierTnf: TypeNameFormat.nfcWellKnown,
          carrierType: 'carrierTypeTest',
          carrierData: Uint8List.fromList(carrierDataList));

      expect(hcr.minPayloadLength, equals(1));

      expect(hcr.tnf, equals(TypeNameFormat.nfcWellKnown));
      expect(hcr.flags.runtimeType, equals(NDEFRecordFlags));

      expect(hcr.type, equals([72, 99]));
      expect(hcr.decodedType, equals('Hc'));
      expect(hcr.fullType, equals('urn:nfc:wkt:Hc'));
      expect(hcr.runtimeType, equals(HandoverCarrierRecord));
      expect(hcr.carrierType, equals('carrierTypeTest'));

      expect(hcr.carrierData, equals([1, 2, 3]));
      expect(hcr.carrierTnf, equals(TypeNameFormat.nfcWellKnown));
      expect(
          hcr.basicInfoString,
          equals(
              'id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=Hc '));
    });
  });
}
