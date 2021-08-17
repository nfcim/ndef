import 'dart:convert';
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
  });
}
