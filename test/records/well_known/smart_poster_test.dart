import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:ndef/ndef.dart';
import '../../helpers.dart';

void main() {
  group('SmartPosterRecord', () {
    test('encode and decode full smart poster', () {
      var hexStrings = [
        "d10249537091011655046769746875622e636f6d2f6e6663696d2f6e6465661101075402656e6e64656611030161637400120909696d6167652f706e676120706963747572655101047300002710",
      ];
      var messages = [
        [
          SmartPosterRecord(
            title: "ndef",
            uri: "https://github.com/nfcim/ndef",
            action: Action.exec,
            icon: {"image/png": Uint8List.fromList(utf8.encode("a picture"))},
            size: 10000,
          ),
        ],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });

    test('encode and decode uri-only smart poster', () {
      var hexStrings = [
        "d1020f5370d1010b55046769746875622e636f6d",
      ];
      var messages = [
        [SmartPosterRecord(uri: "https://github.com")],
      ];

      testParse(hexStrings, messages);
      testGenerate(hexStrings, messages);
    });
  });
}
