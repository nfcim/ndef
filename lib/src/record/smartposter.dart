import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';
import 'package:utf/utf.dart';

import '../record.dart';
import '../byteStream.dart';
import 'text.dart';
import 'uri.dart';
import 'mime.dart';

enum Action { exec, save, edit }

class ActionRecord extends Record {
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "act";

  @override
  String get decodedType {
    return ActionRecord.classType;
  }

  static const int classMinPayloadLength = 1;
  static const int classMaxPayloadLength = 1;

  int get minPayloadLength {
    return classMinPayloadLength;
  }

  int get maxPayloadLength {
    return classMaxPayloadLength;
  }

  @override
  String toString() {
    var str = "ActionRecord: ";
    str += basicInfoString;
    str += "action=$action ";
    return str;
  }

  Action action;

  ActionRecord({this.action});

  Uint8List get payload {
    Uint8List payload = new Uint8List(0);
    payload.add(Action.values.indexOf(action));
    return payload;
  }

  set payload(Uint8List payload) {
    int actionIndex = payload[0];
    assert(actionIndex < Action.values.length && actionIndex >= 0,
        'Action code must be in [0,${Action.values.length})');

    action = Action.values[actionIndex];
  }
}

class SizeRecord extends Record {
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "s";

  @override
  String get decodedType {
    return SizeRecord.classType;
  }

  static const int classMinPayloadLength = 4;
  static const int classMaxPayloadLength = 4;

  int get minPayloadLength {
    return classMinPayloadLength;
  }

  int get maxPayloadLength {
    return classMaxPayloadLength;
  }

  @override
  String toString() {
    var str = "SizeRecord: ";
    str += basicInfoString;
    str += "size=$size ";
    return str;
  }

  int size;

  SizeRecord({this.size});

  Uint8List get payload {
    return ByteStream.int2list(size, 4);
  }

  set payload(Uint8List payload) {
    size = ByteStream.list2int(payload.sublist(0, 4));
  }
}

class TypeRecord extends Record {
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "t";

  @override
  String get decodedType {
    return TypeRecord.classType;
  }

  @override
  String toString() {
    var str = "TypeRecord: ";
    str += basicInfoString;
    str += "type=$typeInfo ";
    return str;
  }

  String typeInfo;

  TypeRecord({this.typeInfo});

  Uint8List get payload {
    return utf8.encode(typeInfo);
  }

  set payload(Uint8List payload) {
    typeInfo = utf8.decode(payload);
  }
}

class SmartposterRecord extends Record {
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "Sp";

  @override
  String get decodedType {
    return SmartposterRecord.classType;
  }

  @override
  String toString() {
    var str = "SmartRecord: ";
    str += basicInfoString;
    str += "titleRecords=$titleRecords ";
    str += "uriRecords=$uriRecords ";
    str += "actionRecords=$actionRecords ";
    str += "iconRecords=$iconRecords ";
    str += "sizeRecords=$sizeRecords ";
    str += "typeRecords=$typeRecords ";
    return str;
  }

  List<dynamic> titleRecords,
      uriRecords,
      actionRecords,
      iconRecords,
      sizeRecords,
      typeRecords;

  static Record typeFactory(TypeNameFormat tnf, String classType) {
    Record record;
    if (tnf == TypeNameFormat.nfcWellKnown) {
      // urn:nfc:wkt
      if (classType == UriRecord.classType) {
        // URI
        record = UriRecord();
      } else if (classType == TextRecord.classType) {
        // Text
        record = TextRecord();
      } else if (classType == SizeRecord.classType) {
        // Size (local)
        record = SizeRecord();
      } else if (classType == TypeRecord.classType) {
        // Type (local)
        record = TypeRecord();
      } else if (classType == ActionRecord.classType) {
        // Action (local)
        record = ActionRecord();
      } else {
        record = Record();
      }
    } else if (tnf == TypeNameFormat.media) {
      record = MimeRecord();
    } else if (tnf == TypeNameFormat.absoluteURI) {
      record = AbsoluteUriRecord(); // FIXME: seems wrong
    } else {
      // unknown
      record = new Record();
    }
    return record;
  }

  Uint8List get payload {
    var allRecords = titleRecords +
        uriRecords +
        actionRecords +
        iconRecords +
        sizeRecords +
        typeRecords;
    return encodeNdefMessage(allRecords);
  }

  set payload(Uint8List payload) {
    decodeRawNdefMessage(payload, typeFactory: SmartposterRecord.typeFactory)
        .forEach((e) {
      if (e is TextRecord) {
        titleRecords.add(e);
      } else if (e is UriRecord) {
        uriRecords.add(e);
      } else if (e is MimeRecord) {
        iconRecords.add(e);
      } else if (e is ActionRecord) {
        actionRecords.add(e);
      } else if (e is SizeRecord) {
        sizeRecords.add(e);
      } else if (e is TypeRecord) {
        typeRecords.add(e);
      }
    });
    assert(uriRecords.length == 1);
  }
}
