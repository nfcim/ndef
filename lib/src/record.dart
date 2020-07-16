import 'dart:convert';
import 'dart:typed_data';

import 'byteStream.dart';
import 'record/uri.dart';
import 'record/text.dart';
import 'record/signature.dart';
import 'record/mime.dart';
import 'record/absoluteUri.dart';
import 'record/raw.dart';

class RecordFlags {
  /// Message Begin */
  bool MB;

  /// Message End */
  bool ME;

  /// Chunk Flag */
  bool CF;

  /// Short Record */
  bool SR;

  /// ID Length */
  bool IL;

  /// Type Name Format */
  int TNF;

  RecordFlags(int data) {
    assert(0 <= data && data <= 255);
    MB = ((data >> 7) & 1) == 1;
    ME = ((data >> 6) & 1) == 1;
    CF = ((data >> 5) & 1) == 1;
    SR = ((data >> 4) & 1) == 1;
    IL = ((data >> 3) & 1) == 1;
    TNF = data & 7;
  }

  int encode() {
    assert(0 <= TNF && TNF <= 7);
    return ((MB as int) << 7) |
        ((ME as int) << 6) |
        ((CF as int) << 5) |
        ((SR as int) << 4) |
        ((IL as int) << 3) |
        (TNF & 7);
  }
}

/// base class of all types of records
/// should not be used directly
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

  // TODO: try to use enum
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

  Uint8List id;
  RecordFlags flags;
  Record();

  static Record decode(ByteStream stream) {
    var flags = new RecordFlags(stream.readByte());

    num TYPE_LENTH = stream.readByte();
    num PAYLOAD_LENTH;
    num ID_LENTH = 0;

    if (flags.SR) {
      PAYLOAD_LENTH = stream.readByte();
    } else {
      PAYLOAD_LENTH = stream.readInt(4);
    }
    if (flags.IL) {
      ID_LENTH = stream.readByte();
    }

    if ([0, 5, 6].contains(flags.TNF)) {
      assert(TYPE_LENTH == 0, "TYPE_LENTH must be 0 when TNF is 0,5,6");
    }
    if (flags.TNF == 0) {
      assert(ID_LENTH == 0, "ID_LENTH must be 0 when TNF is 0");
      assert(PAYLOAD_LENTH == 0, "PAYLOAD_LENTH must be 0 when TNF is 0");
    }
    if ([1, 2, 3, 4].contains(flags.TNF)) {
      assert(TYPE_LENTH == 0, "TYPE_LENTH must be >0 when TNF is 1,2,3,4");
    }

    var TYPE = stream.readBytes(TYPE_LENTH);
    var ID = stream.readBytes(ID_LENTH);
    var PAYLOAD = stream.readBytes(PAYLOAD_LENTH);

    var typeNameFormat = tnfMap[flags.TNF];
    var type = utf8.decode(TYPE);

    Record record;

    if (typeNameFormat == "nfcWellKnown") {
      //urn:nfc:wkt
      if (type == URIRecord.type) {
        //URI
        record = URIRecord.decodePayload(PAYLOAD);
      } else if (type == "T") {
        // TODO: remove hardcode types
        //Text
        record = TextRecord.decodePayload(PAYLOAD);
      } else if (type == "Sp") {
        //Smart Poster

      } else if (type == "Sig") {
        //Signature
        record = SignatureRecord.decodePayload(PAYLOAD);
      }
    } else if (typeNameFormat == "media") {
      record = MIMERecord.decodePayload(PAYLOAD);
    } else if (typeNameFormat == "absoluteURI") {
      record = new absoluteUriRecord(type);
    } else {
      record = new RawRecord(TYPE, PAYLOAD);
    }

    record.id = ID;
    record.flags = flags;
    return record;
  }

  static String decodeType(num TNF, Uint8List TYPE) {
    return prefixMap[TNF];
  }

  static void error(String fmt) {}

  /// encode this record to raw byte data
  Uint8List encode() {
    throw "encoding not implemented on general type";
  }

  /// used internally to encode raw messages
  Uint8List encodeRaw(dynamic type, Uint8List payload) {
    // TODO: encode using type, id, payload and flags
    if (type is String) {
      // TODO: encode type to byte
    } else if (type is Uint8List) {
      // do nothing
    } else {
      throw "type must be String or Uint8List";
    }
    var encoded = new Uint8List(0);
    // flags
    var encodedFlags = flags.encode();
    encoded.add(encodedFlags);
    // TODO: more fields
    return encoded;
  }
}
