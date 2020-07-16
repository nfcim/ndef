import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';

import 'record.dart';
import 'text.dart';
import 'uri.dart';
import 'mime.dart';
import 'byteStream.dart';

class ActionRecord extends Record {
  static const String recordType = "urn:nfc:wkt:act";

  static List<String> actionMap = ['exec', 'save', 'edit'];

  String action;

  ActionRecord(this.action);

  static ActionRecord decodePayload(Uint8List payload) {
    int actionIndex = payload[0];
    assert(actionIndex < actionMap.length && actionIndex >= 0,
        'Action code must be in [0,3)');

    String action = actionMap[actionIndex];
    return ActionRecord(action);
  }
}

class SizeRecord extends Record {
  static const String recordType = "urn:nfc:wkt:s";

  int size;

  SizeRecord(this.size);

  get PAYLOAD {
    return ByteStream.int2List(size, 4);
  }

  static SizeRecord decodePayload(Uint8List payload) {
    ByteStream stream = new ByteStream(payload);
    return SizeRecord(stream.readInt(4));
  }
}

class TypeRecord extends Record {
  static const String recordType = "urn:nfc:wkt:t";

  String type;

  TypeRecord(this.type);

  get PAYLOAD {
    return utf8.encode(type);
  }

  static TypeRecord decodePayload(Uint8List payload) {
    return TypeRecord(utf8.decode(payload));
  }
}

class SmartposterRecord extends Record {
  static const String recordType = "urn:nfc:wkt:Sp";

  List<dynamic> titleRecords,
      uriRecords,
      actionRecords,
      iconRecords,
      sizeRecords,
      typeRecords;

  //TODO:encode

  static SmartposterRecord decodePayload(Uint8List payload) {
    SmartposterRecord spRecord;
    decodeNdefMessage(payload).forEach((e) {
      if (e is TextRecord) {
        spRecord.titleRecords.add(e);
      } else if (e is URIRecord) {
        spRecord.uriRecords.add(e);
      } else if (e is MIMERecord) {
        spRecord.iconRecords.add(e);
      }
    });
    return spRecord;
  }
}
