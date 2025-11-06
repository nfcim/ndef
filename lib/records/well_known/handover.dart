import 'dart:convert';
import 'dart:typed_data';

// this file uses too many symbols, import the whole library instead
import 'package:ndef/ndef.dart';
import 'package:ndef/utilities.dart';

/// Power state of a carrier in connection handover.
enum CarrierPowerState {
  /// Carrier is inactive.
  inactive,

  /// Carrier is active and ready.
  active,

  /// Carrier is activating.
  activating,

  /// Carrier state is unknown.
  unknown,
}

/// A NDEF record describing an alternative carrier for connection handover.
///
/// This record identifies a carrier technology and its power state.
class AlternativeCarrierRecord extends WellKnownRecord {
  /// The type identifier for Alternative Carrier records.
  static const String classType = "ac";

  @override
  String get decodedType {
    return AlternativeCarrierRecord.classType;
  }

  /// The minimum payload length for Alternative Carrier records.
  static const int classMinPayloadLength = 2;

  @override
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

  /// The power state of the carrier.
  late CarrierPowerState carrierPowerState;

  /// Reference to the carrier data record.
  late Uint8List carrierDataReference;

  /// List of auxiliary data references.
  late List<Uint8List> auxDataReferenceList;

  /// Constructs an [AlternativeCarrierRecord] with carrier information.
  AlternativeCarrierRecord({
    CarrierPowerState? carrierPowerState,
    Uint8List? carrierDataReference,
    List<Uint8List>? auxDataReferenceList,
  }) {
    if (carrierPowerState != null) {
      this.carrierPowerState = carrierPowerState;
    }
    if (carrierDataReference != null) {
      this.carrierDataReference = carrierDataReference;
    }
    this.auxDataReferenceList = auxDataReferenceList ?? <Uint8List>[];
  }

  /// Gets the carrier power state as an index.
  int get carrierPowerStateIndex {
    return CarrierPowerState.values.indexOf(carrierPowerState);
  }

  /// Sets the carrier power state from an index.
  set carrierPowerStateIndex(int carrierPowerStateIndex) {
    assert(
      carrierPowerStateIndex >= 0 &&
          carrierPowerStateIndex < CarrierPowerState.values.length,
    );
    carrierPowerState = CarrierPowerState.values[carrierPowerStateIndex];
  }

  @override
  Uint8List get payload {
    var payload = <int>[];
    payload.add(carrierPowerStateIndex);

    // latin1 String and its corresponding Uint8List have the same length
    payload.add(carrierDataReference.length);
    payload.addAll(carrierDataReference);

    assert(
      auxDataReferenceList.length < 255,
      "Number of auxDataReference must be in [0,256)",
    );

    payload.add(auxDataReferenceList.length);
    for (int i = 0; i < auxDataReferenceList.length; i++) {
      payload.add(auxDataReferenceList[i].length);
      payload.addAll(auxDataReferenceList[i]);
    }

    return Uint8List.fromList(payload);
  }

  @override
  set payload(Uint8List? payload) {
    var stream = ByteStream(payload!);

    carrierPowerStateIndex = stream.readByte() & 3;
    int carrierDataReferenceLength = stream.readByte();
    carrierDataReference = stream.readBytes(carrierDataReferenceLength);

    int auxDataReferenceCount = stream.readByte();
    for (int i = 0; i < auxDataReferenceCount; i++) {
      int auxDataReferenceLength = stream.readByte();
      auxDataReferenceList.add(stream.readBytes(auxDataReferenceLength));
    }

    assert(
      stream.isEnd() == true,
      "payload has ${stream.unreadLength} bytes after decode",
    );
  }
}

/// A NDEF record containing a 16-bit random number for collision resolution.
///
/// Used in connection handover to resolve collisions when both devices
/// attempt to initiate a handover simultaneously.
class CollisionResolutionRecord extends WellKnownRecord {
  /// The type identifier for Collision Resolution records.
  static const String classType = "cr";

  @override
  String get decodedType {
    return CollisionResolutionRecord.classType;
  }

  /// The minimum payload length for Collision Resolution records.
  static const int classMinPayloadLength = 2;

  /// The maximum payload length for Collision Resolution records.
  static const int classMaxPayloadLength = 2;

  @override
  int get minPayloadLength {
    return classMinPayloadLength;
  }

  @override
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

  /// Constructs a [CollisionResolutionRecord] with an optional [randomNumber].
  CollisionResolutionRecord({int? randomNumber}) {
    if (randomNumber != null) {
      this.randomNumber = randomNumber;
    }
  }

  /// Gets the 16-bit random number.
  int? get randomNumber {
    return _randomNumber;
  }

  /// Sets the random number from an int or Uint8List.
  set randomNumber(var randomNumber) {
    if (randomNumber is Uint8List) {
      randomNumber = (randomNumber).toInt();
    } else if (randomNumber is! int) {
      throw ArgumentError(
        "RandomNumber expects int or Uint8List, got ${randomNumber.runtimeType}",
      );
    }
    assert(randomNumber >= 0 && randomNumber <= 0xffff);
    _randomNumber = randomNumber;
  }

  @override
  Uint8List get payload {
    return _randomNumber.toBytes(2);
  }

  @override
  set payload(Uint8List? payload) {
    randomNumber = payload;
  }
}

enum ErrorReason {
  temporarilyOutOfMemory,
  permanentlyOutOfMemory,
  carrierSpecificError,
  other,
}

/// A NDEF record describing an error in connection handover.
///
/// Used in Handover Select records to indicate why a handover failed.
class ErrorRecord extends WellKnownRecord {
  /// The type identifier for Error records.
  static const String classType = "err";

  @override
  String get decodedType {
    return ErrorRecord.classType;
  }

  /// Map of error codes to human-readable descriptions.
  static const List<String> errorStringMap = [
    "temporarily out of memory, may retry after X milliseconds",
    "permanently out of memory, may retry with at most X octets",
    "carrier specific error, may retry after X milliseconds",
  ];

  @override
  String toString() {
    var str = "ErrorRecord: ";
    str += basicInfoString;
    str += "error=$errorString";
    return str;
  }

  late int _errorNum;

  /// Additional error-specific data.
  late Uint8List errorData;

  /// Constructs an [ErrorRecord] with an error number and optional data.
  ErrorRecord({int? errorNum, Uint8List? errorData}) {
    if (errorNum != null) {
      this.errorNum = errorNum;
    }
    if (errorData != null) {
      this.errorData = errorData;
    }
  }

  /// The minimum payload length for Error records.
  static const int classMinPayloadLength = 1;

  @override
  int get minPayloadLength {
    return classMinPayloadLength;
  }

  /// Gets the error number.
  int get errorNum {
    return _errorNum;
  }

  /// Sets the error number (must not be 0).
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

  @override
  Uint8List? get payload {
    var payload = [errorNum] + errorData;
    return Uint8List.fromList(payload);
  }

  @override
  set payload(Uint8List? payload) {
    ByteStream stream = ByteStream(payload!);
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

/// Base class for connection handover NDEF records.
///
/// Contains version information, alternative carrier records, and other
/// records used in the handover process.
class HandoverRecord extends WellKnownRecord {
  /// The handover protocol version.
  Version version = Version();

  /// List of alternative carrier records.
  late List<AlternativeCarrierRecord> alternativeCarrierRecordList;

  /// List of unknown/unrecognized records.
  late List<NDEFRecord> unknownRecordList;

  /// The minimum payload length for Handover records.
  static const int classMinPayloadLength = 1;

  @override
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

  /// Constructs a [HandoverRecord] with optional version and carrier records.
  HandoverRecord({
    String? versionString,
    List<AlternativeCarrierRecord>? alternativeCarrierRecordList,
  }) {
    this.alternativeCarrierRecordList =
        alternativeCarrierRecordList ?? <AlternativeCarrierRecord>[];
    unknownRecordList = <NDEFRecord>[];
    if (versionString != null) version.string = versionString;
  }

  /// Gets all records (carriers and unknown) as a single list.
  List<NDEFRecord> get allRecordList {
    return List<NDEFRecord>.from(alternativeCarrierRecordList) +
        unknownRecordList;
  }

  /// Type factory for handover constituent records.
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
      record = NDEFRecord(tnf: tnf);
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

  @override
  Uint8List? get payload {
    var data = encodeNdefMessage(allRecordList);
    // cast() 's use
    List<int>? payload = ([version.value] + data).cast();
    return Uint8List.fromList(payload);
  }

  @override
  set payload(Uint8List? payload) {
    version = Version(value: payload![0]);
    if (payload.length > 1) {
      var records = decodeRawNdefMessage(
        payload.sublist(1),
        typeFactory: _typeFactory,
      );
      for (int i = 0; i < records.length; i++) {
        addRecord(records[i]);
      }
    }
  }
}

/// A NDEF record for initiating connection handover.
///
/// Contains alternative carriers and collision resolution information.
class HandoverRequestRecord extends HandoverRecord {
  /// The type identifier for Handover Request records.
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

  /// List of collision resolution records.
  late List<CollisionResolutionRecord> collisionResolutionRecordList;

  /// Constructs a [HandoverRequestRecord] with version, collision resolution, and carriers.
  HandoverRequestRecord({
    String super.versionString = "1.3",
    int? collisionResolutionNumber,
    super.alternativeCarrierRecordList,
  }) {
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
      record = NDEFRecord(tnf: tnf);
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

  @override
  get _typeFactory {
    return HandoverRequestRecord.typeFactory;
  }

  int? get collisionResolutionNumber {
    if (collisionResolutionRecordList.isNotEmpty) {
      return collisionResolutionRecordList[0].randomNumber;
    } else {
      return null;
    }
  }

  set collisionResolutionNumber(int? collisionResolutionNumber) {
    if (collisionResolutionRecordList.isEmpty) {
      collisionResolutionRecordList.add(
        CollisionResolutionRecord(randomNumber: collisionResolutionNumber),
      );
    } else {
      collisionResolutionRecordList[0].randomNumber = collisionResolutionNumber;
    }
  }

  @override
  List<NDEFRecord> get allRecordList {
    return super.allRecordList + collisionResolutionRecordList;
  }

  @override
  Uint8List? get payload {
    if (version.value > 0x11) {
      if (collisionResolutionNumber == null) {
        throw ArgumentError(
          "Handover Request Record must have a Collision Resolution Record",
        );
      }
    }
    return super.payload;
  }

  @override
  set payload(Uint8List? payload) {
    super.payload = payload;
    if (version.value > 0x11) {
      if (collisionResolutionNumber == null) {
        throw ArgumentError(
          "Handover Request Record must have a Collision Resolution Record",
        );
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

  HandoverSelectRecord({
    String super.versionString = "1.3",
    ErrorRecord? error,
    super.alternativeCarrierRecordList,
  }) {
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
      record = NDEFRecord(tnf: tnf);
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

  @override
  get _typeFactory {
    return HandoverSelectRecord.typeFactory;
  }

  ErrorRecord? get error {
    if (errorRecordList.isNotEmpty) {
      return errorRecordList[0];
    } else {
      return null;
    }
  }

  set error(ErrorRecord? error) {
    if (errorRecordList.isEmpty) {
      errorRecordList.add(error!);
    } else {
      errorRecordList[0] = error!;
    }
  }

  @override
  List<NDEFRecord> get allRecordList {
    return super.allRecordList + errorRecordList;
  }

  @override
  Uint8List? get payload {
    if (version.value < 0x12 && errorRecordList.isNotEmpty) {
      throw ArgumentError(
        "Encoding error record version ${version.value} is not supported",
      );
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

  HandoverMediationRecord({
    String super.versionString = "1.3",
    super.alternativeCarrierRecordList,
  });
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

  HandoverInitiateRecord({
    String super.versionString = "1.3",
    super.alternativeCarrierRecordList,
  });
}

class HandoverCarrierRecord extends WellKnownRecord {
  static const String classType = "Hc";

  @override
  String get decodedType {
    return HandoverCarrierRecord.classType;
  }

  static const int classMinPayloadLength = 1;

  @override
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

  HandoverCarrierRecord({
    TypeNameFormat? carrierTnf,
    this.carrierType,
    Uint8List? carrierData,
    Uint8List? id,
  }) {
    if (carrierTnf != null) {
      this.carrierTnf = carrierTnf;
    }
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

  @override
  Uint8List? get payload {
    var carrierTypeBytes = utf8.encode(carrierType!);
    List<int>? payload = ([_carrierTnf, carrierTypeBytes.length] +
            carrierTypeBytes +
            carrierData)
        .cast();
    return Uint8List.fromList(payload);
  }

  @override
  set payload(Uint8List? payload) {
    ByteStream stream = ByteStream(payload!);
    _carrierTnf = stream.readByte() & 7;
    int carrierTypeLength = stream.readByte();
    carrierType = utf8.decode(stream.readBytes(carrierTypeLength));
    carrierData = stream.readAll();
  }
}
