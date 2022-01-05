import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ndef/ndef.dart';
import 'package:ndef/utilities.dart';

void testParse(List<String> hexStrings, List<List<NDEFRecord>> messages) {
  for (int i = 0; i < hexStrings.length; i++) {
    List<NDEFRecord> decoded = decodeRawNdefMessage(hexStrings[i].toBytes());
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
