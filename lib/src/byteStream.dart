import 'dart:typed_data';

/// byte stream utility class for decoding
class ByteStream {
  Uint8List _data;
  int _current = 0;

  get unreadLength {
    return _data.length - _current;
  }

  get length {
    return _data.length;
  }

  ByteStream(Uint8List data) {
    _data = data;
  }

  bool isEnd() {
    return _current == _data.length;
  }

  int readByte() {
    checkBytesAvailable(1);
    return _data[_current++];
  }

  Uint8List readBytes(int number) {
    checkBytesAvailable(number);
    Uint8List d = _data.sublist(_current, _current + number);
    _current += number;
    return d;
  }

  int readInt(int number) {
    assert(number <= 8);
    Uint8List d = readBytes(number);
    int value = 0;
    for (var n = 0; n < d.length; n++) {
      value <<= 16;
      value += d[d.length - n - 1];
    }
    return value;
  }

  Uint8List readAll() {
    return readBytes(unreadLength);
  }

  String readHexString(int number) {
    Uint8List list = readBytes(number);
    return list2hexString(list);
  }

  void checkBytesAvailable(int number) {
    assert(number <= unreadLength, "there is no enough data in stream");
  }

  void checkEmpty() {
    assert(unreadLength == 0, "stream has $unreadLength bytes after decode");
  }

  static String int2hexString(int value) {
    assert(value >= 0 && value < 256,
        "the number to decode into Hex String must be in the range of [0,256)");
    int num1 = value ~/ 16;
    int num0 = value % 16;
    String map = 'ABCDEF';
    String str1 = num1 >= 10 ? map[num1 - 10] : num1.toString();
    String str0 = num0 >= 10 ? map[num0 - 10] : num0.toString();
    return str1 + str0;
  }

  static int list2int(Uint8List list) {
    var stream = ByteStream(list);
    return stream.readInt(stream.length);
  }

  static Uint8List int2list(int value, int length) {
    Uint8List list = new Uint8List(0);
    for (int i = 0; i < length; i++) {
      list.add(value % 256);
      value ~/= 256;
    }
    list = list.reversed;
    return list;
  }

  static Uint8List hexString2list(String hex) {
    hex = hex.splitMapJoin(" ", onMatch: (Match match) {
      return "";
    });
    var result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  static String list2hexString(Uint8List list) {
    String hex = "";
    for (var n = 0; n < list.length; n++) {
      hex += int2hexString(list[n]);
    }
    return hex;
  }
}
