import 'dart:typed_data';
import 'package:ndef/ndef.dart';
import 'package:ndef/utilities.dart';

void main() {
  // Test payload < 256 bytes
  var smallText = 'A' * 100; // 100 characters
  var smallRecord = TextRecord(language: 'en', text: smallText);
  var smallEncoded = smallRecord.encode();
  print('Small payload (${100 + 3} bytes total payload):'); // 3 bytes for language code
  print('  Encoded: ${smallEncoded.toHexString()}');
  print('  Length: ${smallEncoded.length}');
  
  // The flags byte should have SR=1 (short record) for payloads < 256
  var flags = smallEncoded[0];
  print('  Flags: 0x${flags.toRadixString(16)}');
  print('  SR (Short Record): ${(flags >> 4) & 1}');
  
  // Test payload >= 256 bytes
  var largeText = 'A' * 312; // 312 characters (from test)
  var largeRecord = TextRecord(language: 'en', text: largeText);
  var largeEncoded = largeRecord.encode();
  print('\nLarge payload (${312 + 3} bytes total payload):'); // 3 bytes for language code
  print('  Encoded: ${largeEncoded.toHexString()}');
  print('  Length: ${largeEncoded.length}');
  
  var largeFlags = largeEncoded[0];
  print('  Flags: 0x${largeFlags.toRadixString(16)}');
  print('  SR (Short Record): ${(largeFlags >> 4) & 1}');
  
  // For long records (SR=0), payload length is 4 bytes starting at position 2
  var typeLength = largeEncoded[1];
  print('  Type length: $typeLength');
  
  var payloadLengthBytes = largeEncoded.sublist(2, 6);
  print('  Payload length bytes: ${payloadLengthBytes.toHexString()}');
  
  // Big-endian interpretation (correct)
  var payloadLengthBE = (payloadLengthBytes[0] << 24) | 
                         (payloadLengthBytes[1] << 16) | 
                         (payloadLengthBytes[2] << 8) | 
                         payloadLengthBytes[3];
  print('  Big-endian: $payloadLengthBE');
  
  // Little-endian interpretation (incorrect)
  var payloadLengthLE = (payloadLengthBytes[3] << 24) | 
                         (payloadLengthBytes[2] << 16) | 
                         (payloadLengthBytes[1] << 8) | 
                         payloadLengthBytes[0];
  print('  Little-endian: $payloadLengthLE');
  
  // Expected payload length
  var expectedPayloadLength = 315; // 312 chars + 3 bytes header
  print('  Expected: $expectedPayloadLength');
  
  if (payloadLengthBE == expectedPayloadLength) {
    print('  ✓ Correctly encoded in big-endian!');
  } else if (payloadLengthLE == expectedPayloadLength) {
    print('  ✗ INCORRECTLY encoded in little-endian!');
  } else {
    print('  ? Neither interpretation matches expected value');
  }
}
