import 'dart:typed_data';

import 'package:ndef/record.dart';
import 'package:ndef/utilities.dart';

class MimeRecord extends NDEFRecord {
  static const TypeNameFormat classTnf = TypeNameFormat.media;

  @override
  TypeNameFormat get tnf {
    return classTnf;
  }

  MimeRecord({String? decodedType, Uint8List? payload, Uint8List? id})
      : super(id: id, payload: payload) {
    if (decodedType != null) {
      this.decodedType = decodedType;
    }
  }

  @override
  String toString() {
    var str = "MimeRecord: ";
    str += basicInfoString;
    str += "payload=${(payload?.toHexString()) ?? '(null)'}";
    return str;
  }
}
