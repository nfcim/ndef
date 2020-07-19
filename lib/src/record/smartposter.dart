import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';
import 'package:utf/utf.dart';

import '../record.dart';
import '../byteStream.dart';
import 'text.dart';
import 'uri.dart';
import 'mime.dart';

enum Action{
  exec,
  save,
  edit
}

class ActionRecord extends Record {
  static const String recordType = "urn:nfc:wkt:act";

  static const String decodedType = "act";

  @override
  String get _decodedType {
    return TextRecord.decodedType;
  }

  Action action;

  ActionRecord({this.action});

  get payload {
    Uint8List payload=new Uint8List(0);
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
  static const String recordType = "urn:nfc:wkt:s";

  static const String decodedType = "s";

  @override
  String get _decodedType {
    return TextRecord.decodedType;
  }

  int size;

  SizeRecord({this.size});

  get payload {
    return ByteStream.int2List(size, 4);
  }

  set payload(Uint8List payload) {
    ByteStream stream = new ByteStream(payload);
    size=stream.readInt(4);
  }
}

class TypeRecord extends Record {
  static const String recordType = "urn:nfc:wkt:t";

  static const String decodedType = "t";

  @override
  String get _decodedType {
    return TextRecord.decodedType;
  }

  String typeInfo;

  TypeRecord({this.typeInfo});

  get payload {
    return utf8.encode(typeInfo);
  }

  set payload(Uint8List payload) {
    typeInfo=utf8.decode(payload);
  }
}

class SmartposterRecord extends Record {
  static const String recordType = "urn:nfc:wkt:Sp";

  static const String decodedType = "Sp";

  @override
  String get _decodedType {
    return TextRecord.decodedType;
  }

  List<dynamic> titleRecords,
      uriRecords,
      actionRecords,
      iconRecords,
      sizeRecords,
      typeRecords;

  static Record doDecode(TypeNameFormat tnf, Uint8List type, Uint8List payload,
      {Uint8List id}) {

    Record record;
    var decodedType = utf8.decode(type);

    if (tnf == TypeNameFormat.nfcWellKnown) {
      // urn:nfc:wkt
      if (decodedType == URIRecord.decodedType) {
        // URI
        record = URIRecord();
      } else if (decodedType == TextRecord.decodedType) {
        // Text
        record = TextRecord();
      } else if (decodeType == SizeRecord.decodedType) {
        // Size (local)
        record = SizeRecord();
      } else if (decodedType == TypeRecord.decodedType) {
        // Type (local)
        record = TypeRecord();
      } else if (decodedType == ActionRecord.decodedType) {
        // Action (local)
        record = ActionRecord();
      }
    } else if (tnf == TypeNameFormat.media) {
      record = MIMERecord();
    } else if (tnf == TypeNameFormat.absoluteURI) {
      record = AbsoluteUriRecord(); // FIXME: seems wrong
    } else {
      // unknown
      record = new Record();
    }

    record.id = id;
    record.type = type;
    // use setter for implicit decoding
    record.payload = payload;
    return record;
  }    

  get payload {
    var allRecords=titleRecords+uriRecords+actionRecords+iconRecords+sizeRecords+typeRecords;
    return encodeNdefMessage(allRecords);
  }

  set payload(Uint8List payload) {
    decodeRawNdefMessage(payload,doDecodeStrategy:SmartposterRecord.doDecode).forEach((e) {
      if (e is TextRecord) {
        titleRecords.add(e);
      } else if (e is URIRecord) {
        uriRecords.add(e);
      } else if (e is MIMERecord) {
        iconRecords.add(e);
      } else if (e is ActionRecord) {
        actionRecords.add(e);
      } else if (e is SizeRecord) {
        sizeRecords.add(e);
      } else if (e is TypeRecord) {
        typeRecords.add(e);
      }
    });
    assert(uriRecords.length==1);
  }
}
