import 'dart:typed_data';

import 'package:ndef/record.dart';
import 'package:ndef/utilities.dart';

/// A NDEF record with NFC Forum well-known type.
///
/// This is the base class for well-known record types defined by the NFC Forum,
/// such as Text, URI, Smart Poster, etc.
class WellKnownRecord extends NDEFRecord {
  /// The Type Name Format for well-known records.
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  @override
  TypeNameFormat get tnf {
    return classTnf;
  }

  /// Constructs a [WellKnownRecord] with optional [decodedType], [payload], and [id].
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
