import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/records/well_known/well_known.dart';
import 'package:ndef/utilities.dart';

enum TextEncoding { UTF8, UTF16 }

class TextRecord extends WellKnownRecord {
  static const String classType = "T";

  @override
  String get decodedType {
    return TextRecord.classType;
  }

  static const int classMinPayloadLength = 1;

  @override
  int get minPayloadLength {
    return classMinPayloadLength;
  }

  @override
  String toString() {
    var str = "TextRecord: ";
    str += basicInfoString;
    str += "encoding=$encodingString ";
    str += "language=$language ";
    str += "text=$text";
    return str;
  }

  late TextEncoding encoding;
  String? _language, text;

  TextRecord({this.encoding = TextEncoding.UTF8, String? language, this.text}) {
    if (language != null) {
      this.language = language;
    }
  }

  String? get language {
    return _language;
  }

  set language(String? language) {
    if (language != null && (language.length >= 64 || language.isEmpty)) {
      throw RangeError.range(language.length, 1, 64);
    }
    _language = language;
  }

  String get encodingString {
    if (encoding == TextEncoding.UTF8) {
      return "UTF-8";
    } else {
      // encoding == TextEncoding.UTF16
      return "UTF-16";
    }
  }

  @override
  Uint8List get payload {
    List<int> languagePayload = utf8.encode(language!);
    late List<int> textPayload;
    late int encodingFlag;
    if (encoding == TextEncoding.UTF8) {
      textPayload = utf8.encode(text!);
      encodingFlag = 0;
    } else if (encoding == TextEncoding.UTF16) {
      // use UTF-16 LE only in encoding
      List<int> encodedChar = [0xFEFF];
      encodedChar.addAll(text!.codeUnits);
      textPayload = Uint16List.fromList(encodedChar).buffer.asUint8List();
      encodingFlag = 1;
    }
    int flag = (encodingFlag << 7) | languagePayload.length;
    return Uint8List.fromList([flag] + languagePayload + textPayload);
  }

  @override
  set payload(Uint8List? payload) {
    var stream = ByteStream(payload!);

    int flag = stream.readByte();
    int languagePayloadLength = flag & 0x3F;

    assert(languagePayloadLength != 0, "language code length can not be zero");

    if (flag >> 7 == 1) {
      encoding = TextEncoding.UTF16;
    } else {
      encoding = TextEncoding.UTF8;
    }

    var languagePayload = stream.readBytes(languagePayloadLength);
    var textPayload = stream.readAll();
    language = utf8.decode(languagePayload);

    if (encoding == TextEncoding.UTF8) {
      text = utf8.decode(textPayload);
    } else if (encoding == TextEncoding.UTF16) {
      // decode UTF-16 manually
      var bytes = textPayload;
      Endianness end;
      if (bytes[0] == 0xFF) {
        end = Endianness.Little;
      } else if (bytes[1] == 0xFE) {
        end = Endianness.Big;
      } else {
        throw ArgumentError("Unknown BOM in UTF-16 encoded string.");
      }
      StringBuffer buffer = StringBuffer();
      for (int i = 2; i < bytes.length;) {
        int firstWord = end == Endianness.Little
            ? (bytes[i + 1] << 8) + bytes[i]
            : (bytes[i] << 8) + bytes[i + 1];
        if (0xD800 <= firstWord && firstWord <= 0xDBFF) {
          int secondWord = end == Endianness.Little
              ? (bytes[i + 3] << 8) + bytes[i + 2]
              : (bytes[i + 2] << 8) + bytes[i + 3];
          int charCode =
              ((firstWord - 0xD800) << 10) + (secondWord - 0xDC00) + 0x10000;
          buffer.writeCharCode(charCode);
          i += 4;
        } else {
          buffer.writeCharCode(firstWord);
          i += 2;
        }
      }
      text = buffer.toString();
    }
  }
}
