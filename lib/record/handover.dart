import 'dart:convert';
import 'dart:typed_data';

import '../ndef.dart';
import 'bluetooth.dart';
import 'deviceinfo.dart';
import 'wellknown.dart';

enum CarrierPowerState { inactive, active, activating, unknown }

class AlternativeCarrierRecord extends WellKnownRecord {
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
    str += "auxDataReferences=$auxDataReferenceList";
    return str;
  }

  late CarrierPowerState carrierPowerState;
  late Uint8List carrierDataReference;
  late List<Uint8List> auxDataReferenceList;

  AlternativeCarrierRecord(
      {CarrierPowerState? carrierPowerState,
      Uint8List? carrierDataReference,
      List<Uint8List>? auxDataReferenceList}) {
    if (carrierPowerState != null) {
      this.carrierPowerState = carrierPowerState;
    }
    if (carrierDataReference != null) {
      this.carrierDataReference = carrierDataReference;
    }
    this.auxDataReferenceList =
        auxDataReferenceList == null ? <Uint8List>[] : auxDataReferenceList;
  }

  int get carrierPowerStateIndex {
    return CarrierPowerState.values.indexOf(carrierPowerState);
  }

  set carrierPowerStateIndex(int carrierPowerStateIndex) {
    assert(carrierPowerStateIndex >= 0 &&
        carrierPowerStateIndex < CarrierPowerState.values.length);
    carrierPowerState = CarrierPowerState.values[carrierPowerStateIndex];
  }

  Uint8List get payload {
    var payload = <int>[];
    payload.add(carrierPowerStateIndex);

    // latin1 String and its corresponding Uint8List have the same length
    payload.add(carrierDataReference.length);
    payload.addAll(carrierDataReference);

    assert(auxDataReferenceList.length < 255,
        "Number of auxDataReference must be in [0,256)");

    payload.add(auxDataReferenceList.length);
    for (int i = 0; i < auxDataReferenceList.length; i++) {
      payload.add(auxDataReferenceList[i].length);
      payload.addAll(auxDataReferenceList[i]);
    }

    return new Uint8List.fromList(payload);
  }

  set payload(Uint8List? payload) {
    var stream = new ByteStream(payload!);

    carrierPowerStateIndex = stream.readByte() & 3;
    int carrierDataReferenceLength = stream.readByte();
    carrierDataReference = stream.readBytes(carrierDataReferenceLength);

    int auxDataReferenceCount = stream.readByte();
    for (int i = 0; i < auxDataReferenceCount; i++) {
      int auxDataReferenceLength = stream.readByte();
      auxDataReferenceList.add(stream.readBytes(auxDataReferenceLength));
    }

    assert(stream.isEnd() == true,
        "payload has ${stream.unreadLength} bytes after decode");
  }
}

class CollisionResolutionRecord extends WellKnownRecord {
  // a 16-bit random number used to resolve a collision
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
    str += "randomNumber=$randomNumber";
    return str;
  }

  late int _randomNumber;

  CollisionResolutionRecord({int? randomNumber}) {
    if (randomNumber != null) {
      this.randomNumber = randomNumber;
    }
  }

  int? get randomNumber {
    return _randomNumber;
  }

  set randomNumber(var randomNumber) {
    if (randomNumber is Uint8List) {
      randomNumber = (randomNumber).toInt();
    } else if (!(randomNumber is int)) {
      throw ArgumentError("RandomNumber expects int or Uint8List, got ${randomNumber.runtimeType}");
    }
    assert(randomNumber >= 0 && randomNumber <= 0xffff);
    _randomNumber = randomNumber;
  }

  Uint8List get payload {
    return _randomNumber.toBytes(2);
  }

  set payload(Uint8List? payload) {
    this.randomNumber = payload;
  }
}

enum ErrorReason {
  temporarilyOutOfMemory,
  permanentlyOutOfMemory,
  carrierSpecificError,
  other
}

class ErrorRecord extends WellKnownRecord {
  // used in the HandoverSelectRecord
  static const String classType = "err";

  @override
  String get decodedType {
    return ErrorRecord.classType;
  }

  static const List<String> errorStringMap = [
    "temporarily out of memory, may retry after X milliseconds",
    "permanently out of memory, may retry with at most X octets",
    "carrier specific error, may retry after X milliseconds"
  ];

  @override
  String toString() {
    var str = "ErrorRecord: ";
    str += basicInfoString;
    str += "error=$errorString";
    return str;
  }

  late int _errorNum;
  late Uint8List errorData;

  ErrorRecord({int? errorNum, Uint8List? errorData}) {
    if (errorNum != null) {
      this.errorNum = errorNum;
    }
    if (errorData != null) {
      this.errorData = errorData;
    }
  }

  static const int classMinPayloadLength = 1;

  int get minPayloadLength {
    return classMinPayloadLength;
  }

  int get errorNum {
    return _errorNum;
  }

  set errorNum(int errorNum) {
    if (errorNum == 0) {
      throw ArgumentError("Error reason must not be 0");
    }
    _errorNum = errorNum;
  }

  /// A read-only description of error reason and error data
  String get errorString {
    if (errorNum > 0 && errorNum <= 3) {
      var errorDataInt = errorData.toInt();
      return errorStringMap[errorNum - 1].replaceFirst('X', '$errorDataInt');
    } else {
      var errorDataString = errorData.toHexString();
      return "Reason $errorNum Data $errorDataString";
    }
  }

  ErrorReason get errorReason {
    if (errorNum >= 1 && errorNum <= 3) {
      return ErrorReason.values[errorNum - 1];
    } else {
      return ErrorReason.other;
    }
  }

  set errorReason(ErrorReason errorReason) {
    _errorNum = ErrorReason.values.indexOf(errorReason);
  }

  Uint8List? get payload {
    var payload = [errorNum] + errorData;
    return new Uint8List.fromList(payload);
  }

  set payload(Uint8List? payload) {
    ByteStream stream = new ByteStream(payload!);
    errorNum = stream.readByte();

    if (errorNum == 1) {
      errorData = stream.readBytes(1);
    } else if (errorNum == 2) {
      errorData = stream.readBytes(4);
    } else if (errorNum == 3) {
      errorData = stream.readBytes(1);
    } else {
      errorData = stream.readBytes(stream.unreadLength);
    }
  }
}

class HandoverRecord extends WellKnownRecord {
  Version version = Version();
  late List<AlternativeCarrierRecord> alternativeCarrierRecordList;
  late List<NDEFRecord> unknownRecordList;

  static const int classMinPayloadLength = 1;

  int get minPayloadLength {
    return classMinPayloadLength;
  }

  @override
  String toString() {
    var str = "HandoverRecord: ";
    str += basicInfoString;
    str += "version=${version.string} ";
    str += "alternativeCarrierRecords=$alternativeCarrierRecordList ";
    str += "unknownRecords=$unknownRecordList";
    return str;
  }

  HandoverRecord(
      {String? versionString,
      List<AlternativeCarrierRecord>? alternativeCarrierRecordList}) {
    this.alternativeCarrierRecordList = alternativeCarrierRecordList == null
        ? <AlternativeCarrierRecord>[]
        : alternativeCarrierRecordList;
    this.unknownRecordList = <NDEFRecord>[];
    if (versionString != null) this.version.string = versionString;
  }

  List<NDEFRecord> get allRecordList {
    return List<NDEFRecord>.from(alternativeCarrierRecordList) +
        unknownRecordList;
  }

  static NDEFRecord typeFactory(TypeNameFormat tnf, String classType) {
    NDEFRecord record;
    if (tnf == TypeNameFormat.nfcWellKnown) {
      if (classType == AlternativeCarrierRecord.classType) {
        record = AlternativeCarrierRecord();
      } else if (classType == DeviceInformationRecord.classType) {
        record = DeviceInformationRecord();
      } else {
        return WellKnownRecord();
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
      record = new NDEFRecord(tnf: tnf);
    }
    return record;
  }

  get _typeFactory {
    return HandoverRecord.typeFactory;
  }

  void addRecord(NDEFRecord record) {
    if (record is AlternativeCarrierRecord) {
      alternativeCarrierRecordList.add(record);
    } else {
      unknownRecordList.add(record);
    }
  }

  Uint8List? get payload {
    var data = encodeNdefMessage(allRecordList);
    // cast() 's use
    List<int>? payload = ([version.value] + data).cast();
    return Uint8List.fromList(payload);
  }

  set payload(Uint8List? payload) {
    version = Version(value: payload![0]);
    if (payload.length > 1) {
      var records =
          decodeRawNdefMessage(payload.sublist(1), typeFactory: _typeFactory);
      for (int i = 0; i < records.length; i++) {
        addRecord(records[i]);
      }
    }
  }
}

class HandoverRequestRecord extends HandoverRecord {
  static const String classType = "Hr";

  @override
  String get decodedType {
    return HandoverRequestRecord.classType;
  }

  @override
  String toString() {
    var str = "HandoverRequestRecord: ";
    str += basicInfoString;
    str += "version=${version.string} ";
    str += "alternativeCarrierRecords=$alternativeCarrierRecordList ";
    str += "collisionResolutionRecords=$collisionResolutionRecordList ";
    str += "unknownRecords=$unknownRecordList";
    return str;
  }

  late List<CollisionResolutionRecord> collisionResolutionRecordList;

  HandoverRequestRecord(
      {String versionString = "1.3",
      int? collisionResolutionNumber,
      List<AlternativeCarrierRecord>? alternativeCarrierRecordList})
      : super(
            versionString: versionString,
            alternativeCarrierRecordList: alternativeCarrierRecordList) {
    collisionResolutionRecordList = <CollisionResolutionRecord>[];
    if (collisionResolutionNumber != null) {
      this.collisionResolutionNumber = collisionResolutionNumber;
    }
  }

  static NDEFRecord typeFactory(TypeNameFormat tnf, String classType) {
    NDEFRecord record;
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
        return WellKnownRecord();
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
      record = new NDEFRecord(tnf: tnf);
    }
    return record;
  }

  @override
  void addRecord(NDEFRecord record) {
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

  int? get collisionResolutionNumber {
    if (collisionResolutionRecordList.length >= 1) {
      return collisionResolutionRecordList[0].randomNumber;
    } else {
      return null;
    }
  }

  set collisionResolutionNumber(int? collisionResolutionNumber) {
    if (collisionResolutionRecordList.length == 0) {
      collisionResolutionRecordList.add(new CollisionResolutionRecord(
          randomNumber: collisionResolutionNumber));
    } else {
      collisionResolutionRecordList[0].randomNumber = collisionResolutionNumber;
    }
  }

  @override
  List<NDEFRecord> get allRecordList {
    return super.allRecordList + collisionResolutionRecordList;
  }

  Uint8List? get payload {
    if (version.value > 0x11) {
      if (collisionResolutionNumber == null) {
        throw ArgumentError("Handover Request Record must have a Collision Resolution Record");
      }
    }
    return super.payload;
  }

  set payload(Uint8List? payload) {
    super.payload = payload;
    if (version.value > 0x11) {
      if (collisionResolutionNumber == null) {
        throw ArgumentError("Handover Request Record must have a Collision Resolution Record");
      }
    }
  }
}

class HandoverSelectRecord extends HandoverRecord {
  static const String classType = "Hs";

  @override
  String get decodedType {
    return HandoverSelectRecord.classType;
  }

  @override
  String toString() {
    var str = "HandoverSelectRecord: ";
    str += basicInfoString;
    str += "version=${version.value} ";
    str += "alternativeCarrierRecords=$alternativeCarrierRecordList ";
    str += "errorRecords=$errorRecordList ";
    str += "unknownRecords=$unknownRecordList";
    return str;
  }

  late List<ErrorRecord> errorRecordList;

  HandoverSelectRecord(
      {String versionString = "1.3",
      ErrorRecord? error,
      List<AlternativeCarrierRecord>? alternativeCarrierRecordList})
      : super(
            versionString: versionString,
            alternativeCarrierRecordList: alternativeCarrierRecordList) {
    errorRecordList = <ErrorRecord>[];
    if (error != null) {
      this.error = error;
    }
  }

  static NDEFRecord typeFactory(TypeNameFormat tnf, String classType) {
    NDEFRecord record;
    if (tnf == TypeNameFormat.nfcWellKnown) {
      if (classType == AlternativeCarrierRecord.classType) {
        record = AlternativeCarrierRecord();
      } else if (classType == ErrorRecord.classType) {
        record = ErrorRecord();
      } else if (classType == DeviceInformationRecord.classType) {
        record = DeviceInformationRecord();
      } else {
        return WellKnownRecord();
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
      record = new NDEFRecord(tnf: tnf);
    }
    return record;
  }

  @override
  void addRecord(NDEFRecord record) {
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

  ErrorRecord? get error {
    if (errorRecordList.length >= 1) {
      return errorRecordList[0];
    } else {
      return null;
    }
  }

  set error(ErrorRecord? error) {
    if (errorRecordList.length == 0) {
      errorRecordList.add(error!);
    } else {
      errorRecordList[0] = error!;
    }
  }

  @override
  List<NDEFRecord> get allRecordList {
    return super.allRecordList + errorRecordList;
  }

  Uint8List? get payload {
    if (version.value < 0x12 && errorRecordList.length >= 1) {
      throw ArgumentError("Encoding error record version ${version.value} is not supported");
    }
    return super.payload;
  }
}

class HandoverMediationRecord extends HandoverRecord {
  static const String classType = "Hm";

  @override
  String get decodedType {
    return HandoverMediationRecord.classType;
  }

  @override
  String toString() {
    var str = "HandoverMediationRecord: ";
    str += basicInfoString;
    str += "version=${version.value} ";
    str += "alternativeCarrierRecords=$alternativeCarrierRecordList ";
    str += "unknownRecords=$unknownRecordList";
    return str;
  }

  HandoverMediationRecord(
      {String versionString = "1.3",
      List<AlternativeCarrierRecord>? alternativeCarrierRecordList})
      : super(
            versionString: versionString,
            alternativeCarrierRecordList: alternativeCarrierRecordList);
}

class HandoverInitiateRecord extends HandoverRecord {
  static const String classType = "Hi";

  @override
  String get decodedType {
    return HandoverInitiateRecord.classType;
  }

  @override
  String toString() {
    var str = "HandoverInitiateRecord: ";
    str += basicInfoString;
    str += "version=${version.value} ";
    str += "alternativeCarrierRecords=$alternativeCarrierRecordList ";
    str += "unknownRecords=$unknownRecordList";
    return str;
  }

  HandoverInitiateRecord(
      {String versionString = "1.3",
      List<AlternativeCarrierRecord>? alternativeCarrierRecordList})
      : super(
            versionString: versionString,
            alternativeCarrierRecordList: alternativeCarrierRecordList);
}

class HandoverCarrierRecord extends WellKnownRecord {
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
    str += "carrierType=$carrierType ";
    str += "carrierData=$carrierData";
    return str;
  }

  HandoverCarrierRecord(
      {TypeNameFormat? carrierTnf,
      String? carrierType,
      Uint8List? carrierData,
      Uint8List? id}) {
    if (carrierTnf != null) {
      this.carrierTnf = carrierTnf;
    }
    this.carrierType = carrierType;
    if (carrierData != null) {
      this.carrierData = carrierData;
    }
    this.id = id;
  }

  int? _carrierTnf;
  String? carrierType;
  late Uint8List carrierData;

  TypeNameFormat get carrierTnf {
    return TypeNameFormat.values[_carrierTnf!];
  }

  set carrierTnf(TypeNameFormat carrierTnf) {
    _carrierTnf = TypeNameFormat.values.indexOf(carrierTnf);
  }

  String get carrierFullType {
    return NDEFRecord.tnfString[_carrierTnf!] + carrierType!;
  }

  Uint8List? get payload {
    var carrierTypeBytes = utf8.encode(carrierType!);
    List<int>? payload = ([_carrierTnf, carrierTypeBytes.length] +
            carrierTypeBytes +
            carrierData)
        .cast();
    return Uint8List.fromList(payload);
  }

  set payload(Uint8List? payload) {
    ByteStream stream = new ByteStream(payload!);
    _carrierTnf = stream.readByte() & 7;
    int carrierTypeLength = stream.readByte();
    carrierType = utf8.decode(stream.readBytes(carrierTypeLength));
    carrierData = stream.readAll();
  }
}
