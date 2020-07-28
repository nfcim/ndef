import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';
import 'package:utf/utf.dart' as utf;

import '../record.dart';

enum TextEncoding { UTF8, UTF16 }

class TextRecord extends Record {
  static const TypeNameFormat classTnf = TypeNameFormat.nfcWellKnown;

  TypeNameFormat get tnf {
    return classTnf;
  }

  static const String classType = "T";

  @override
  String get decodedType {
    return TextRecord.classType;
  }

  static const int classMinPayloadLength=1;

  int get minPayloadLength{
    return classMinPayloadLength;
  }

  @override
  String toString() {
    var str = "TextRecord: ";
    str+=basicInfoString;
    str+="encoding=$encodingString ";
    str+="language=$language ";
    str+="text=$text";
    return str;
  }

  TextEncoding encoding;
  String _language, text;

  TextRecord(
      {TextEncoding encoding = TextEncoding.UTF8,
      String language,
      String text}) {
    this.encoding = encoding;
    if(language!=null){
      this.language = language;
    }
    this.text = text;
  }

  get language {
    return _language;
  }

  set language(String language) {
    assert(0 < language.length && language.length < 64,
        "the length of language code must be in [1,64), got ${language.length}");
    this._language = language;
  }

  get encodingString {
    if(encoding==TextEncoding.UTF8){
      return "UTF-8";
    }else if(encoding==TextEncoding.UTF16){
      return "UTF-16";
    }
  }

  Uint8List get payload {
    Uint8List languagePayload = utf8.encode(language);
    Uint8List textPayload;
    int encodingFlag;
    if (encoding == TextEncoding.UTF8) {
      textPayload = utf8.encode(text);
      encodingFlag = 0;
    } else if (encoding == TextEncoding.UTF16) {
      textPayload = utf.encodeUtf16(text);
      encodingFlag = 1;
    }
    int flag = (encodingFlag << 7) | languagePayload.length;
    return new Uint8List.fromList([flag] + languagePayload + textPayload);
  }

  set payload(Uint8List payload) {
    var stream = new ByteStream(payload);

    int flag = stream.readByte();

    assert(flag & 0x3F != 0, "language code length can not be zero");
    assert(flag & 0x3F < payload.length,
        "language code length exceeds payload length");

    if (flag >> 7 == 1) {
      encoding = TextEncoding.UTF16;
    } else {
      encoding = TextEncoding.UTF8;
    }

    var languagePayload = stream.readBytes(flag & 0x3F);
    var textPayload = stream.readAll();
    language = utf8.decode(languagePayload);

    if (encoding == TextEncoding.UTF8) {
      text = utf8.decode(textPayload);
    } else if (encoding == TextEncoding.UTF16) {
      text = utf.decodeUtf16(textPayload);
    }
  }
}
