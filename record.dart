import 'dart:convert';

import 'byteStream.dart';
import 'uri.dart';
import 'text.dart';
import 'signature.dart';
import 'mime.dart';
import 'absoluteUri.dart';

/*
/// Type of NFC tag.
enum NDEFTypeNameFormat {
  absoluteURI,
  empty,
  media,
  nfcExternal,
  nfcWellKnown,
  unchanged,
  unknown
}

/// Metadata of a NDEF record.
///
/// All fields are in the format of hex string.
@JsonSerializable()
class NDEFRecord {
  /// identifier of the payload
  final String identifier;

  /// payload
  final String payload;

  /// type of the payload
  final String type;

  /// type name format
  final NDEFTypeNameFormat typeNameFormat;

  NDEFRecord(this.identifier, this.payload, this.type, this.typeNameFormat);

  factory NDEFRecord.fromJson(Map<String, dynamic> json) =>
      _$NDEFRecordFromJson(json);
  Map<String, dynamic> toJson() => _$NDEFRecordToJson(this);
}
*/

class Record {
  static List<String> prefixMap = [
    "",
    "urn:nfc:wkt:",
    "",
    "",
    "urn:nfc:ext:",
    "unknown",
    "unchanged"
  ];
  static List<String> tnfMap = [
    "empty",
    "nfcWellKnown",
    "media",
    "absoluteURI",
    "nfcExternel",
    "unknown",
    "unchanged"
  ];

  static const String recordType = "none";

  Record() {}

  static dynamic decode(ByteStream stream) {
    int flags = stream.read_byte();

    num MB = (flags >> 7) & 1;
    num ME = (flags >> 6) & 1;
    num CF = (flags >> 5) & 1;
    num SR = (flags >> 4) & 1;
    num IL = (flags >> 3) & 1;
    int TNF = flags & 7;

    assert(flags != 7, 'TNF value must between 0 and 6');

    num TYPE_LENTH = stream.read_byte();
    num PAYLOAD_LENTH;
    num ID_LENTH = 0;

    if (SR == 1) {
      PAYLOAD_LENTH = stream.read_byte();
    } else {
      PAYLOAD_LENTH = stream.read_int(4);
    }
    if (IL == 1) {
      ID_LENTH = stream.read_byte();
    }

    if ([0, 5, 6].contains(TNF)) {
      assert(TYPE_LENTH == 0, "TYPE_LENTH must be 0 when TNF is 0,5,6");
    }
    if (TNF == 0) {
      assert(ID_LENTH == 0, "ID_LENTH must be 0 when TNF is 0");
      assert(PAYLOAD_LENTH == 0, "PAYLOAD_LENTH must be 0 when TNF is 0");
    }
    if ([1, 2, 3, 4].contains(TNF)) {
      assert(TYPE_LENTH == 0, "TYPE_LENTH must be >0 when TNF is 1,2,3,4");
    }

    List<int> TYPE = stream.read_bytes(TYPE_LENTH);
    List<int> ID = stream.read_bytes(ID_LENTH);
    List<int> PAYLOAD = stream.read_bytes(PAYLOAD_LENTH);

    String typeNameFormat = tnfMap[TNF];
    String type = utf8.decode(TYPE);

    var record;
    if (typeNameFormat == "nfcWellKnown") {
      //urn:nfc:wkt
      if (type == "U") {
        //URI
        record = URIRecord.decode_payload(PAYLOAD);
      } else if (type == "T") {
        //Text
        record = TextRecord.decode_payload(PAYLOAD);
      } else if (type == "Sp") {
        //Smart Poster

      } else if (type == "Sig") {
        //Signature
        record = SignatureRecord.decode_payload(PAYLOAD);
      }
    } else if (typeNameFormat == "media") {
      record = MIMERecord.decode_payload(PAYLOAD);
    } else if (typeNameFormat == "absoluteURI") {
      record = new absoluteUriRecord(type);
    } else {
      record = new DefaultRecord(TYPE, ID, PAYLOAD);
    }

    return record;
  }

  static String _decode_type(num TNF, List<int> TYPE) {
    return prefixMap[TNF];
  }

  static void _error(String fmt) {}
}

class DefaultRecord extends Record {
  List<int> type, id, payload;

  DefaultRecord(this.type, this.id, this.payload);
}
