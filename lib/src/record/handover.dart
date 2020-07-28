import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';
import 'package:ndef/src/record/bluetooth.dart';

import '../record.dart';
import 'deviceinfo.dart';

// Handover is use to connect Wifi or bluetooth

enum CarrierPowerState { inactive, active, activating, unknown }

class AlternativeCarrierRecord extends Record {
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "ac";

  @override
  String get decodedType {
    return AlternativeCarrierRecord.classType;
  }

  static const int classMinPayloadLength = 2;

  int get minPayloadLength {
    return classMinPayloadLength;
  }

  @override
  String toString() {
    var str = "AlternativeCarrierRecord: ";
    str += basicInfoString;
    str += "carrierPowerState=$carrierPowerState ";
    str += "carrierDataReference=$carrierDataReference ";
    str += "auxDataReferences=$auxDataReferenceList ";
    return str;
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
    var payload = new List<int>();
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

    return new Uint8List.fromList(payload);
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
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "cr";

  @override
  String get decodedType {
    return CollisionResolutionRecord.classType;
  }

  static const int classMinPayloadLength = 2;
  static const int classMaxPayloadLength = 2;

  int get minPayloadLength {
    return classMinPayloadLength;
  }

  int get maxPayloadLength {
    return classMaxPayloadLength;
  }

  @override
  String toString() {
    var str = "CollisionResolutionRecord: ";
    str += basicInfoString;
    str += "uri=$randomNumber ";
    return str;
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
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "err";

  static const List<String> errorStringMap = [
    "temporarily out of memory, may retry after X milliseconds",
    "permanently out of memory, may retry with at most X octets",
    "carrier specific error, may retry after X milliseconds"
  ];

  @override
  String toString() {
    var str = "ErrorRecord: ";
    str += basicInfoString;
    str += "error=$errorString ";
    return str;
  }

  int errorReason;
  Uint8List errorData;

  @override
  String get decodedType {
    return HandoverRequestRecord.classType;
  }

  static const int classMinPayloadLength = 1;

  int get minPayloadLength {
    return classMinPayloadLength;
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

  static const int classMinPayloadLength = 1;

  int get minPayloadLength {
    return classMinPayloadLength;
  }

  @override
  String toString() {
    var str = "HandoverRecord: ";
    str += basicInfoString;
    str += "version=$versionString ";
    str += "alternativeCarrierRecords=$alternativeCarrierRecordList ";
    str += "unknownRecords=$unknownRecordList ";
    return str;
  }

  HandoverRecord() {
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
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "Hr";

  @override
  String get decodedType {
    return HandoverRequestRecord.classType;
  }

  @override
  String toString() {
    var str = "HandoverRequestRecord: ";
    str += basicInfoString;
    str += "version=$versionString ";
    str += "alternativeCarrierRecords=$alternativeCarrierRecordList ";
    str += "collisionResolutionRecords=$collisionResolutionRecordList ";
    str += "unknownRecords=$unknownRecordList ";
    return str;
  }

  List<CollisionResolutionRecord> collisionResolutionRecordList;

  HandoverRequestRecord() {
    collisionResolutionRecordList = new List<CollisionResolutionRecord>();
  }

  static Record typeFactory(TypeNameFormat tnf, String classType) {
    Record record;
    if (tnf == TypeNameFormat.nfcWellKnown) {
      if (classType == AlternativeCarrierRecord.classType) {
        record = AlternativeCarrierRecord();
      } else if (classType == CollisionResolutionRecord.classType) {
        record = CollisionResolutionRecord();
      } else if (classType == HandoverCarrierRecord.classType) {
        record = HandoverCarrierRecord();
      } else if (classType == DeviceInformationRecord.classType) {
        record = DeviceInformationRecord();
      } else {
        return Record();
      }
    } else if (tnf == TypeNameFormat.media) {
      if (classType == BluetoothEasyPairingRecord.classType) {
        record = BluetoothEasyPairingRecord();
      } else if (classType == BluetoothLowEnergyRecord.classType) {
        record = BluetoothLowEnergyRecord();
      } else {
        record = MimeRecord();
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
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "Hs";

  @override
  String get decodedType {
    return HandoverSelectRecord.classType;
  }

  @override
  String toString() {
    var str = "HandoverSelectRecord: ";
    str += basicInfoString;
    str += "version=$versionString ";
    str += "alternativeCarrierRecords=$alternativeCarrierRecordList ";
    str += "errorRecords=$errorRecordList ";
    str += "unknownRecords=$unknownRecordList ";
    return str;
  }

  List<ErrorRecord> errorRecordList;

  HandoverSelectRecord() {
    errorRecordList = new List<ErrorRecord>();
  }

  static Record typeFactory(TypeNameFormat tnf, String classType) {
    Record record;
    if (tnf == TypeNameFormat.nfcWellKnown) {
      if (classType == AlternativeCarrierRecord.classType) {
        record = AlternativeCarrierRecord();
      } else if (classType == ErrorRecord.classType) {
        record = ErrorRecord();
      } else if (classType == DeviceInformationRecord.classType) {
        record = DeviceInformationRecord();
      } else {
        return Record();
      }
    } else if (tnf == TypeNameFormat.media) {
      if (classType == BluetoothEasyPairingRecord.classType) {
        record = BluetoothEasyPairingRecord();
      } else if (classType == BluetoothLowEnergyRecord.classType) {
        record = BluetoothLowEnergyRecord();
      } else {
        record = MimeRecord();
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
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "Hm";

  @override
  String get decodedType {
    return HandoverMediationRecord.classType;
  }

  @override
  String toString() {
    var str = "HandoverMediationRecord: ";
    str += basicInfoString;
    str += "version=$versionString ";
    str += "alternativeCarrierRecords=$alternativeCarrierRecordList ";
    str += "unknownRecords=$unknownRecordList ";
    return str;
  }
}

class HandoverInitiateRecord extends HandoverRecord {
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "Hi";

  @override
  String get decodedType {
    return HandoverInitiateRecord.classType;
  }

  @override
  String toString() {
    var str = "HandoverInitiateRecord: ";
    str += basicInfoString;
    str += "version=$versionString ";
    str += "alternativeCarrierRecords=$alternativeCarrierRecordList ";
    str += "unknownRecords=$unknownRecordList ";
    return str;
  }
}

class HandoverCarrierRecord extends HandoverRecord {
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "Hc";

  @override
  String get decodedType {
    return HandoverCarrierRecord.classType;
  }

  static const int classMinPayloadLength = 1;

  int get minPayloadLength {
    return classMinPayloadLength;
  }

  @override
  String toString() {
    var str = "HandoverCarrierRecord: ";
    str += basicInfoString;
    str += "version=$versionString ";
    str += "carrierType=$carrierType ";
    str += "alternativeCarrierRecords=$alternativeCarrierRecordList ";
    str += "unknownRecords=$unknownRecordList ";
    return str;
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
