import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart' as ndef;

void main() {
  var encodedUrlRecord =
      "91011655046769746875622e636f6d2f6e6663696d2f6e64656651010b55046769746875622e636f6d";
  var urlRecords = [
    new ndef.UriRecord.fromUriString("https://github.com/nfcim/ndef"),
    new ndef.UriRecord.fromUriString("https://github.com")
  ];

  // decode full ndef message (concatenation of records)
  var decodedurlRecords = ndef
      .decodeRawNdefMessage(ndef.ByteUtils.hexStringToBytes(encodedUrlRecord));

  assert(urlRecords.length == decodedurlRecords.length);

  for (int i = 0; i < urlRecords.length; i++) {
    var raw = urlRecords[i];
    var decoded = decodedurlRecords[i];
    assert(decoded is ndef.UriRecord);
    assert((decoded as ndef.UriRecord).uri == raw.uri);
    print((decoded as ndef.UriRecord).toString());
  }

  // modify the record by data-binding
  var origPayload = urlRecords[0].payload;
  print('===================');
  print('original payload: ' + ndef.ByteUtils.bytesToHexString(origPayload));
  print('original uri: ' + urlRecords[0].uri.toString());

  // change uri
  print('===================');
  urlRecords[0].uriData =
      'github.com/nfcim/flutter_nfc_kit'; // thats also our awesome library, check it out!
  print('payload after change uriData: ' +
      ndef.ByteUtils.bytesToHexString(
          urlRecords[0].payload)); // encoded when invoking
  print('uri after change uriData: ' + urlRecords[0].uri.toString());

  // change it back (by using payload)
  print('===================');
  urlRecords[0].payload = origPayload; // decoded when invoking
  print('payload after changed back: ' +
      ndef.ByteUtils.bytesToHexString(urlRecords[0].payload));
  print('uri after changed back: ' + urlRecords[0].uri.toString());

  // encoded into message again (also canonicalize MB & MF fields)
  var encodedAgain = ndef.encodeNdefMessage(urlRecords);
  assert(ndef.ByteUtils.bytesToHexString(encodedAgain) == encodedUrlRecord);
  print('encoded single record: ' +
      ndef.ByteUtils.bytesToHexString(urlRecords[0].encode()));

  // also you can decode by providing id, type and payload separately (normally from phone API)
  print('===================');
  var partiallyDecodedUrlRecord = ndef.decodePartialNdefMessage(
      ndef.TypeNameFormat.nfcWellKnown, utf8.encode("U"), origPayload,
      id: Uint8List.fromList([0x1, 0x2]));
  assert(partiallyDecodedUrlRecord is ndef.UriRecord);
  print('partially decoded record: ' +
      (partiallyDecodedUrlRecord as ndef.UriRecord).toString());
}
