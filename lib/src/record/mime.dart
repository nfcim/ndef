import 'dart:typed_data';

import '../record.dart';

class MimeRecord extends Record {

  static const TypeNameFormat classTnf = TypeNameFormat.media;

  TypeNameFormat get tnf {
    return classTnf;
  }

  @override
  String get decodedType {
    return classType;
  }

  String classType;
  Uint8List _payload;

  MimeRecord({String contentType, Uint8List payload}) {
    this.classType = contentType;
    this.payload = payload;
  }

  Uint8List get payload {
    return _payload;
  }

  set payload(Uint8List payload) {
    _payload = payload;
  }
}
