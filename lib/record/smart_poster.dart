import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';
import 'package:ndef/utilities.dart';

enum Action { exec, save, edit }

class ActionRecord extends WellKnownRecord {
  static const String classType = "act";

  @override
  String get decodedType {
    return ActionRecord.classType;
  }

  static const int classMinPayloadLength = 1;
  static const int classMaxPayloadLength = 1;

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
    var str = "ActionRecord: ";
    str += basicInfoString;
    str += "action=$action";
    return str;
  }

  Action? action;

  ActionRecord({this.action});

  @override
  Uint8List get payload {
    var payload = <int>[];
    payload.add(Action.values.indexOf(action!));
    return Uint8List.fromList(payload);
  }

  @override
  set payload(Uint8List? payload) {
    int actionIndex = payload![0];
    if (actionIndex >= Action.values.length && actionIndex < 0) {
      throw RangeError.range(actionIndex, 0, Action.values.length);
    }
    action = Action.values[actionIndex];
  }
}

class SizeRecord extends WellKnownRecord {
  static const String classType = "s";

  @override
  String get decodedType {
    return SizeRecord.classType;
  }

  static const int classMinPayloadLength = 4;
  static const int classMaxPayloadLength = 4;

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
    var str = "SizeRecord: ";
    str += basicInfoString;
    str += "size=$_size";
    return str;
  }

  late int _size;

  int get size {
    return _size;
  }

  set size(int size) {
    if (size < 0 || size >= 1 << 32) {
      throw RangeError.range(size, 0, 1 << 32);
    }
    _size = size;
  }

  SizeRecord({int? size}) {
    if (size != null) {
      this.size = size;
    }
  }

  @override
  Uint8List? get payload {
    return _size.toBytes(4);
  }

  @override
  set payload(Uint8List? payload) {
    _size = payload!.sublist(0, 4).toInt();
  }
}

class TypeRecord extends WellKnownRecord {
  static const String classType = "t";

  @override
  String get decodedType {
    return TypeRecord.classType;
  }

  @override
  String toString() {
    var str = "TypeRecord: ";
    str += basicInfoString;
    str += "type=$typeInfo";
    return str;
  }

  String? typeInfo;

  TypeRecord({this.typeInfo});

  @override
  Uint8List get payload {
    return utf8.encode(typeInfo!) as Uint8List;
  }

  @override
  set payload(Uint8List? payload) {
    typeInfo = utf8.decode(payload!);
  }
}

class SmartPosterRecord extends WellKnownRecord {
  static const String classType = "Sp";

  @override
  String get decodedType {
    return SmartPosterRecord.classType;
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
    str += "typeRecords=$typeRecords";
    return str;
  }

  late List<TextRecord> _titleRecords;
  late List<UriRecord> _uriRecords;
  late List<ActionRecord> _actionRecords;
  late List<MimeRecord> _iconRecords;
  late List<SizeRecord> _sizeRecords;
  late List<TypeRecord> _typeRecords;

  late List<String?> _titleLanguages;

  void _init() {
    _titleRecords = <TextRecord>[];
    _titleLanguages = <String>[];
    _uriRecords = <UriRecord>[];
    _actionRecords = <ActionRecord>[];
    _iconRecords = <MimeRecord>[];
    _sizeRecords = <SizeRecord>[];
    _typeRecords = <TypeRecord>[];
  }

  SmartPosterRecord({
    var title,
    var uri,
    Action? action,
    Map<String, Uint8List>? icon,
    int? size,
    String? typeInfo,
  }) {
    _init();
    if (title != null) {
      this.title = title;
    }
    if (uri != null) {
      this.uri = uri;
    }
    if (action != null) {
      this.action = action;
    }
    if (icon != null) {
      this.icon = icon;
    }
    if (size != null) {
      this.size = size;
    }
    if (typeInfo != null) {
      this.typeInfo = typeInfo;
    }
  }

  SmartPosterRecord.fromList({
    List<TextRecord>? titleRecords,
    List<UriRecord>? uriRecords,
    List<ActionRecord>? actionRecords,
    List<MimeRecord>? iconRecords,
    List<SizeRecord>? sizeRecords,
    List<TypeRecord>? typeRecords,
  }) {
    _init();
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
    if (actionRecords != null) {
      for (var r in actionRecords) {
        addActionRecord(r);
      }
    }
    if (iconRecords != null) {
      for (var r in iconRecords) {
        addIconRecord(r);
      }
    }
    if (sizeRecords != null) {
      for (var r in sizeRecords) {
        addSizeRecord(r);
      }
    }
    if (typeRecords != null) {
      for (var r in typeRecords) {
        addTypeRecord(r);
      }
    }
  }

  static NDEFRecord typeFactory(TypeNameFormat tnf, String classType) {
    NDEFRecord record;
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
        record = WellKnownRecord();
      }
    } else if (tnf == TypeNameFormat.media) {
      record = MimeRecord();
    } else if (tnf == TypeNameFormat.absoluteURI) {
      record = AbsoluteUriRecord();
    } else {
      record = NDEFRecord();
    }
    return record;
  }

  List<NDEFRecord> get allRecords {
    return uriRecords +
        titleRecords +
        actionRecords +
        iconRecords +
        sizeRecords +
        typeRecords;
  }

  List<NDEFRecord> get uriRecords {
    return List<NDEFRecord>.from(_uriRecords, growable: false);
  }

  UriRecord? get uriRecord {
    if (uriRecords.length == 1) {
      return _uriRecords[0];
    } else {
      return null;
    }
  }

  Uri? get uri {
    if (_uriRecords.length == 1) {
      return _uriRecords[0].uri;
    } else {
      return null;
    }
  }

  void addUriRecord(UriRecord record) {
    if (_uriRecords.length == 1) {
      throw ArgumentError.value(_uriRecords.length,
          "Number of URI Record in Smart Poster Record must be 1");
    }
    _uriRecords.add(record);
  }

  set uri(var uri) {
    if (uri is String) {
      if (_uriRecords.length == 1) {
        _uriRecords[0] = UriRecord.fromString(uri);
      } else {
        _uriRecords.add(UriRecord.fromString(uri));
      }
    } else if (uri is Uri) {
      if (_uriRecords.length == 1) {
        _uriRecords[0] = UriRecord.fromString(uri.toString());
      } else {
        _uriRecords.add(UriRecord.fromString(uri.toString()));
      }
    }
  }

  List<NDEFRecord> get titleRecords {
    return List<NDEFRecord>.from(_titleRecords, growable: false);
  }

  /// get the English title; if not existing, get the first title
  String? get title {
    if (_titleLanguages.contains('en')) {
      return titles['en'];
    } else if (_titleLanguages.isNotEmpty) {
      return _titleRecords[0].text;
    } else {
      return null;
    }
  }

  Map<String?, String?> get titles {
    var titles = <String?, String?>{};
    for (var r in _titleRecords) {
      titles[r.language] = r.text;
    }
    return titles;
  }

  set title(var title) {
    var language = 'en';
    String text;
    if (title is String) {
      text = title;
    } else if (title is Map<String, String>) {
      var t = title.entries.toList()[0];
      language = t.key;
      text = t.value;
    } else {
      throw ArgumentError(
          "Title expects String or Map<String,String>, got ${title.runtimeType}");
    }
    if (_titleLanguages.contains(language)) {
      _titleRecords[_titleLanguages.indexOf(language)] =
          TextRecord(text: text);
    } else {
      addTitle(text, language: language);
    }
  }

  void addTitle(String text,
      {String language = 'en', TextEncoding encoding = TextEncoding.UTF8}) {
    _titleRecords.add(
        TextRecord(language: language, text: text, encoding: encoding));
    if (_titleLanguages.contains(language)) {
      throw ArgumentError(
          "Language of titles can not be repeated, got $language");
    }
    _titleLanguages.add(language);
  }

  void addTitleRecord(TextRecord record) {
    _titleRecords.add(record);
    if (_titleLanguages.contains(record.language)) {
      throw ArgumentError(
          "Language of titles can not be repeated, got ${record.language}");
    }
    _titleLanguages.add(record.language);
  }

  List<NDEFRecord> get actionRecords {
    return List<NDEFRecord>.from(_actionRecords, growable: false);
  }

  /// get the first action if it exists
  Action? get action {
    if (_actionRecords.isNotEmpty) {
      return _actionRecords[0].action;
    } else {
      return null;
    }
  }

  set action(Action? action) {
    if (_actionRecords.isNotEmpty) {
      _actionRecords[0] = ActionRecord(action: action);
    } else {
      addActionRecord(ActionRecord(action: action));
    }
  }

  void addActionRecord(ActionRecord record) {
    _actionRecords.add(record);
  }

  List<NDEFRecord> get sizeRecords {
    return List<NDEFRecord>.from(_sizeRecords, growable: false);
  }

  int? get size {
    if (_sizeRecords.isNotEmpty) {
      return _sizeRecords[0].size;
    } else {
      return null;
    }
  }

  set size(int? size) {
    if (_sizeRecords.isNotEmpty) {
      _sizeRecords[0] = SizeRecord(size: size);
    } else {
      addSizeRecord(SizeRecord(size: size));
    }
  }

  void addSizeRecord(SizeRecord record) {
    _sizeRecords.add(record);
  }

  List<NDEFRecord> get typeRecords {
    return List<NDEFRecord>.from(_typeRecords, growable: false);
  }

  String? get typeInfo {
    if (_typeRecords.isNotEmpty) {
      return _typeRecords[0].typeInfo;
    } else {
      return null;
    }
  }

  set typeInfo(String? typeInfo) {
    if (_typeRecords.isNotEmpty) {
      _typeRecords[0] = TypeRecord(typeInfo: typeInfo);
    } else {
      addTypeRecord(TypeRecord(typeInfo: typeInfo));
    }
  }

  void addTypeRecord(TypeRecord record) {
    _typeRecords.add(record);
  }

  List<NDEFRecord> get iconRecords {
    return List<NDEFRecord>.from(_iconRecords, growable: false);
  }

  MimeRecord? get iconRecord {
    if (_iconRecords.isNotEmpty) {
      return _iconRecords[0];
    } else {
      return null;
    }
  }

  Map<String?, Uint8List?>? get icon {
    if (iconRecord != null) {
      return {iconRecord!.decodedType: iconRecord!.payload};
    } else {
      return null;
    }
  }

  static void _checkValidIconType(String decodedType) {
    if (!(decodedType.startsWith('image/') ||
        decodedType.startsWith('video'))) {
      throw ArgumentError(
          "Type of Icon Records must be image or video, not $decodedType");
    }
  }

  set icon(Map<String?, Uint8List?>? icon) {
    String? decodedType = icon!.keys.toList()[0];
    _checkValidIconType(decodedType!);
    iconRecord = MimeRecord(
        decodedType: decodedType, payload: icon.values.toList()[0]);
  }

  void addIcon(Map<String, Uint8List> icon) {
    String decodedType = icon.keys.toList()[0];
    _checkValidIconType(decodedType);
    _iconRecords.add(MimeRecord(
        decodedType: decodedType, payload: icon.values.toList()[0]));
  }

  set iconRecord(MimeRecord? record) {
    _checkValidIconType(record!.decodedType!);
    if (_iconRecords.isNotEmpty) {
      _iconRecords[0] = record;
    } else {
      _iconRecords.add(record);
    }
  }

  void addIconRecord(MimeRecord record) {
    _checkValidIconType(record.decodedType!);
    _iconRecords.add(record);
  }

  static bool _isEqualRecords(List<NDEFRecord> own, List<NDEFRecord> other) {
    for (var i = 0; i < own.length; i++) {
      if (!own[i].isEqual(other[i])) {
        return false;
      }
    }
    return true;
  }

  @override
  bool isEqual(NDEFRecord other) {
    var o = other as SmartPosterRecord;
    return (tnf == other.tnf) &&
        ByteUtils.bytesEqual(type, other.type) &&
        (id == other.id) &&
        (titleRecords.length == o.titleRecords.length) &&
        (uriRecords.length == o.uriRecords.length) &&
        (actionRecords.length == o.actionRecords.length) &&
        (iconRecords.length == o.iconRecords.length) &&
        (sizeRecords.length == o.sizeRecords.length) &&
        (typeRecords.length == o.typeRecords.length) &&
        _isEqualRecords(titleRecords, o.titleRecords) &&
        _isEqualRecords(uriRecords, o.uriRecords) &&
        _isEqualRecords(actionRecords, o.actionRecords) &&
        _isEqualRecords(iconRecords, o.iconRecords) &&
        _isEqualRecords(sizeRecords, o.sizeRecords) &&
        _isEqualRecords(typeRecords, o.typeRecords);
  }

  @override
  Uint8List get payload {
    if (_uriRecords.length != 1) {
      throw ArgumentError.value(_uriRecords.length,
          "Number of URI Record in Smart Poster Record must be 1");
    }
    return encodeNdefMessage(allRecords);
  }

  @override
  set payload(Uint8List? payload) {
    decodeRawNdefMessage(payload!, typeFactory: SmartPosterRecord.typeFactory)
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
      throw ArgumentError.value(uriRecords.length,
          "Number of URI Record in Smart Poster Record must be 1");
    }
  }
}
