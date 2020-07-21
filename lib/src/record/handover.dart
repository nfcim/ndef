import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';

import '../record.dart';
import 'deviceinfo.dart';

// Handover is use to connect Wifi or bluetooth

enum CarrierPowerState { inactive, active, activating, unknown }

class AlternativeCarrierRecord extends Record {
  static const String recordType = "urn:nfc:wkt:ac";

  static const String decodedType = "ac";

  @override
  String get _decodedType {
    return AlternativeCarrierRecord.decodedType;
  }

  CarrierPowerState carrierPowerState;
  String carrierDataReference;
  List<String> auxDataReferenceList;

  AlternativeCarrierRecord({String carrierPower}) {
    auxDataReferenceList = new List<String>();
  }

  get carrierPowerStateIndex {
    return CarrierPowerState.values.indexOf(carrierPowerState);
  }

  set carrierPowerStateIndex(int carrierPowerStateIndex) {
    assert(carrierPowerStateIndex >= 0 &&
        carrierPowerStateIndex < CarrierPowerState.values.length);
    carrierPowerState = CarrierPowerState.values[carrierPowerStateIndex];
  }

  Uint8List get payload {
    Uint8List payload = new Uint8List(0);
    payload.add(carrierPowerStateIndex);

    // latin1 String and its corresponding Uint8List have the same length
    payload.add(carrierDataReference.length);
    payload.addAll(latin1.encode(carrierDataReference));

    assert(auxDataReferenceList.length < 255,
        "number of auxDataReference must be in [0,256)");

    payload.add(auxDataReferenceList.length);
    for (int i = 0; i < auxDataReferenceList.length; i++) {
      payload.add(auxDataReferenceList[i].length);
      payload.addAll(latin1.encode(auxDataReferenceList[i]));
    }

    return payload;
  }

  set payload(Uint8List payload) {
    var stream = new ByteStream(payload);

    carrierPowerStateIndex = stream.readByte() & 3;
    int carrierDataReferenceLength = stream.readByte();
    carrierDataReference =
        latin1.decode(stream.readBytes(carrierDataReferenceLength));

    int auxDataReferenceCount = stream.readByte();
    for (int i = 0; i < auxDataReferenceCount; i++) {
      int auxDataReferenceLength = stream.readByte();
      auxDataReferenceList
          .add(latin1.decode(stream.readBytes(auxDataReferenceLength)));
    }

    assert(stream.isEnd() == true,
        "payload has ${stream.unreadLength} bytes after decode");
  }
}

class CollisionResolutionRecord extends Record {
  // a 16-bit random number used to resolve a collision
  static const String recordType = "urn:nfc:wkt:cr";

  static const String decodedType = "cr";

  @override
  String get _decodedType {
    return CollisionResolutionRecord.decodedType;
  }

  int _randomNumber;

  CollisionResolutionRecord({int randomNumber}) {
    this.randomNumber = randomNumber;
  }

  get randomNumber {
    return _randomNumber;
  }

  set randomNumber(var randomNumber) {
    if (randomNumber is Uint8List) {
      randomNumber = ByteStream.list2int(randomNumber);
    } else if (!randomNumber is int) {
      throw "randomNumber expects an int or Uint8List";
    }
    assert(randomNumber >= 0 && randomNumber <= 0xffff);
    _randomNumber = randomNumber;
  }

  Uint8List get payload {
    return ByteStream.int2list(randomNumber, 2);
  }

  set payload(Uint8List payload) {
    this.randomNumber = payload;
  }
}

class ErrorRecord extends Record {
  // used in the HandoverSelectRecord
  static const String recordType = "urn:nfc:wkt:err";

  static const String decodedType = "err";

  static const List<String> errorStringMap = [
    "temporarily out of memory, may retry after X milliseconds",
    "permanently out of memory, may retry with at most X octets",
    "carrier specific error, may retry after X milliseconds"
  ];

  int errorReason;
  Uint8List errorData;

  @override
  String get _decodedType {
    return HandoverRequestRecord.decodedType;
  }

  get errorDataInt {
    assert(errorReason >= 0 && errorReason < 3);
    return ByteStream.list2int(errorData);
  }

  get errorString {
    if (errorReason >= 0 && errorReason < 3) {
      return errorStringMap[errorReason].replaceFirst('X', '$errorDataInt');
    } else {
      var errorDataString = ByteStream.list2hexString(errorData);
      return "Reason $errorReason Data $errorDataString";
    }
  }

  Uint8List get payload {
    Uint8List payload;
    assert(errorReason != 0, "error reason must not be 0");
    payload = [errorReason] + errorData;
    return payload;
  }

  set payload(Uint8List payload) {
    ByteStream stream = new ByteStream(payload);
    errorReason = stream.readByte();
    assert(errorReason != 0, "error reason must not be 0");

    if (errorReason == 1) {
      errorData = stream.readBytes(1);
    } else if (errorReason == 2) {
      errorData = stream.readBytes(4);
    } else if (errorReason == 3) {
      errorData = stream.readBytes(1);
    } else {
      errorData = stream.readBytes(stream.unreadLength);
    }
    stream.checkEmpty();
  }
}

class HandoverRecord extends Record {
  int _version;
  List<AlternativeCarrierRecord> alternativeCarrierRecordList;
  List<Record> unknownRecordList;

  HandoverCarrierRecord() {
    alternativeCarrierRecordList = new List<AlternativeCarrierRecord>();
    unknownRecordList = new List<Record>();
  }

  get versionMajor {
    return _version >> 4;
  }

  get versionMinor {
    return _version & 0xf;
  }

  get versionString {
    return "$versionMajor.$versionMinor";
  }

  get allRecordList {
    return alternativeCarrierRecordList + unknownRecordList;
  }

  void addRecord(Record record) {
    if (record is AlternativeCarrierRecord) {
      alternativeCarrierRecordList.add(record);
    } else {
      unknownRecordList.add(record);
    }
  }

  Uint8List get payload {
    Uint8List data = encodeNdefMessage(allRecordList);
    Uint8List payload = [_version] + data;
    return payload;
  }

  set payload(Uint8List payload) {
    _version = payload[0];
    var records = decodeRawNdefMessage(
      payload.sublist(1),
    );
    for (int i = 0; i < records.length; i++) {
      addRecord(records[i]);
    }
  }
}

class HandoverRequestRecord extends HandoverRecord {
  static const String recordType = "urn:nfc:wkt:Hr";

  static const String decodedType = "Hr";

  @override
  String get _decodedType {
    return HandoverRequestRecord.decodedType;
  }

  List<CollisionResolutionRecord> collisionResolutionRecordList;

  HandoverRequestRecord() {
    collisionResolutionRecordList = new List<CollisionResolutionRecord>();
  }

  static Record typeFactory(TypeNameFormat tnf, String decodedType) {
    Record record;
    if (tnf == TypeNameFormat.nfcWellKnown) {
      if (decodedType == AlternativeCarrierRecord.decodedType) {
        record = AlternativeCarrierRecord();
      } else if (decodedType == CollisionResolutionRecord.decodedType) {
        record = CollisionResolutionRecord();
      } else if (decodedType == HandoverCarrierRecord.decodedType) {
        record = HandoverCarrierRecord();
      } else if (decodedType == DeviceInformationRecord.decodedType) {
        record = DeviceInformationRecord();
      } else {
        return Record();
      }
    } else {
      record = new Record();
    }
    return record;
  }

  @override
  void addRecord(Record record) {
    if (record is AlternativeCarrierRecord) {
      alternativeCarrierRecordList.add(record);
    } else if (record is CollisionResolutionRecord) {
      collisionResolutionRecordList.add(record);
    } else {
      unknownRecordList.add(record);
    }
  }

  get _typeFactory {
    return HandoverRequestRecord.typeFactory;
  }

  get collisionResolutionNumber {
    if (collisionResolutionRecordList.length >= 1) {
      return collisionResolutionRecordList[0].randomNumber;
    } else {
      return null;
    }
  }

  @override
  get allRecordList {
    return super.allRecordList + collisionResolutionRecordList;
  }

  Uint8List get payload {
    if (_version > 0x11) {
      if (collisionResolutionNumber == null) {
        throw "Handover Request Record must have a Collision Resolution Record";
      }
    }
    return super.payload;
  }

  set payload(Uint8List payload) {
    super.payload = payload;
    if (_version > 0x11) {
      if (collisionResolutionNumber == null) {
        throw "Handover Request Record must have a Collision Resolution Record";
      }
    }
  }
}

class HandoverSelectRecord extends HandoverRecord {
  static const String recordType = "urn:nfc:wkt:Hs";

  static const String decodedType = "Hs";

  @override
  String get _decodedType {
    return HandoverSelectRecord.decodedType;
  }

  List<ErrorRecord> errorRecordList;

  HandoverSelectRecord() {
    errorRecordList = new List<ErrorRecord>();
  }

  static Record typeFactory(TypeNameFormat tnf, String decodedType) {
    Record record;
    if (tnf == TypeNameFormat.nfcWellKnown) {
      if (decodedType == AlternativeCarrierRecord.decodedType) {
        record = AlternativeCarrierRecord();
      } else if (decodedType == ErrorRecord.decodedType) {
        record = ErrorRecord();
      } else if (decodedType == DeviceInformationRecord.decodedType) {
        record = DeviceInformationRecord();
      } else {
        return Record();
      }
    } else {
      record = new Record();
    }
    return record;
  }

  @override
  void addRecord(Record record) {
    if (record is AlternativeCarrierRecord) {
      alternativeCarrierRecordList.add(record);
    } else if (record is ErrorRecord) {
      errorRecordList.add(record);
    } else {
      unknownRecordList.add(record);
    }
  }

  get _typeFactory {
    return HandoverSelectRecord.typeFactory;
  }

  get error {
    if (errorRecordList.length >= 1) {
      return errorRecordList[0];
    } else {
      return null;
    }
  }

  @override
  get allRecordList {
    return super.allRecordList + errorRecordList;
  }

  Uint8List get payload {
    if (_version < 0x12 && errorRecordList.length >= 1) {
      throw "can not encode error record for version " + versionString;
    }
    return super.payload;
  }
}

class HandoverMediationRecord extends HandoverRecord {
  static const String recordType = "urn:nfc:wkt:Hm";

  static const String decodedType = "Hm";

  @override
  String get _decodedType {
    return HandoverMediationRecord.decodedType;
  }
}

class HandoverInitiateRecord extends HandoverRecord {
  static const String recordType = "urn:nfc:wkt:Hi";

  static const String decodedType = "Hi";

  @override
  String get _decodedType {
    return HandoverInitiateRecord.decodedType;
  }
}

class HandoverCarrierRecord extends HandoverRecord {
  static const String recordType = "urn:nfc:wkt:Hc";

  static const String decodedType = "Hc";

  @override
  String get _decodedType {
    return HandoverCarrierRecord.decodedType;
  }

  int ctf;
  String carrierTypeSuffix;
  Uint8List carrierData;

  get carrierType {
    return Record.typePrefixes[ctf] + carrierTypeSuffix;
  }

  Uint8List get payload {
    Uint8List payload;
    Uint8List carrierTypeBytes = utf8.encode(carrierTypeSuffix);
    payload = [ctf, carrierTypeBytes.length] + carrierTypeBytes + carrierData;
    return payload;
  }

  set payload(Uint8List payload) {
    ByteStream stream = new ByteStream(payload);
    ctf = stream.readByte() & 7;
    int carrierTypeLength = stream.readByte();
    carrierTypeSuffix = utf8.decode(stream.readBytes(carrierTypeLength));
    carrierData = stream.readAll();
  }
}
