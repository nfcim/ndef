import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/ndef.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/uri.dart';

import 'ndef_test.dart';

void main() {
  test('ndef message with uri type', () {
    List<String> hexStrings = [
      // test the robustness of function which handles the  hexStrings.
      "9101165504676974    6875622e    636f6d2f6e6663696d2f6e64656651010b55046769746875622e636f6d",
    ];

    List<List<NDEFRecord>> messages = [
      [
        UriRecord.fromString("https://github.com/nfcim/ndef"),
        UriRecord.fromString("https://github.com")
      ],
    ];

    // Part I: test the function of ENCODE and DECODE.
    testParse(hexStrings, messages);
    testGenerate(hexStrings, messages);

    // Part II: test the function decodePartialNdefMessage();
    NDEFRecord testDPNM = decodePartialNdefMessage(TypeNameFormat.absoluteURI, UriRecord.classType as Uint8List, payload, id: "dfjakfj" as Uint8List);

  });
}
