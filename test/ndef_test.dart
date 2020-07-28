import 'package:flutter_test/flutter_test.dart';

import 'package:ndef/ndef.dart';

void main() {
  test('parse ndef message with uri type', () {
    // TODO: fill in tests
    List<String> hexStrings=[
      "91011655046769746875622e636f6d2f6e6663696d2f6e64656651010b55046769746875622e636f6d",
    ];

    List<List<Record>> messages=[
      [new UriRecord.fromUriString("https://github.com/nfcim/ndef"),
      new UriRecord.fromUriString("https://github.com")],
    ];

    for(int i=0;i<hexStrings.length;i++){
      var decoded = decodeRawNdefMessage(ByteStream.hexString2list(hexStrings[i]));
      assert(decoded.length==messages[i].length);
      for(int j=0;j<decoded.length;j++){
        assert(decoded[j].isEqual(messages[i][j]));
      }
    }
  });

  test('generate ndef message with uri type', () {
    List<String> hexStrings=[
      "91011655046769746875622e636f6d2f6e6663696d2f6e64656651010b55046769746875622e636f6d",
    ];

    List<List<Record>> messages=[
      [new UriRecord.fromUriString("https://github.com/nfcim/ndef"),
      new UriRecord.fromUriString("https://github.com")],
    ];

    for(int i=0;i<hexStrings.length;i++){
      assert(ByteStream.list2hexString(encodeNdefMessage(messages[i]))==hexStrings[i]);
    }
  });

  // TODO: more tests
}
