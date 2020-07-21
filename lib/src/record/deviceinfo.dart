import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';

import '../record.dart';

class DataElement {
  int type;
  Uint8List value;
  DataElement(this.type, this.value);
}

class DeviceInformationRecord extends Record {
  static const String recordType = "urn:nfc:wkt:Di";

  static const String decodedType = "Di";

  @override
  String get _decodedType {
    return DeviceInformationRecord.decodedType;
  }

  static const int minPayloadLength=2;

  int get _minPayloadLength{
    return minPayloadLength;
  }

  List<String> dataList;
  List<DataElement> undefinedData;

  DeviceInformationRecord(
      {String venderName,
      String modelName,
      String uniqueName,
      String uuid,
      String versionString,
      List<DataElement> undefinedData}) {
    dataList = new List<String>(5);
    this.venderName = venderName;
    this.modelName = modelName;
    this.uniqueName = uniqueName;
    this.uuid = uuid;
    this.versionString = versionString;
    this.undefinedData = undefinedData;
  }

  get vendorName {
    return dataList[0];
  }

  set venderName(String venderName) {
    dataList[0] = venderName;
  }

  get modelName {
    return dataList[1];
  }

  set modelName(String modelName) {
    dataList[1] = modelName;
  }

  get uniqueName {
    return dataList[2];
  }

  set uniqueName(String uniqueName) {
    dataList[2] = uniqueName;
  }

  get uuid {
    return dataList[3];
  }

  set uuid(String uuid) {
    dataList[3] = uuid;
  }

  get versionString {
    return dataList[4];
  }

  set versionString(String versionString) {
    dataList[4] = versionString;
  }

  Uint8List get payload {
    if (!(vendorName != null && modelName != null)) {
      throw "decoding requires the manufacturer and model name TLVs";
    }
    Uint8List payload = new Uint8List(0);

    // known data
    for (int type = 0; type < 5; type++) {
      if (dataList[type] != null) {
        payload.add(type);
        Uint8List valueBytes = utf8.encode(dataList[type]);
        payload.add(valueBytes.length);
        payload.addAll(valueBytes);
      }
    }

    // undefined data
    for (int i = 0; i < undefinedData.length; i++) {
      payload.add(undefinedData[i].type);
      Uint8List valueBytes = undefinedData[i].value;
      payload.add(valueBytes.length);
      payload.addAll(valueBytes);
    }

    return payload;
  }

  set payload(Uint8List payload) {
    ByteStream stream = new ByteStream(payload);

    while (!stream.isEnd()) {
      int type = stream.readByte();
      int length = stream.readByte();
      Uint8List value = stream.readBytes(length);
      if (type >= 0 && type < 5) {
        dataList[type] = utf8.decode(value);
      } else {
        undefinedData.add(DataElement(type, value));
      }
    }
    if (!(vendorName != null && modelName != null)) {
      throw "decoding requires the manufacturer and model name TLVs";
    }
  }
}
