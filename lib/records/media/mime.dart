import 'dart:typed_data';

import 'package:ndef/record.dart';
import 'package:ndef/utilities.dart';

/// A NDEF record with MIME media type (RFC 2046).
///
/// This record type uses MIME types (e.g., "text/plain", "image/png") to describe
/// the payload content.
class MimeRecord extends NDEFRecord {
  /// The Type Name Format for MIME media records.
  static const TypeNameFormat classTnf = TypeNameFormat.media;

  @override
  TypeNameFormat get tnf {
    return classTnf;
  }

  /// Constructs a [MimeRecord] with optional [decodedType], [payload], and [id].
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
