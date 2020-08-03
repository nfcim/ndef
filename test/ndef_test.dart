import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/src/record/deviceinfo.dart';
import 'package:utf/utf.dart' as utf;

import 'package:ndef/ndef.dart';
import 'package:ndef/src/byteStream.dart';

void main() {
  test('ndef message with uri type', () {
    // TODO: fill in tests
    List<String> hexStrings = [
      "91011655046769746875622e636f6d2f6e6663696d2f6e64656651010b55046769746875622e636f6d",
    ];

    List<List<Record>> messages = [
      [
        new UriRecord.fromUriString("https://github.com/nfcim/ndef"),
        new UriRecord.fromUriString("https://github.com")
      ],
    ];

    // parse
    for (int i = 0; i < hexStrings.length; i++) {
      var decoded =
          decodeRawNdefMessage(ByteStream.hexString2list(hexStrings[i]));
      assert(decoded.length == messages[i].length);
      for (int j = 0; j < decoded.length; j++) {
        assert(decoded[j].isEqual(messages[i][j]));
      }
    }

    // generate
    for (int i = 0; i < hexStrings.length; i++) {
      assert(ByteStream.list2hexString(encodeNdefMessage(messages[i])) ==
          hexStrings[i]);
    }
  });

  test('ndef message with text type', () {
    List<String> hexStrings = [
      "d1010f5402656e48656c6c6f20576f726c6421",
      //"d101145485656d6f6a69fffe3dd801de3dd802de3ed828dd"  // can only decode emoji correctly, but can not encode
    ];

    List<List<Record>> messages = [
      [new TextRecord(language: 'en', text: 'Hello World!')],
      //[new TextRecord(language:'emoji',text:'😁😂🤨',encoding:TextEncoding.UTF16)],
    ];

    // parse
    for (int i = 0; i < hexStrings.length; i++) {
      var decoded =
          decodeRawNdefMessage(ByteStream.hexString2list(hexStrings[i]));
      assert(decoded.length == messages[i].length);
      for (int j = 0; j < decoded.length; j++) {
        assert(decoded[j].isEqual(messages[i][j]));
      }
    }

    // generate
    for (int i = 0; i < hexStrings.length; i++) {
      assert(ByteStream.list2hexString(encodeNdefMessage(messages[i])) ==
          hexStrings[i]);
    }
  });

  test('ndef message with signature type', () {
    List<String> hexStrings = [
      "d10306536967200002000000",
      "d1034d536967200b0200473045022100a410c28fd9437fd24f6656f121e62bcc5f65e36257f5faadf68e3e83d40d481a0220335b1dff8d6fe722fcf7018be9684d2de5670b256fdfc02aa25bdae16f624b8000",
    ];

    List<List<Record>> messages = [
      [new SignatureRecord()],
      [
        new SignatureRecord(
            signatureType: 'ECDSA-P256',
            signature: ByteStream.hexString2list(
                "3045022100a410c28fd9437fd24f6656f121e62bcc5f65e36257f5faadf68e3e83d40d481a0220335b1dff8d6fe722fcf7018be9684d2de5670b256fdfc02aa25bdae16f624b80"))
      ],
    ];

    // parse
    for (int i = 0; i < hexStrings.length; i++) {
      var decoded =
          decodeRawNdefMessage(ByteStream.hexString2list(hexStrings[i]));
      assert(decoded.length == messages[i].length);
      for (int j = 0; j < decoded.length; j++) {
        assert(decoded[j].isEqual(messages[i][j]));
      }
    }

    // generate
    for (int i = 0; i < hexStrings.length; i++) {
      assert(ByteStream.list2hexString(encodeNdefMessage(messages[i])) ==
          hexStrings[i]);
    }
  });

  test('ndef message with device information type', () {
    List<String> hexStrings = [
      "d1023b446900056e6663696d01096e666344657669636502076e66634e616d6503106361ae18d5b011ea9d0840a3ccfd09570405312e302e30ff054e4643494d",
    ];

    List<List<Record>> messages = [
      [
        new DeviceInformationRecord(
            vendorName: "nfcim",
            modelName: "nfcDevice",
            uniqueName: "nfcName",
            uuid: "6361ae18-d5b0-11ea-9d08-40a3ccfd0957",
            versionString: "1.0.0",
            undefinedData: [
              new DataElement.fromString(255, "NFCIM"),
            ])
      ],
    ];

    // parse
    for (int i = 0; i < hexStrings.length; i++) {
      var decoded =
          decodeRawNdefMessage(ByteStream.hexString2list(hexStrings[i]));
      assert(decoded.length == messages[i].length);
      for (int j = 0; j < decoded.length; j++) {
        assert(decoded[j].isEqual(messages[i][j]));
      }
    }

    // generate
    for (int i = 0; i < hexStrings.length; i++) {
      assert(ByteStream.list2hexString(encodeNdefMessage(messages[i])) ==
          hexStrings[i]);
    }
  });

  test('ndef message with signature type', () {
    //print(decodeRawNdefMessage(ByteStream.hexString2list(
    //    "")));
  });

  // TODO: more tests
}
