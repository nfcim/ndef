import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/record.dart';
import 'package:ndef/record/smartposter.dart';

import '../ndef_test.dart';

void main() {
  group('encode and decode', () {
    test('main function', () {
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
  });

  group('ndef message with smart poster type', () {
    SmartPosterRecord smartPosterRecord1 = SmartPosterRecord(
        title: "ndef",
        uri: "https://github.com/nfcim/ndef",
        action: Action.exec,
        icon: {"image/png": Uint8List.fromList(utf8.encode("a picture"))},
        size: 10000);


    SmartPosterRecord smartPosterRecord2 = SmartPosterRecord(uri: "https://github.com");
  });
}
