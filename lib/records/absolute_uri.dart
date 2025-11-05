import 'dart:typed_data';

import 'package:ndef/record.dart';

/// A NDEF record with absolute URI type.
///
/// This record type contains a URI in the type field and has no payload.
/// The URI is stored directly in the type field according to the NDEF specification.
class AbsoluteUriRecord extends NDEFRecord {
  /// The Type Name Format for absolute URI records.
  static const TypeNameFormat classTnf = TypeNameFormat.absoluteURI;

  @override
  TypeNameFormat get tnf {
    return classTnf;
  }

  /// Constructs an [AbsoluteUriRecord] with optional [uri] and [id].
  AbsoluteUriRecord({String? uri, Uint8List? id}) : super(id: id) {
    if (uri != null) {
      this.uri = uri;
    }
  }

  /// Gets the URI from the record type field.
  String? get uri {
    return decodedType;
  }

  /// Sets the URI in the record type field.
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
        "AbsoluteURI record does not allow payload, but got ${payload.length} bytes",
      );
    }
  }
}
