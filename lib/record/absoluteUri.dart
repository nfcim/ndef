import 'dart:typed_data';

import '../ndef.dart';

class AbsoluteUriRecord extends NDEFRecord {
  static const TypeNameFormat classTnf = TypeNameFormat.absoluteURI;

  TypeNameFormat get tnf {
    return classTnf;
  }

  AbsoluteUriRecord({String? uri, Uint8List? id}) : super(id: id) {
    if (uri != null) {
      this.uri = uri;
    }
  }

  String get uri {
    return decodedType!; // This is really bad hack
  }

  set uri(String uri) {
    decodedType = uri; // This is really bad hack
  }

  @override
  String toString() {
    var str = "AbsoluteUriRecord: ";
    str += "uri=$uri";
    return str;
  }

  //absoluteURI record has no payload
  Uint8List? get payload {
    return null;
  }

  set payload(Uint8List? payload) {
    if (payload != null && payload.length > 0) {
      throw ArgumentError("AbsoluteURI record has no payload, don't set it");
    }
  }
}
