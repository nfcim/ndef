import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:ndef/ndef.dart';
import 'package:ndef/utilities.dart';

/// Decode hex strings and verify they match the expected records.
void testParse(List<String> hexStrings, List<List<NDEFRecord>> messages) {
  for (int i = 0; i < hexStrings.length; i++) {
    var decoded = decodeRawNdefMessage(hexStrings[i].toBytes());
    expect(decoded.length, messages[i].length,
        reason: 'Message $i record count mismatch');
    for (int j = 0; j < decoded.length; j++) {
      expect(decoded[j].isEqual(messages[i][j]), isTrue,
          reason: 'Message $i record $j mismatch');
    }
  }
}

/// Encode records and verify they produce the expected hex strings.
void testGenerate(List<String> hexStrings, List<List<NDEFRecord>> messages) {
  for (int i = 0; i < hexStrings.length; i++) {
    expect(encodeNdefMessage(messages[i]).toHexString(), hexStrings[i],
        reason: 'Message $i encoding mismatch');
  }
}

/// Encode then decode records, verifying round-trip fidelity.
void testRoundTrip(List<List<NDEFRecord>> messages) {
  for (int i = 0; i < messages.length; i++) {
    var decoded = decodeRawNdefMessage(encodeNdefMessage(messages[i]));
    expect(decoded.length, messages[i].length,
        reason: 'Round-trip message $i record count mismatch');
    for (int j = 0; j < decoded.length; j++) {
      expect(decoded[j].isEqual(messages[i][j]), isTrue,
          reason: 'Round-trip message $i record $j mismatch');
    }
  }
}

/// Shorthand to convert a hex string to [Uint8List].
Uint8List hexToBytes(String hex) => ByteUtils.hexStringToBytes(hex);
