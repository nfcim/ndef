import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';

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
    var payload = new List<int>();
    payload.add(Action.values.indexOf(action));
    return new Uint8List.fromList(payload);
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

  List<TextRecord> _titleRecords;
  List<UriRecord> _uriRecords;
  List<ActionRecord> _actionRecords;
  List<MimeRecord> _iconRecords;
  List<SizeRecord> _sizeRecords;
  List<TypeRecord> _typeRecords;

  List<String> _titleLanguages;

  SmartposterRecord({
    var title,
    var uri,
    Action action,
    MimeRecord iconRecord,
    int size,
    String typeInfo,
  }) {
    _titleRecords = new List<TextRecord>();
    _uriRecords = new List<UriRecord>();
    _actionRecords = new List<ActionRecord>();
    _iconRecords = new List<MimeRecord>();
    _sizeRecords = new List<SizeRecord>();
    _typeRecords = new List<TypeRecord>();
    if (title != null) {
      this.title=title;
    }
    if(uri!=null){
      this.uri=uri;
    }
    if(action!=null){
      this.action=action;
    }
    if(iconRecord!=null){
      this.iconRecord=iconRecord;
    }
    if(size!=null){
      this.size=size;
    }
    if(type!=null){
      this.typeInfo=typeInfo;
    }
  }

  SmartposterRecord.fromList({
    List<TextRecord> titleRecords,
    List<UriRecord> uriRecords,
    List<ActionRecord> actionRecords,
    List<MimeRecord> iconRecords,
    List<SizeRecord> sizeRecords,
    List<TypeRecord> typeRecords,
  }) {
    _titleRecords = new List<TextRecord>();
    _uriRecords = new List<UriRecord>();
    _actionRecords = new List<ActionRecord>();
    _iconRecords = new List<MimeRecord>();
    _sizeRecords = new List<SizeRecord>();
    _typeRecords = new List<TypeRecord>();
    if (titleRecords != null) {
      for (var r in titleRecords) {
        addTitleRecord(r);
      }
    }
    if (uriRecords != null) {
      for (var r in uriRecords) {
        addUriRecord(r);
      }
    }
  }

  static Record typeFactory(TypeNameFormat tnf, String classType) {
    Record record;
    if (tnf == TypeNameFormat.nfcWellKnown) {
      if (classType == UriRecord.classType) {
        record = UriRecord();
      } else if (classType == TextRecord.classType) {
        record = TextRecord();
      } else if (classType == SizeRecord.classType) {
        record = SizeRecord();
      } else if (classType == TypeRecord.classType) {
        record = TypeRecord();
      } else if (classType == ActionRecord.classType) {
        record = ActionRecord();
      } else {
        record = Record();
      }
    } else if (tnf == TypeNameFormat.media) {
      record = MimeRecord();
    } else if (tnf == TypeNameFormat.absoluteURI) {
      record = AbsoluteUriRecord();
    } else {
      record = new Record();
    }
    return record;
  }

  get allRecords {
    return titleRecords +
        uriRecords +
        actionRecords +
        iconRecords +
        sizeRecords +
        typeRecords;
  }

  get uriRecords {
    return new List<Record>.from(_uriRecords, growable: false);
  }

  get uriRecord {
    if (uriRecords.length == 1) {
      return _uriRecords[0];
    } else {
      return null;
    }
  }

  get uri {
    if (_uriRecords.length == 1) {
      return _uriRecords[0].uri;
    } else {
      return null;
    }
  }

  void addUriRecord(UriRecord record) {
    if (_uriRecords.length == 1) {
      throw "Number of URI Record in Smart Poster Record must be 1";
    }
    _uriRecords.add(record);
  }

  set uri(var uri){
    if(uri is String){
      if(_uriRecords.length==1){
        _uriRecords[0]=new UriRecord.fromUriString(uri);
      }else{
        _uriRecords.add(new UriRecord.fromUriString(uri));
      }
    }else if(uri is Uri){
      if(_uriRecords.length==1){
        _uriRecords[0]=new UriRecord.fromUriString(uri.toString());
      }else{
        _uriRecords.add(new UriRecord.fromUriString(uri.toString()));
      }
    }
  }

  get titleRecords {
    return new List<Record>.from(_titleRecords, growable: false);
  }

  get title {
    if (_titleLanguages.contains('en')) {
      return titles['en'];
    } else {
      return _titleRecords[0].text;
    }
  }

  get titles {
    var titles = Map<String, String>();
    for (var r in _titleRecords) {
      titles[r.language] = r.text;
    }
  }

  set title(var title){
    var language = 'en';
    var text;
    if(title is String){
      text=title;
    }else if(title is Map<String,String>){
      var t = title.entries.toList()[0];
      language=t.key;
      text=t.value;
    }else{
      throw "Title must be String or Map<String,String>";
    }
    if(_titleLanguages.contains(language)){
      _titleRecords[_titleLanguages.indexOf(language)]=new TextRecord(text: text);
    }else{
      addTitle(text,language: language);
    }
  }

  void addTitle(String text,
      {String language = 'en', TextEncoding encoding = TextEncoding.UTF8}) {
    _titleRecords.add(
        new TextRecord(language: language, text: text, encoding: encoding));
    if (_titleLanguages.contains(language)) {
      throw "Language of titles can not be repeated, got $language";
    }
    _titleLanguages.add(language);
  }

  void addTitleRecord(TextRecord record) {
    _titleRecords.add(record);
    if (_titleLanguages.contains(record.language)) {
      throw "Language of titles can not be repeated, got ${record.language}";
    }
    _titleLanguages.add(record.language);
  }

  get actionRecords {
    return new List<Record>.from(_actionRecords, growable: false);
  }

  /// get the first action if it exists
  get action {
    if (_actionRecords.length >= 1) {
      return _actionRecords[0].action;
    } else {
      return null;
    }
  }

  set action(Action action) {
    if (_actionRecords.length >= 1) {
      _actionRecords[0] = new ActionRecord(action: action);
    } else {
      addActionRecord(new ActionRecord(action: action));
    }
  }

  void addActionRecord(ActionRecord record) {
    _actionRecords.add(record);
  }

  get sizeRecords {
    return new List<Record>.from(_sizeRecords, growable: false);
  }

  get size {
    if (_sizeRecords.length >= 1) {
      return _sizeRecords[0].size;
    } else {
      return null;
    }
  }

  set size(int size) {
    if (_sizeRecords.length >= 1) {
      _sizeRecords[0] = new SizeRecord(size: size);
    } else {
      addSizeRecord(new SizeRecord(size: size));
    }
  }

  void addSizeRecord(SizeRecord record) {
    _sizeRecords.add(size);
  }

  get typeRecords {
    return new List<Record>.from(_typeRecords, growable: false);
  }

  get typeInfo {
    if (_typeRecords.length >= 1) {
      return _typeRecords[0].typeInfo;
    } else {
      return null;
    }
  }

  set typeInfo(String typeInfo) {
    if (_typeRecords.length >= 1) {
      _typeRecords[0] = new TypeRecord(typeInfo: typeInfo);
    } else {
      addTypeRecord(new TypeRecord(typeInfo: typeInfo));
    }
  }

  void addTypeRecord(TypeRecord record) {
    _typeRecords.add(record);
  }

  get iconRecords {
    return new List<Record>.from(_iconRecords, growable: false);
  }

  get iconRecord {
    if (_actionRecords.length >= 1) {
      return _actionRecords[0];
    } else {
      return null;
    }
  }

  set iconRecord(MimeRecord record) {
    if (record.decodedType.startsWith('image/') ||
        record.decodedType.startsWith('video/')) {
      if (_iconRecords.length >= 1) {
        _iconRecords[0] = record;
      } else {
        _iconRecords.add(record);
      }
    } else {
      throw "Type of Icon Records must be image or video, not ${record.decodedType}";
    }
  }

  void addIconRecord(MimeRecord record) {
    if (record.decodedType.startsWith('image/') ||
        record.decodedType.startsWith('video/')) {
      _iconRecords.add(record);
    } else {
      throw "Type of Icon Records must be image or video, not ${record.decodedType}";
    }
  }

  Uint8List get payload {
    if (_uriRecords.length != 1) {
      throw "Number of URI Record in Smart Poster Record must be 1";
    }
    return encodeNdefMessage(allRecords);
  }

  set payload(Uint8List payload) {
    decodeRawNdefMessage(payload, typeFactory: SmartposterRecord.typeFactory)
        .forEach((e) {
      if (e is TextRecord) {
        addTitleRecord(e);
      } else if (e is UriRecord) {
        addUriRecord(e);
      } else if (e is MimeRecord) {
        addIconRecord(e);
      } else if (e is ActionRecord) {
        addActionRecord(e);
      } else if (e is SizeRecord) {
        addSizeRecord(e);
      } else if (e is TypeRecord) {
        addTypeRecord(e);
      }
    });
    if (uriRecords.length != 1) {
      throw "Number of URI Record in Smart Poster Record must be 1";
    }
  }
}
