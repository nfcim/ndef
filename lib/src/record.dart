import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';

import 'byteStream.dart';
import 'record/uri.dart';
import 'record/text.dart';
import 'record/signature.dart';
import 'record/mime.dart';
import 'record/absoluteUri.dart';
import 'record/raw.dart';

class RecordFlags {
  /// Message Begin */
  bool MB = false;

  /// Message End */
  bool ME = false;

  /// Chunk Flag */
  bool CF = false;

  /// Short Record */
  bool SR = false;

  /// ID Length */
  bool IL = false;

  /// Type Name Format */
  int TNF = 0;

  RecordFlags({int data}) {
    if (data != null) {
      assert(0 <= data && data <= 255);
      MB = ((data >> 7) & 1) == 1;
      ME = ((data >> 6) & 1) == 1;
      CF = ((data >> 5) & 1) == 1;
      SR = ((data >> 4) & 1) == 1;
      IL = ((data >> 3) & 1) == 1;
      TNF = data & 7;
    }
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

enum TypeNameFormat {
  empty,
  nfcWellKnown,
  media,
  absoluteURI,
  nfcExternel,
  unknown,
  unchanged
}

/// base class of all types of records
class Record {
  static List<String> typePrefixes = [
    "",
    "urn:nfc:wkt:",
    "",
    "",
    "urn:nfc:ext:",
    "unknown",
    "unchanged"
  ];

  Uint8List encodedType;
  
  String get _decodedType {
    throw "not implemented in base class";
  }

  set type(Uint8List type) {
    encodedType = type;
  }

  Uint8List get type {
    if (encodedType != null) {
      return encodedType;
    } else {
      // no encodedType set, might be a directly initialized subclass
      return utf8.encode(_decodedType);
    }
  }

  Uint8List id;
  Uint8List payload;
  RecordFlags flags;
  Record();

  static Record doDecode(TypeNameFormat tnf, Uint8List type, Uint8List payload,
      {Uint8List id}) {

    Record record;
    var decodedType = utf8.decode(type);

    if (tnf == TypeNameFormat.nfcWellKnown) {
      // urn:nfc:wkt
      if (decodedType == URIRecord.decodedType) {
        // URI
        record = URIRecord();
      } else if (decodedType == TextRecord.decodedType) {
        // Text
        record = TextRecord();
      } else if (decodedType == "Sp") {
        // Smart Poster
        record = SmartposterRecord.decodePayload(payload);
      } else if (decodedType == "Sig") {
        // Signature
        record = SignatureRecord.decodePayload(payload);
      }
    } else if (tnf == TypeNameFormat.media) {
      record = MIMERecord.decodePayload(payload);
    } else if (tnf == TypeNameFormat.absoluteURI) {
      record = new absoluteUriRecord(decodedType); // FIXME: seems wrong
    } else {
      // unknown
      record = new Record();
    }

    record.id = id;
    record.type = type;
    // use setter for implicit decoding
    record.payload = payload;
    return record;
  }

  static Record decodeStream(ByteStream stream) {
    var flags = new RecordFlags(data: stream.readByte());

    num typeLength = stream.readByte();
    num payloadLength;
    num idLength = 0;

    if (flags.SR) {
      payloadLength = stream.readByte();
    } else {
      payloadLength = stream.readInt(4);
    }
    if (flags.IL) {
      idLength = stream.readByte();
    }

    if ([0, 5, 6].contains(flags.TNF)) {
      assert(typeLength == 0, "TYPE_LENTH must be 0 when TNF is 0,5,6");
    }
    if (flags.TNF == 0) {
      assert(idLength == 0, "ID_LENTH must be 0 when TNF is 0");
      assert(payloadLength == 0, "PAYLOAD_LENTH must be 0 when TNF is 0");
    }
    if ([1, 2, 3, 4].contains(flags.TNF)) {
      assert(typeLength == 0, "TYPE_LENTH must be > 0 when TNF is 1,2,3,4");
    }

    var type = stream.readBytes(typeLength);

    Uint8List id;
    if (idLength != 0) {
      id = stream.readBytes(idLength);
    }

    var payload = stream.readBytes(payloadLength);
    var typeNameFormat = TypeNameFormat.values[flags.TNF];

    var decoded = doDecode(typeNameFormat, type, payload, id: id);
    decoded.flags = flags;
    return decoded;
  }

  static String decodeType(num tnf, Uint8List type) {
    return typePrefixes[tnf];
  }

  static void error(String fmt) {}

  /// encode this record to raw byte data
  Uint8List encode() {
    var encoded = new Uint8List(0);

    // check and canonicalize
    if (this.id == null) {
      flags.IL = false;
    }

    if (payload.length < 256) {
      flags.SR = true;
    }

    // flags
    var encodedFlags = flags.encode();
    encoded.add(encodedFlags);

    // type length
    assert(type.length > 0 && type.length < 256);
    encoded += [type.length];

    // use gettter for implicit encoding
    var encodedPayload = payload;

    // payload length
    if (encodedPayload.length < 256) {
      encoded += [encodedPayload.length];
    } else {
      encoded += [
        encodedPayload.length & 0xff,
        (encodedPayload.length >> 8) & 0xff,
        (encodedPayload.length >> 16) & 0xff,
        (encodedPayload.length >> 24) & 0xff,
      ];
    }

    // ID length
    if (id != null) {
      assert(id.length > 0 && id.length < 256);
      encoded += [id.length];
    }

    // type
    encoded += type;

    // ID
    if (id != null) {
      encoded += id;
    }

    // payload
    encoded += encodedPayload;

    return encoded;
  }

}
