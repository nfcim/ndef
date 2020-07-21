import 'dart:typed_data';

import '../record.dart';

class AbsoluteUriRecord extends Record {
  static const String recordType = "absoluteURI";

  String uri;
  Uint8List _payload;

  AbsoluteUriRecord({this.uri});

  get _decodedType {
    return uri;
  }

  //absoluteURI record has no payload
  Uint8List get payload {
    return null;
  }

  set payload(Uint8List payload) {
    _payload = payload;
  }
}
