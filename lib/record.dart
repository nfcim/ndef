import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';

import 'utilities.dart';
import 'record/wellknown.dart';
import 'record/uri.dart';
import 'record/text.dart';
import 'record/signature.dart';
import 'record/deviceinfo.dart';
import 'record/mime.dart';
import 'record/bluetooth.dart';
import 'record/absoluteUri.dart';
import 'record/handover.dart';

/// Represent the flags in the header of a NDEF record.
class NDEFRecordFlags {
  /// Message Begin
  /// The MB flag is a 1-bit field that when set indicates
  /// the start of an NDEF message (see section 2.3.1).
  ///
  /// Section 2.3.1
  /// An NDEF message is composed of one or more NDEF records.
  /// 一条NDEF message是由一个或者多个NDEF records组成的。
  /// The first record in a message is marked with the MB (Message Begin) flag
  /// set and the last record in the message is marked with the ME (Message End) flag
  /// set (see sections 3.2.1 and 3.2.2).
  /// 最最基本的解释：在这么多个record中，第一个（the first record 就是MB（Message Begin））
  /// 相同，the last record便是ME（Message End）
  ///
  /// The minimum message length is one record which is achieved
  /// by setting both the MB and the ME flag in the same record.
  /// 小知识：最最小的message长度就是一个record（由 MB 和 ME flag 同时标记在同一个record中）
  ///
  /// Attention!!!
  ///   1.NDEF messages MUST NOT overlap; that is, the MB and the ME flags
  ///   MUST NOT be used to nest NDEF messages
  ///   在NDEF message中不允许出现重复（overlap）的情况，放到实际来看，MB 和 Me 只能在一个NDEF Message
  ///   中出现一次。
  ///   2.MB 和 ME 都是一位的字段值哦。
  ///
  // ignore: non_constant_identifier_names
  bool MB = false;

  /// Message End
  /// The ME flag is a 1-bit field that when set indicates the end of
  /// an NDEF message (see section 2.3.1).
  ///
  /// Note, that in case of a chunked payload, the ME flag is set only
  /// in the terminating record chunk of that chunked payload (see section 2.3.3).
  /// */
  // ignore: non_constant_identifier_names
  bool ME = false;

  /// Chunk Flag
  /// The CF flag is a 1-bit field indicating that this is either
  /// the first record chunk or a middle record chunk of a chunked payload
  /// */
  // ignore: non_constant_identifier_names
  bool CF = false;

  /// Short Record */
  // ignore: non_constant_identifier_names
  bool SR = false;

  /// ID Length */
  // ignore: non_constant_identifier_names
  bool IL = false;

  /// Type Name Format */
  // ignore: non_constant_identifier_names
  int TNF = 0;

  NDEFRecordFlags({int?
  data}) {
    decode(data);
  }

  int encode() {
    assert(0 <= TNF && TNF<= 7);
    return (MB.toInt() << 7) |
        (ME.toInt() << 6) |
        (CF.toInt() << 5) |
        (SR.toInt() << 4) |
        (IL.toInt() << 3) |
        (TNF & 7);
  }

  void decode(int? data) {
    if (data != null) {
      if (data < 0 || data >= 256) {
        throw "Data to decode in flags must be in [0, 256), got $data";
      }
      MB = ((data >> 7) & 1) == 1;
      ME = ((data >> 6) & 1) == 1;
      CF = ((data >> 5) & 1) == 1;
      SR = ((data >> 4) & 1) == 1;
      IL = ((data >> 3) & 1) == 1;
      TNF = data & 7;
    }
  }

  void resetPositionFlag() {
    MB = false;
    ME = false;
  }
}

/// The TNF field of a NDEF record.
enum TypeNameFormat {
  empty,
  nfcWellKnown,
  media,
  absoluteURI,
  nfcExternal,
  unknown,
  unchanged
}

/// Construct an instance of a specific type (subclass) of [NDEFRecord] according to [tnf] and [classType]
typedef NDEFRecord? TypeFactory(TypeNameFormat tnf, String classType);

/// The base class of all types of records.
/// Also represents an record of unknown type.
class NDEFRecord {
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
  static const TypeNameFormat? classTnf = null;

  TypeNameFormat get tnf {
    return TypeNameFormat.values[flags.TNF];
  }

  set tnf(TypeNameFormat? tnf) {
    flags.TNF = TypeNameFormat.values.indexOf(tnf!);
  }

  /// 此处埋个小伏笔，encodeType这个参数到底是nullable嘛？
  Uint8List? encodedType;

  set decodedType(String? decodedType) {
    encodedType = utf8.encode(decodedType!) as Uint8List?;
  }

  String? get decodedType {
    if (encodedType == null) {
      return null;
    }
    return utf8.decode(encodedType!);
  }

  set type(Uint8List? type) {
    encodedType = type;
  }

  Uint8List? get type {
    if (encodedType != null) {
      return encodedType;
    } else {
      // no encodedType set, might be a directly initialized subclass
      if (decodedType == null) {
        return null;
      } else {
        return utf8.encode(decodedType!) as Uint8List;
      }
    }
  }

  String? get fullType {
    if (decodedType == null) {
      return null;
    }
    return tnfString[flags.TNF] + decodedType!;
  }

  /// Hex String of id, return "(empty)" when the id bytes is null
  String get idString {
    return id == null ? "(empty)" : id!.toHexString();
  }

  set idString(String? value) {
    id = latin1.encode(value!);
  }

  static const int classMinPayloadLength = 0;
  static const int? classMaxPayloadLength = null;

  int get minPayloadLength {
    return classMinPayloadLength;
  }

  int? get maxPayloadLength {
    return classMaxPayloadLength;
  }

  String get basicInfoString {
    var str = "id=$idString ";
    str += "typeNameFormat=$tnf ";
    str += "type=$decodedType ";
    return str;
  }

  @override
  String toString() {
    var str = "Record: ";
    str += basicInfoString;
    str += "payload=${payload!.toHexString()}";
    return str;
  }

  late Uint8List? id;
  Uint8List? payload;
  late NDEFRecordFlags flags;

  NDEFRecord(
      { TypeNameFormat? tnf, Uint8List? type, Uint8List? id, Uint8List? payload}) {
    flags = new NDEFRecordFlags();
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

  /// Construct an instance of a specific type (subclass) of [NDEFRecord] according to tnf and type
  static NDEFRecord defaultTypeFactory(TypeNameFormat? tnf, String? classType) {
    NDEFRecord? record;
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
      } else if (classType == HandoverCarrierRecord.classType) {
        record = HandoverCarrierRecord();
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
      record = NDEFRecord(tnf: tnf);
    }
    return record;
  }

  /// Decode a [NDEFRecord] record from raw data.
  static NDEFRecord doDecode(
      TypeNameFormat? tnf, Uint8List? type, Uint8List? payload,
      { Uint8List? id, TypeFactory? typeFactory = NDEFRecord.defaultTypeFactory}) {
    NDEFRecord? record = typeFactory!(tnf!, utf8.decode(type!));
    if (payload!.length < record!.minPayloadLength) {
      throw "Payload length must be >= ${record.minPayloadLength}";
    }
    if (record.maxPayloadLength != null &&
        payload.length < record.maxPayloadLength!) {
      throw "Payload length must be <= ${record.maxPayloadLength}";
    }
    record.id = id;
    record.type = type;
    // use setter for implicit decoding
    record.payload = payload;
    return record;
  }

  /// Decode a NDEF [NDEFRecord] from part of [ByteStream].
  static NDEFRecord decodeStream(ByteStream stream, TypeFactory typeFactory) {
    var flags = new NDEFRecordFlags(data: stream.readByte());

    //TODO: Convert "num" to "int" for null-safety
    int typeLength = stream.readByte();
    int payloadLength;
    int idLength = 0;
    if (flags.SR) {
      payloadLength = stream.readByte();
    } else {
      payloadLength = stream.readInt(4);
    }
    if (flags.IL) {
      idLength = stream.readByte();
    }

    if ([0, 5, 6].contains(flags.TNF)) {
      assert(typeLength == 0, "TYPE_LENGTH must be 0 when TNF is 0,5,6");
    }
    if (flags.TNF == 0) {
      assert(idLength == 0, "ID_LENGTH must be 0 when TNF is 0");
      assert(payloadLength == 0, "PAYLOAD_LENGTH must be 0 when TNF is 0");
    }
    if ([1, 2, 3, 4].contains(flags.TNF)) {
      assert(typeLength > 0, "TYPE_LENGTH must be > 0 when TNF is 1,2,3,4");
    }

    var type = stream.readBytes(typeLength);

    Uint8List? id;
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

  /// Encode this [NDEFRecord] to raw byte data.
  Uint8List encode() {
    if (type == null) {
      throw "Type is null, please set type before encode";
    }

    if (payload == null) {
      throw "Payload is null, please set parameters or set payload directly before encode";
    }

    // var encoded = new List<int>();
    var encoded = <int>[];

    // check and canonicalize
    if (this.id == null) {
      flags.IL = false;
    } else {
      flags.IL = true;
    }

    if (payload!.length < 256) {
      flags.SR = true;
    } else {
      flags.SR = false;
    }

    // flags
    var encodedFlags = flags.encode();
    encoded.add(encodedFlags);

    // type length
    if (type!.length >= 256) {
      throw "Number of bytes of type must be in [0,256), got ${type!.length}";
    }
    encoded += [type!.length];

    // use getter for implicit encoding
    var encodedPayload = payload;

    // payload length
    if (encodedPayload!.length < 256) {
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
      if (id!.length >= 256) {
        throw "Number of bytes of identifier must be in [0,256), got ${id!.length}";
      }
      encoded += [id!.length];
    }

    // type
    encoded += type!;

    // ID
    if (id != null) {
      encoded += id!;
    }

    // payload
    encoded += encodedPayload;

    return new Uint8List.fromList(encoded);
  }

  bool isEqual(NDEFRecord other) {
    return (other is NDEFRecord) &&
        (tnf == other.tnf) &&
        ByteUtils.bytesEqual(type!, other.type) &&
        ByteUtils.bytesEqual(id, other.id) &&
        ByteUtils.bytesEqual(payload, other.payload);
  }
}
