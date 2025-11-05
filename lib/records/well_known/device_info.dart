import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import 'package:ndef/records/well_known/well_known.dart';
import 'package:ndef/utilities.dart';

/// A data element in a Device Information record.
///
/// Consists of a type identifier and a value.
class DataElement {
  /// The type identifier of the data element.
  late int type;

  /// The value of the data element as bytes.
  late Uint8List value;

  /// Constructs a [DataElement] with [type] and [value].
  DataElement(this.type, this.value);

  /// Constructs a [DataElement] with [type] and [valueString] encoded as UTF-8.
  DataElement.fromString(this.type, String valueString) {
    value = utf8.encode(valueString);
  }

  @override
  String toString() {
    var str = "DataElement: ";
    str += "type=$type ";
    str += "value=$value";
    return str;
  }
}

/// A NDEF record containing device information.
///
/// This record type stores information about a device such as vendor name,
/// model name, unique name, UUID, and version information.
class DeviceInformationRecord extends WellKnownRecord {
  /// The type identifier for Device Information records.
  static const String classType = "Di";

  @override
  String get decodedType {
    return DeviceInformationRecord.classType;
  }

  /// The minimum payload length for Device Information records.
  static const int classMinPayloadLength = 2;

  @override
  int get minPayloadLength {
    return classMinPayloadLength;
  }

  @override
  String toString() {
    var str = "DeviceInformationRecord: ";
    str += "vendorName=$vendorName ";
    str += "modelName=$modelName ";
    str += "uniqueName=$uniqueName ";
    str += "uuid=$uuid ";
    str += "version= $versionString ";
    str += "undefined= $undefinedData";
    return str;
  }

  /// The vendor name of the device.
  String? vendorName;

  /// The model name of the device.
  String? modelName;

  /// The unique name of the device.
  String? uniqueName;

  /// The version string of the device.
  String? versionString;

  /// The UUID as raw bytes.
  late Uint8List uuidData;

  /// Additional undefined data elements.
  late List<DataElement> undefinedData;

  /// Constructs a [DeviceInformationRecord] with optional device information fields.
  DeviceInformationRecord({
    this.vendorName,
    this.modelName,
    this.uniqueName,
    String? uuid,
    this.versionString,
    List<DataElement>? undefinedData,
  }) {
    if (uuid != null) {
      this.uuid = uuid;
    }
    this.undefinedData = undefinedData ?? [];
  }

  /// Gets the UUID as a formatted string.
  String get uuid {
    return Uuid.unparse(uuidData);
  }

  /// Sets the UUID from a formatted string.
  set uuid(String uuid) {
    uuidData = Uint8List.fromList(Uuid.parse(uuid));
  }

  void _addEncodedData(String? value, int type, List<int?> payload) {
    if (value != null) {
      payload.add(type);
      Uint8List valueBytes = utf8.encode(value);
      payload.add(valueBytes.length);
      payload.addAll(valueBytes);
    }
  }

  @override
  Uint8List? get payload {
    if (!(vendorName != null && modelName != null)) {
      throw ArgumentError(
        "Decoding requires the manufacturer and model name TLVs",
      );
    }
    List<int>? payload = [];

    // known data
    _addEncodedData(vendorName, 0, payload);
    _addEncodedData(modelName, 1, payload);
    _addEncodedData(uniqueName, 2, payload);
    payload.add(3);
    payload.add(uuidData.length);
    payload.addAll(uuidData);
    _addEncodedData(versionString, 4, payload);

    // undefined data
    for (int i = 0; i < undefinedData.length; i++) {
      payload.add(undefinedData[i].type);
      Uint8List valueBytes = undefinedData[i].value;
      payload.add(valueBytes.length);
      payload.addAll(valueBytes);
    }
    return Uint8List.fromList(payload);
  }

  @override
  set payload(Uint8List? payload) {
    ByteStream stream = ByteStream(payload!);
    while (!stream.isEnd()) {
      int type = stream.readByte();
      int length = stream.readByte();
      Uint8List value = stream.readBytes(length);
      switch (type) {
        case 0:
          vendorName = utf8.decode(value);
          break;
        case 1:
          modelName = utf8.decode(value);
          break;
        case 2:
          uniqueName = utf8.decode(value);
          break;
        case 3:
          uuidData = value;
          break;
        case 4:
          versionString = utf8.decode(value);
          break;
        default:
          undefinedData.add(DataElement(type, value));
          break;
      }
    }
    if (!(vendorName != null && modelName != null)) {
      throw ArgumentError(
        "Decoding requires the manufacturer and model name TLVs",
      );
    }
  }
}
