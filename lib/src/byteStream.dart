import 'dart:typed_data';

/// byte stream utility class for decoding
class ByteStream {
  Uint8List _data;
  int _current = 0;

  ByteStream(Uint8List data) {
    _data = data;
  }

  bool isEnd() {
    return _current == _data.length;
  }

  int readByte() {
    return _data[_current++];
  }

  Uint8List readBytes(int number) {
    Uint8List d = _data.sublist(_current, _current + number);
    _current += number;
    return d;
  }

  int readInt(int number) {
    Uint8List d = readBytes(number);
    int value = 0;
    for (var n = 0; n < d.length; n++) {
      value <<= 16;
      value += d[d.length - n - 1];
    }
    return value;
  }

  int readString(int number) {
    Uint8List d = readBytes(number);
    String str = "";
    for (var n = 0; n < d.length; n++) {
      // TODO: seems not finished?
    }
  }

  static String int2hex(int value) {
    assert(value >= 0 && value < 256,
        "the number to decode into Hex String must be in the range of [0,256)");
    int num1 = value ~/ 16;
    int num0 = value % 16;
    String map = 'ABCDEF';
    String str1 = num1 >= 10 ? map[num1 - 10] : num1.toString();
    String str0 = num0 >= 10 ? map[num0 - 10] : num0.toString();
    return str1 + str0;
  }

  static Uint8List int2List(int value, int length) {
    Uint8List list = new Uint8List(0);
    for (int i = 0; i < length; i++) {
      list.add(value % 256);
      value ~/= 256;
    }
    list = list.reversed;
    return list;
  }

  static Uint8List decodeHexString(String hex) {
    hex = hex.splitMapJoin(" ", onMatch: (Match match) {
      return "";
    });
    var result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
