import 'dart:typed_data';

import 'package:ndef/record.dart';

class AbsoluteUriRecord extends NDEFRecord {
  static const TypeNameFormat classTnf = TypeNameFormat.absoluteURI;

  @override
  TypeNameFormat get tnf {
    return classTnf;
  }

  AbsoluteUriRecord({String? uri, Uint8List? id}) : super(id: id) {
    if (uri != null) {
      this.uri = uri;
    }
  }

  String? get uri {
    return decodedType;
  }

  set uri(String? uri) {
    decodedType = uri;
  }

  @override
  String? get decodedType {
    return uri;
  }

  @override
  String toString() {
    var str = "AbsoluteUriRecord: ";
    str += "uri=$uri";
    return str;
  }

  // absoluteURI record has no payload
  @override
  Uint8List get payload {
    return Uint8List(0);
  }

  @override
  set payload(Uint8List? payload) {
    if (payload != null && payload.isNotEmpty) {
      throw ArgumentError(
          "AbsoluteURI record does not allow payload, but got ${payload.length} bytes");
    }
  }
}
