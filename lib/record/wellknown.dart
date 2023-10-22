import 'dart:typed_data';

import '../ndef.dart';

class WellKnownRecord extends NDEFRecord {
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  @override
  TypeNameFormat get tnf {
    return classTnf;
  }

  WellKnownRecord({String? decodedType, Uint8List? payload, Uint8List? id})
      : super(id: id, payload: payload) {
    if (decodedType != null) {
      this.decodedType = decodedType;
    }
  }

  @override
  String toString() {
    var str = "WellKnownRecord: ";
    str += basicInfoString;
    str += "type=$decodedType ";
    str += "payload=${(payload?.toHexString()) ?? '(null)'}";
    return str;
  }
}
