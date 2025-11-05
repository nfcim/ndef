import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/records/external/external.dart';

/// Android Application Record (AAR) for launching Android apps via NFC.
///
/// This record type specifies an Android package name that should be used
/// to launch an application when the NFC tag is scanned.
class AARRecord extends ExternalRecord {
  /// The type identifier for Android Application Records.
  static const String classType = "android.com:pkg";

  @override
  String get decodedType {
    return AARRecord.classType;
  }

  /// The Android package name (e.g., "com.example.app").
  String? packageName;

  /// Constructs an [AARRecord] with an optional [packageName].
  AARRecord({this.packageName});

  @override
  Uint8List get payload {
    return Uint8List.fromList(utf8.encode(packageName ?? ''));
  }

  @override
  set payload(Uint8List? payload) {
    packageName = utf8.decode(payload ?? Uint8List(0));
  }

  @override
  String toString() {
    var str = "AARRecord: ";
    str += basicInfoString;
    str += "package=$packageName";
    return str;
  }
}
