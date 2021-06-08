import 'dart:convert';
import 'dart:typed_data';

import 'wellknown.dart';

class UriRecord extends WellKnownRecord {
  static List<String> prefixMap = [
    "",
    "http://www.",
    "https://www.",
    "http://",
    "https://",
    "tel:",
    "mailto:",
    "ftp://anonymous:anonymous@",
    "ftp://ftp.",
    "ftps://",
    "sftp://",
    "smb://",
    "nfs://",
    "ftp://",
    "dav://",
    "news:",
    "telnet://",
    "imap:",
    "rtsp://",
    "urn:",
    "pop:",
    "sip:",
    "sips:",
    "tftp:",
    "btspp://",
    "btl2cap://",
    "btgoep://",
    "tcpobex://",
    "irdaobex://",
    "file://",
    "urn:epc:id:",
    "urn:epc:tag:",
    "urn:epc:pat:",
    "urn:epc:raw:",
    "urn:epc:",
    "urn:nfc:",
  ];

  static const String classType = "U";

  @override
  String get decodedType {
    return UriRecord.classType;
  }

  static const int classMinPayloadLength = 1;

  int get minPayloadLength {
    return classMinPayloadLength;
  }

  @override
  String toString() {
    var str = "UriRecord: ";
    str += basicInfoString;
    str += "uri=$uriString";
    return str;
  }

  int _prefixIndex = -1;
  String? content;

  UriRecord({String? prefix, String? content}) {
    if (prefix != null) {
      this.prefix = prefix;
    }
    this.content = content;
  }

  /// Construct with a [UriString] or an [IriString]
  UriRecord.fromString(String string) {
    this.iriString = string;
  }

  /// Construct with an instance of Uri
  UriRecord.fromUri(Uri uri) {
    this.uriString = uri.toString();
  }

  String? get prefix {
    if (_prefixIndex == -1) {
      return null;
    }
    return prefixMap[_prefixIndex];
  }

  set prefix(String? prefix) {
    int prefixIndex = prefixMap.indexOf(prefix!);
    if (prefixIndex == -1) {
      throw "URI Prefix $prefix is not supported, please select one from $prefixMap";
    } else {
      _prefixIndex = prefixIndex;
    }
  }

  String? get iriString {
    if (this.prefix == null || this.content == null) {
      return null;
    }
    return this.prefix! + this.content!;
  }

  set iriString(String? iriString) {
    for (int i = 1; i < prefixMap.length; i++) {
      if (iriString!.startsWith(prefixMap[i])) {
        this._prefixIndex = i;
        this.content = iriString.substring(prefix!.length);
        return;
      }
    }
    this._prefixIndex = 0;
    this.content = iriString;
  }

  String? get uriString {
    if (this.prefix == null || this.content == null) {
      return null;
    }
    return Uri.parse(this.prefix! + this.content!).toString();
  }

  set uriString(String? uriString) {
    this.iriString = uriString!;
  }

  Uri? get uri {
    if (this.prefix == null || this.content == null) {
      return null;
    }
    return Uri.parse(iriString!);
  }

  set uri(Uri? uri) {
    this.iriString = uri!.toString();
  }

  /// Encode and Get payload, return null when the prefix or content is null
  Uint8List? get payload {
    if (content == null || prefix == null) {
      return null;
    }
    return Uint8List.fromList([_prefixIndex] + utf8.encode(content!));
  }

  set payload(Uint8List? payload) {
    int prefixIndex = payload![0];
    if (prefixIndex < prefixMap.length) {
      _prefixIndex = prefixIndex;
    } else {
      _prefixIndex = 0;
    }
    content = utf8.decode(payload.sublist(1));
  }
}
