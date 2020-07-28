import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:utf/utf.dart' as utf;

import 'package:ndef/ndef.dart';

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
    // TODO: fill in tests
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
      print((messages[i][0] as TextRecord).text);
      print(ByteStream.list2hexString(encodeNdefMessage(messages[i])));
      assert(ByteStream.list2hexString(encodeNdefMessage(messages[i])) ==
          hexStrings[i]);
    }
  });
  
  test('ndef message with signature type', () {
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

  // TODO: more tests
}
