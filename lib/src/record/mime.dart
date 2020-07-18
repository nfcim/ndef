import 'dart:typed_data';

import '../record.dart';

class MIMERecord extends Record {
  static const String recordType = "media";

  static const String decodedType = "media";

  @override
  String get _decodedType {
    return MIMERecord.decodedType;
  }

  String contentType;
  Uint8List _payload;

  MIMERecord({String contentType, Uint8List payload}) {
    this.contentType = contentType;
    this.payload = payload;
  }

  get payload{
    return _payload;
  }

  set payload(Uint8List payload) {
    _payload=payload;
  }
}
