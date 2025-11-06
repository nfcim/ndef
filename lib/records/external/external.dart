import 'dart:typed_data';

import 'package:ndef/record.dart';
import 'package:ndef/utilities.dart';

/// A NDEF record with NFC Forum external type.
///
/// External types are defined by third parties using a domain-based naming scheme.
class ExternalRecord extends NDEFRecord {
  /// The Type Name Format for external records.
  static const TypeNameFormat classTnf = TypeNameFormat.nfcExternal;

  @override
  TypeNameFormat get tnf {
    return classTnf;
  }

  /// Constructs an [ExternalRecord] with optional [decodedType], [payload], and [id].
  ExternalRecord({String? decodedType, super.payload, super.id}) {
    if (decodedType != null) {
      this.decodedType = decodedType;
    }
  }

  @override
  String toString() {
    var str = "ExternalRecord: ";
    str += basicInfoString;
    str += "type=$decodedType ";
    str += "payload=${(payload?.toHexString()) ?? '(null)'}";
    return str;
  }
}
