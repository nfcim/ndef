import 'dart:typed_data';

enum Endianness { big, little }

/// Utility class to play with raw bytes
class ByteUtils {
  static int bool2int(bool value) {
    return value ? 1 : 0;
  }

  static String int2hexString(int value) {
    assert(value >= 0 && value < 256,
        "the number to decode into Hex String must be in the range of [0,256)");
    var str = value.toRadixString(16);
    if (str.length == 1) {
      str = '0' + str;
    }
    return str;
  }

  static int list2int(Uint8List list, {endianness = Endianness.big}) {
    var stream = ByteStream(list);
    return stream.readInt(stream.length, endianness: endianness);
  }

  static Uint8List int2list(int value, int length,
      {endianness = Endianness.big}) {
    assert(length <= 8);
    var list = new List<int>();
    for (int i = 0; i < length; i++) {
      list.add(value % 256);
      value ~/= 256;
    }
    if (endianness == Endianness.big) {
      list = list.reversed.toList();
    }
    return new Uint8List.fromList(list);
  }

  static BigInt list2bigInt(Uint8List list, {endianness = Endianness.big}) {
    var stream = ByteStream(list);
    return stream.readBigInt(stream.length, endianness: endianness);
  }

  static Uint8List bigInt2list(BigInt value, int length,
      {endianness = Endianness.big}) {
    Uint8List list = new List<int>(0);
    for (int i = 0; i < length; i++) {
      list.add((value % (new BigInt.from(256))).toInt());
      value ~/= (new BigInt.from(256));
    }
    if (endianness == Endianness.big) {
      list = list.reversed;
    }
    return new Uint8List.fromList(list);
  }

  static Uint8List hexString2list(String hex) {
    hex = hex.splitMapJoin(" ", onMatch: (Match match) {
      return "";
    });
    var result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return new Uint8List.fromList(result);
  }

  static String list2hexString(Uint8List list) {
    String hex = "";
    for (var n = 0; n < list.length; n++) {
      hex += int2hexString(list[n]);
    }
    return hex;
  }
}

/// byte stream utility class for decoding
class ByteStream {
  Uint8List _data;
  int _current = 0;

  get readLength {
    return _current;
  }

  get unreadLength {
    return _data.length - _current;
  }

  get length {
    return _data.length;
  }

  ByteStream(Uint8List data) {
    _data = data;
  }

  @override
  String toString() {
    var str = "ByteStream: ";
    str += "current=$_current ";
    str += "data=$_data";
    return str;
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

  int readInt(int number, {Endianness endianness = Endianness.big}) {
    if (number > 8) {
      throw "Number of bytes converted to a int must be in [0,8)";
    }
    Uint8List d = readBytes(number);
    int value = 0;
    if (endianness == Endianness.big) {
      for (var n = 0; n < d.length; n++) {
        value <<= 8;
        value += d[n];
      }
    } else if (endianness == Endianness.little) {
      for (var n = d.length - 1; n >= 0; n--) {
        value <<= 8;
        value += d[n];
      }
    }
    return value;
  }

  BigInt readBigInt(int number, {Endianness endianness = Endianness.big}) {
    Uint8List d = readBytes(number);
    BigInt value = new BigInt.from(0);
    if (endianness == Endianness.big) {
      for (var n = 0; n < d.length; n++) {
        value <<= 256;
        value += new BigInt.from(d[d.length - n - 1]);
      }
    } else if (endianness == Endianness.little) {
      for (var n = d.length - 1; n >= 0; n--) {
        value <<= 256;
        value += new BigInt.from(d[d.length - n - 1]);
      }
    }
    return value;
  }

  Uint8List readAll() {
    return readBytes(unreadLength);
  }

  String readHexString(int number) {
    Uint8List list = readBytes(number);
    return ByteUtils.list2hexString(list);
  }

  void checkBytesAvailable(int number) {
    if (number > unreadLength) {
      throw "there is not enough $number bytes in stream";
    }
  }

  void checkEmpty() {
    if (unreadLength != 0) {
      throw "stream has $unreadLength bytes after decode";
    }
  }
}
