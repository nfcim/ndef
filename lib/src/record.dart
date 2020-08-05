import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';
import 'package:ndef/src/record/bluetooth.dart';
import 'package:ndef/src/record/handover.dart';
import 'package:collection/collection.dart';

import 'byteStream.dart';
import 'record/wellknown.dart';
import 'record/uri.dart';
import 'record/text.dart';
import 'record/signature.dart';
import 'record/deviceinfo.dart';
import 'record/mime.dart';
import 'record/bluetooth.dart';
import 'record/absoluteUri.dart';

/// Represent the flags in the header of a NDEF record.
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
  int _TNF = 0;

  int get TNF {
    return _TNF;
  }

  set TNF(int TNF) {
    if (TNF < 0 || TNF >= 8) {
      throw "TNF number must be in [0,8)";
    }
    _TNF = TNF;
  }

  RecordFlags({int data}) {
    decode(data);
  }

  int encode() {
    return (bool2int(MB) << 7) |
        (bool2int(ME) << 6) |
        (bool2int(CF) << 5) |
        (bool2int(SR) << 4) |
        (bool2int(IL) << 3) |
        (TNF & 7);
  }

  void decode(int data) {
    if (data != null) {
      if (data < 0 || data >= 256) {
        throw "Data to decode in flags must be 1 byte";
      }
      MB = ((data >> 7) & 1) == 1;
      ME = ((data >> 6) & 1) == 1;
      CF = ((data >> 5) & 1) == 1;
      SR = ((data >> 4) & 1) == 1;
      IL = ((data >> 3) & 1) == 1;
      TNF = data & 7;
    }
  }
}

/// The TNF field of a NDEF record.
enum TypeNameFormat {
  empty,
  nfcWellKnown,
  media,
  absoluteURI,
  nfcExternel,
  unknown,
  unchanged
}

/// The base class of all types of records.
/// Also reprents an record of unknown type.
class Record {
  static const List<String> tnfString = [
    "",
    "urn:nfc:wkt:",
    "",
    "",
    "urn:nfc:ext:",
    "unknown",
    "unchanged"
  ];

  /// Predefined TNF of a specific record type.
  static const TypeNameFormat classTnf = null;

  TypeNameFormat get tnf {
    return TypeNameFormat.values[flags.TNF];
  }

  set tnf(TypeNameFormat tnf) {
    flags.TNF = TypeNameFormat.values.indexOf(tnf);
  }

  Uint8List encodedType;

  String get decodedType {
    return utf8.decode(encodedType);
  }

  set decodedType(String decodedType) {
    encodedType = utf8.encode(decodedType);
  }

  set type(Uint8List type) {
    encodedType = type;
  }

  Uint8List get type {
    if (encodedType != null) {
      return encodedType;
    } else {
      // no encodedType set, might be a directly initialized subclass
      return utf8.encode(decodedType);
    }
  }

  String get fullType {
    return tnfString[flags.TNF] + decodedType;
  }

  String get idString {
    if (id == null) {
      return "";
    } else {
      return latin1.decode(id);
    }
  }

  set idString(String value) {
    id = latin1.encode(value);
  }

  static const int classMinPayloadLength = 0;
  static const int classMaxPayloadLength = null;

  int get minPayloadLength {
    return classMinPayloadLength;
  }

  int get maxPayloadLength {
    return classMaxPayloadLength;
  }

  String get basicInfoString {
    var str = "id=$idString ";
    return str;
  }

  @override
  String toString() {
    var str = "Record: ";
    str += basicInfoString;
    str += "typeNameFormat=$tnf ";
    str += "type=$decodedType ";
    str += "payload=${ByteStream.list2hexString(payload)}";
    return str;
  }

  Uint8List id;
  Uint8List payload;
  RecordFlags flags;

  Record({TypeNameFormat tnf, Uint8List type, Uint8List id, Uint8List payload}) {
    flags = new RecordFlags();
    if (tnf == null) {
      flags.TNF = TypeNameFormat.values.indexOf(this.tnf);
    } else {
      if (this.tnf != TypeNameFormat.empty) {
        throw "TNF has not been set in subclass of Record";
      }
      this.tnf = tnf;
    }
    this.type = type;
    this.id = id;
    if (payload != null) {
      this.payload = payload;
    }
  }

  /// Construct an instance of a specific type (subclass) of [Record]
  static Record typeFactory(TypeNameFormat tnf, String classType) {
    Record record;
    if (tnf == TypeNameFormat.nfcWellKnown) {
      if (classType == UriRecord.classType) {
        record = UriRecord();
      } else if (classType == TextRecord.classType) {
        record = TextRecord();
      } else if (classType == SmartPosterRecord.classType) {
        record = SmartPosterRecord();
      } else if (classType == SignatureRecord.classType) {
        record = SignatureRecord();
      } else if (classType == HandoverRequestRecord.classType) {
        record = HandoverRequestRecord();
      } else if (classType == HandoverSelectRecord.classType) {
        record = HandoverSelectRecord();
      } else if (classType == HandoverMediationRecord.classType) {
        record = HandoverMediationRecord();
      } else if (classType == HandoverInitiateRecord.classType) {
        record = HandoverInitiateRecord();
      } else if (classType == DeviceInformationRecord.classType) {
        record = DeviceInformationRecord();
      } else {
        record = WellKnownRecord();
      }
    } else if (tnf == TypeNameFormat.media) {
      if (classType == BluetoothEasyPairingRecord.classType) {
        record = BluetoothEasyPairingRecord();
      } else if (classType == BluetoothLowEnergyRecord.classType) {
        record = BluetoothLowEnergyRecord();
      } else {
        record = MimeRecord();
      }
    } else if (tnf == TypeNameFormat.absoluteURI) {
      record = AbsoluteUriRecord();
    } else {
      record = Record(tnf:tnf);
    }
    return record;
  }

  /// Decode a [Record] record from raw data.
  static Record doDecode(TypeNameFormat tnf, Uint8List type, Uint8List payload,
      {Uint8List id, var typeFactory = Record.typeFactory}) {
    Record record = typeFactory(tnf, utf8.decode(type));
    if (payload.length < record.minPayloadLength) {
      throw "payload length must be >= ${record.minPayloadLength}";
    }
    if (record.maxPayloadLength != null &&
        payload.length < record.maxPayloadLength) {
      throw "payload length must be <= ${record.maxPayloadLength}";
    }
    record.id = id;
    record.type = type;
    // use setter for implicit decoding
    record.payload = payload;
    return record;
  }

  /// Decode a NDEF [Record] from part of [ByteStream]
  static Record decodeStream(ByteStream stream, var typeFactory) {
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
      assert(typeLength > 0, "TYPE_LENTH must be > 0 when TNF is 1,2,3,4");
    }

    var type = stream.readBytes(typeLength);

    Uint8List id;
    if (idLength != 0) {
      id = stream.readBytes(idLength);
    }

    var payload = stream.readBytes(payloadLength);
    var typeNameFormat = TypeNameFormat.values[flags.TNF];

    var decoded = doDecode(typeNameFormat, type, payload,
        id: id, typeFactory: typeFactory);
    decoded.flags = flags;
    return decoded;
  }

  /// Encode this [Record] to raw byte data.
  Uint8List encode() {
    var encoded = new List<int>();

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
    if (type.length >= 256) {
      throw "Number of bytes of type must be in [0,256)";
    }
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
      if (id.length >= 256) {
        throw "Number of bytes of identifier must be in [0,256)";
      }
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

    return new Uint8List.fromList(encoded);
  }

  bool isEqual(Record other) {
    Function eq = const ListEquality().equals;
    return (other is Record) &&
        (tnf == other.tnf) &&
        eq(type, other.type) &&
        (id == other.id) &&
        eq(payload, other.payload);
  }
}
