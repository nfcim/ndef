import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';

import '../record.dart';

class UriRecord extends Record {
  static List<String> uriPrefixMap = [
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

  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

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
    str += "uri=$uriString ";
    return str;
  }

  String _uriPrefix, uriData;

  UriRecord({String uriPrefix, String uriData}) {
    if (uriPrefix != null) {
      this.uriPrefix = uriPrefix;
    }
    this.uriData = uriData;
  }

  UriRecord.fromUriString(String uriString) {
    this.uriString = uriString;
  }

  UriRecord.fromUri(Uri uri) {
    this.uriString = uri.toString();
  }

  String get uriPrefix {
    return _uriPrefix;
  }

  set uriPrefix(String uriPrefix) {
    assert(uriPrefixMap.contains(uriPrefix),
        "URI Prefix $uriPrefix is not correct");
    _uriPrefix = uriPrefix;
  }

  get uriString {
    return this.uriPrefix + this.uriData;
  }

  set uriString(String uriString) {
    for (int i = 1; i < uriPrefixMap.length; i++) {
      if (uriString.startsWith(uriPrefixMap[i])) {
        this._uriPrefix = uriPrefixMap[i];
        this.uriData = uriString.substring(uriPrefix.length);
        return;
      }
    }
    this._uriPrefix = "";
    this.uriData = uriString;
  }

  Uri get uri {
    return Uri.parse(uriString);
  }

  Uint8List get payload {
    for (int i = 0; i < uriPrefixMap.length; i++) {
      if (uriPrefixMap[i] == uriPrefix) {
        return new Uint8List.fromList([i] + utf8.encode(uriData));
      }
    }
  }

  set payload(Uint8List payload) {
    int uriIdentifier = payload[0];
    if (uriIdentifier < uriPrefixMap.length) {
      uriPrefix = uriPrefixMap[uriIdentifier];
    } else {
      //More identifier codes are reserved for future use
      uriPrefix = "";
    }
    uriData = utf8.decode(payload.sublist(1));
  }
}
