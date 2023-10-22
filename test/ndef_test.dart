import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:ndef/ndef.dart';
import 'package:ndef/record/bluetooth.dart';
import 'package:ndef/record/wellknown.dart';

void testParse(List<String> hexStrings, List<List<NDEFRecord>> messages) {
  for (int i = 0; i < hexStrings.length; i++) {
    var decoded = decodeRawNdefMessage(hexStrings[i].toBytes());
    assert(decoded.length == messages[i].length);
    for (int j = 0; j < decoded.length; j++) {
      assert(decoded[j].isEqual(messages[i][j]));
    }
  }
}

void testGenerate(List<String> hexStrings, List<List<NDEFRecord>> messages) {
  for (int i = 0; i < hexStrings.length; i++) {
    assert(encodeNdefMessage(messages[i]).toHexString() == hexStrings[i]);
  }
}

void main() {
  test('ndef message with uri type', () {
    List<String> hexStrings = [
      "91011655046769746875622e636f6d2f6e6663696d2f6e64656651010b55046769746875622e636f6d",
    ];

    List<List<NDEFRecord>> messages = [
      [
        UriRecord.fromString("https://github.com/nfcim/ndef"),
        UriRecord.fromString("https://github.com")
      ],
    ];

    testParse(hexStrings, messages);
    testGenerate(hexStrings, messages);
  });

  test('ndef message with text type', () {
    List<String> hexStrings = [
      "d1010f5402656e48656c6c6f20576f726c6421",
      "d101145485656d6f6a69fffe3dd801de3dd802de3ed828dd"
    ];

    List<List<NDEFRecord>> messages = [
      [TextRecord(language: 'en', text: 'Hello World!')],
      [
        TextRecord(
            language: 'emoji', text: '😁😂🤨', encoding: TextEncoding.UTF16)
      ],
    ];

    testParse(hexStrings, messages);
    testGenerate(hexStrings, messages);
  });

  test('ndef message with signature type', () {
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

  test('ndef message with device information type', () {
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

  test('ndef message with smart poster type', () {
    List<String> hexStrings = [
      "d10249537091011655046769746875622e636f6d2f6e6663696d2f6e6465661101075402656e6e64656611030161637400120909696d6167652f706e676120706963747572655101047300002710",
      "d1020f5370d1010b55046769746875622e636f6d",
    ];

    List<List<NDEFRecord>> messages = [
      [
        SmartPosterRecord(
            title: "ndef",
            uri: "https://github.com/nfcim/ndef",
            action: Action.exec,
            icon: {"image/png": Uint8List.fromList(utf8.encode("a picture"))},
            size: 10000),
        // typeInfo: null),
      ],
      [
        SmartPosterRecord(uri: "https://github.com"),
      ]
    ];

    testParse(hexStrings, messages);
    testGenerate(hexStrings, messages);
  });

  test('ndef message with handover type', () {
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

  test('ndef message with bluetooth type', () {
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

  test('ndef message with absolute uri', () {
    List<String> hexStrings = [
      '931d0068747470733a2f2f6769746875622e636f6d2f6e6663696d2f6e64656653120068747470733a2f2f6769746875622e636f6d',
    ];

    List<List<NDEFRecord>> messages = [
      [
        AbsoluteUriRecord(uri: "https://github.com/nfcim/ndef"),
        AbsoluteUriRecord(uri: "https://github.com")
      ],
    ];
    testParse(hexStrings, messages);
    testGenerate(hexStrings, messages);
  });

  test('utilities test', () {
    assert(ByteUtils.bytesEqual(null, null) == true);
    assert(ByteUtils.bytesEqual(
            Uint8List.fromList([1, 2, 3]), Uint8List.fromList([1, 2])) ==
        false);
    assert(ByteUtils.bytesEqual(
            Uint8List.fromList([1, 2, 3]), Uint8List.fromList([1, 2, 4])) ==
        false);
    assert(ByteUtils.bytesEqual(
            Uint8List.fromList([1, 2, 3]), Uint8List.fromList([1, 2, 3])) ==
        true);
    assert(ByteUtils.bytesEqual(Uint8List.fromList([1, 2, 3]), null) == false);

    var bytes = Uint8List(0);
    assert(bytes.toHexString() == "");
    assert(Uint8List.fromList([]).toHexString() == "");
  });

  test('blank record construction', () {
    var record = NDEFRecord();
    assert(record.tnf == TypeNameFormat.empty);
    assert(record.decodedType == null);
    assert(record.type == null);
    assert(record.fullType == null);
    assert(record.minPayloadLength == 0);
    assert(record.maxPayloadLength == null);
    assert(record.payload == null);

    var uriRecord = UriRecord();
    assert(uriRecord.tnf == TypeNameFormat.nfcWellKnown);
    assert(uriRecord.decodedType == 'U');
    assert(ByteUtils.bytesEqual(uriRecord.type, Uint8List.fromList([85])));
    assert(uriRecord.fullType == "urn:nfc:wkt:U");
    assert(uriRecord.minPayloadLength == 1);
    assert(uriRecord.maxPayloadLength == null);
    assert(uriRecord.prefix == null);
    assert(uriRecord.iriString == null);
    assert(uriRecord.uriString == null);
    assert(uriRecord.uri == null);
    assert(uriRecord.payload == null);

    var textRecord = TextRecord();
    assert(textRecord.encoding == TextEncoding.UTF8);
    assert(textRecord.encodingString == "UTF-8");
    assert(textRecord.language == null);
    assert(textRecord.text == null);

    var wellKnownRecord = WellKnownRecord();
    assert(wellKnownRecord.tnf == TypeNameFormat.nfcWellKnown);
    assert(wellKnownRecord.payload == null);
    assert(wellKnownRecord.id == null);
  });

  // exception test
  test(
      'exception test',
      () => expect(() {
            UriRecord record = UriRecord();
            record.prefix = "test";
          }, throwsArgumentError));

  // TODO: more tests
}
