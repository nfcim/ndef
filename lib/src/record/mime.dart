import 'dart:typed_data';

import '../record.dart';

class MimeRecord extends Record {
  static const TypeNameFormat classTnf = TypeNameFormat.media;

  TypeNameFormat get tnf {
    return classTnf;
  }

  MimeRecord({String decodedType, Uint8List payload}) {
    if (decodeType != null) {
      this.decodedType = decodedType;
    }
    if (payload != null) {
      this.payload = payload;
    }
  }
}
