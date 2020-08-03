import 'dart:typed_data';

import '../record.dart';

class AbsoluteUriRecord extends Record {
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  AbsoluteUriRecord({String uri}) {
    if (uri != null) {
      this.uri = uri;
    }
  }

  get uri {
    return decodedType;
  }

  set uri(String uri) {
    decodedType = uri;
  }

  get decodedType {
    return uri;
  }

  @override
  String toString() {
    var str = "AbsoluteUriRecord: ";
    str += "uri=$uri";
    return str;
  }

  //absoluteURI record has no payload
  Uint8List get payload {
    return null;
  }

  set payload(Uint8List payload) {
    throw "AbsoluteURI record has no payload";
  }
}
