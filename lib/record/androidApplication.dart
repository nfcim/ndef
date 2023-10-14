import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/record/externalRecord.dart';

class AARRecord extends ExternalRecord {
  static const String classType = "android.com:pkg";

  @override
  String get decodedType {
    return AARRecord.classType;
  }

  String packageName;

  AARRecord(this.packageName);

  @override
  Uint8List? get payload {
    return Uint8List.fromList(utf8.encode(packageName));
  }

  set payload(Uint8List? payload) {
    packageName = utf8.decode(payload!);
  }

  @override
  String toString() {
    var str = "AARRecord: ";
    str += basicInfoString;
    str += "package=$packageName";
    return str;
  }
}
