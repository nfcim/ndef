import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:ndef/ndef.dart';
import 'package:ndef/utilities.dart';
import '../../helpers.dart';

void main() {
  group('HandoverRecord', () {
    final hexStrings = [
      'd10201487211',
      '910211487212910202637212345102046163010131005a030201612f62310001',
      '91021248731391020461630101310051030265727201ff5a030201612f62310001',
      '91020a486d13d102046163010161005a0a0301746578742f706c61696e61000102',
      '91021148721291020263721234510204616301013100590205014863310203612f62',
    ];

    final messages = <List<NDEFRecord>>[
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
              carrierDataReference: latin1.encode('1'),
            ),
          ],
        ),
        MimeRecord(
          decodedType: 'a/b',
          id: latin1.encode('1'),
          payload: hexToBytes('0001'),
        ),
      ],
      [
        HandoverSelectRecord(
          error: ErrorRecord(
            errorNum: 1,
            errorData: ByteUtils.intToBytes(255, 1),
          ),
          alternativeCarrierRecordList: [
            AlternativeCarrierRecord(
              carrierPowerState: CarrierPowerState.active,
              carrierDataReference: latin1.encode('1'),
            ),
          ],
        ),
        MimeRecord(
          decodedType: 'a/b',
          id: latin1.encode('1'),
          payload: hexToBytes('0001'),
        ),
      ],
      [
        HandoverMediationRecord(
          versionString: '1.3',
          alternativeCarrierRecordList: [
            AlternativeCarrierRecord(
              carrierPowerState: CarrierPowerState.active,
              carrierDataReference: latin1.encode('a'),
            ),
          ],
        ),
        MimeRecord(
          decodedType: 'text/plain',
          id: latin1.encode('a'),
          payload: hexToBytes('000102'),
        ),
      ],
      [
        HandoverRequestRecord(
          versionString: "1.2",
          collisionResolutionNumber: 0x1234,
          alternativeCarrierRecordList: [
            AlternativeCarrierRecord(
              carrierPowerState: CarrierPowerState.active,
              carrierDataReference: latin1.encode('1'),
            ),
          ],
        ),
        HandoverCarrierRecord(
          carrierTnf: TypeNameFormat.media,
          carrierType: 'a/b',
          carrierData: Uint8List(0),
          id: latin1.encode('1'),
        ),
      ],
    ];

    test('parse from hex', () {
      testParse(hexStrings, messages);
    });

    test('round-trip encode/decode', () {
      testRoundTrip(messages);
    });
  });
}
