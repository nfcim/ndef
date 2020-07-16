import 'dart:typed_data';

import 'record.dart';

class MIMERecord extends Record {
  static const String recordType = "media";

  String contentType;
  Uint8List payload;

  MIMERecord(String contentType, Uint8List payload) {
    this.contentType = contentType;
    this.payload = payload;
  }

  static MIMERecord decodePayload(Uint8List PAYLOAD) {}
}
