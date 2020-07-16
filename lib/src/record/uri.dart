import 'dart:convert';
import 'dart:typed_data';

import '../record.dart';

class URIRecord extends Record {
  static const String recordType = "urn:nfc:wkt:U";
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

  String uriPrefix, uriData;

  URIRecord({this.uriPrefix, this.uriData});

  get uri {
    return this.uriPrefix + this.uriData;
  }

  
  static const String decodedType = "U";

  @override
  String get _decodedType {
    return URIRecord.decodedType;
  }

  Uint8List get payload {
    for (int i = 0; i < uriPrefixMap.length; i++) {
      if (uriPrefixMap[i] == uriPrefix) {
        return [i] + utf8.encode(uriData);
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
      //uriPrefix="unknown:";
    }
    uriData = utf8.decode(payload.sublist(1));
  }

}
