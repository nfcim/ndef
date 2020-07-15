import 'dart:convert';

import 'message.dart';
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

  static dynamic decode_payload(List<int> PAYLOAD) {
    int actionIndex = PAYLOAD[0];
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

  static dynamic decode_payload(List<int> PAYLOAD) {
    ByteStream stream = new ByteStream(PAYLOAD);
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

  static dynamic decode_payload(List<int> PAYLOAD) {
    return TypeRecord(utf8.decode(PAYLOAD));
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

  static dynamic decode_payload(List<int> PAYLOAD) {
    Message message = new Message(PAYLOAD);
    SmartposterRecord spRecord;
    for (int i = 0; i < message.record_list.length; i++) {
      if (message.record_list[i] is TextRecord) {
        spRecord.titleRecords.add(message.record_list[i]);
      } else if (message.record_list[i] is URIRecord) {
        spRecord.uriRecords.add(message.record_list[i]);
      } else if (message.record_list[i] is MIMERecord) {
        spRecord.iconRecords.add(message.record_list[i]);
      }
    }
  }
}
