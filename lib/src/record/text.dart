import 'dart:convert';
import 'dart:typed_data';

import 'package:utf/utf.dart' as utf;

import '../record.dart';

enum TextEncoding { UTF8, UTF16 }

class TextRecord extends Record {
  static const String recordType = "urn:nfc:wkt:T";

  static const String decodedType = "T";

  @override
  String get _decodedType {
    return TextRecord.decodedType;
  }

  TextEncoding encoding;
  String _language, text;

  TextRecord(
      {TextEncoding encoding = TextEncoding.UTF8,
      String language,
      String text}) {
    this.encoding = encoding;
    this.language = language;
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

  Uint8List get payload {
    Uint8List payload;
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
    payload = [flag] + languagePayload + textPayload;

    return payload;
  }

  set payload(Uint8List payload) {
    int flag = payload[0];

    assert(flag & 0x3F != 0, "language code length can not be zero");
    assert(flag & 0x3F < payload.length,
        "language code length exceeds payload length");

    if (flag >> 7 == 1) {
      encoding = TextEncoding.UTF16;
    } else {
      encoding = TextEncoding.UTF8;
    }

    var languagePayload = payload.sublist(1, flag & 0x3F);
    var textPayload = payload.sublist(1 + flag & 0x3F);
    language = utf8.decode(languagePayload);

    if (encoding == TextEncoding.UTF8) {
      text = utf8.decode(textPayload);
    } else if (encoding == TextEncoding.UTF16) {
      text = utf.decodeUtf16(textPayload);
    }
  }
}
