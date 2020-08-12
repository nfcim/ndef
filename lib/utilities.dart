import 'dart:typed_data';

/// Represent an endianness
enum Endianness { Big, Little }

/// Utility class to play with raw bytes
class ByteUtils {
  static int boolToInt(bool value) {
    return value ? 1 : 0;
  }

  static int bytesToInt(Uint8List bytes,
      {Endianness endianness = Endianness.Big}) {
    var stream = ByteStream(bytes);
    return stream.readInt(stream.length, endianness: endianness);
  }

  static Uint8List intToBytes(int value, int length,
      {Endianness endianness = Endianness.Big}) {
    assert(length <= 8);
    var list = new List<int>();
    for (int i = 0; i < length; i++) {
      list.add(value % 256);
      value ~/= 256;
    }
    if (endianness == Endianness.Big) {
      list = list.reversed.toList();
    }
    return new Uint8List.fromList(list);
  }

  static String intToHexString(int value, int length,
      {Endianness endianness = Endianness.Big}) {
    return bytesToHexString(intToBytes(value, length, endianness: endianness));
  }

  static BigInt bytesToBigInt(Uint8List bytes,
      {Endianness endianness = Endianness.Big}) {
    var stream = ByteStream(bytes);
    return stream.readBigInt(stream.length, endianness: endianness);
  }

  static Uint8List bigIntToBytes(BigInt value, int length,
      {endianness = Endianness.Big}) {
    Uint8List list = new List<int>(0);
    for (int i = 0; i < length; i++) {
      list.add((value % (new BigInt.from(256))).toInt());
      value ~/= (new BigInt.from(256));
    }
    if (endianness == Endianness.Big) {
      list = list.reversed;
    }
    return new Uint8List.fromList(list);
  }

  static String byteToHexString(int value) {
    assert(value >= 0 && value < 256,
        "the number to decode into Hex String must be in the range of [0,256)");
    var str = value.toRadixString(16);
    if (str.length == 1) {
      str = '0' + str;
    }
    return str;
  }

  static Uint8List hexStringToBytes(String hex) {
    hex = hex.splitMapJoin(" ", onMatch: (Match match) {
      return "";
    });
    if (hex.length % 2 != 0) {
      throw "Hex string length must be even integer, got ${hex.length}";
    }
    var result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return new Uint8List.fromList(result);
  }

  static String bytesToHexString(Uint8List bytes) {
    String hex = "";
    for (var n = 0; n < bytes.length; n++) {
      hex += byteToHexString(bytes[n]);
    }
    return hex;
  }
}

/// Extension to convert [Uint8List] (Bytes) to other types
extension BytesConvert on Uint8List {
  int toInt({Endianness endianness = Endianness.Big}) => ByteUtils.bytesToInt(this,endianness: endianness);
  String toHexString() => ByteUtils.bytesToHexString(this);
  BigInt toBigInt() => ByteUtils.bytesToBigInt(this);
  Uint8List toReverse() {
    return Uint8List.fromList(this.reversed.toList());
  }
}

/// Extension to convert Hex String to other types
extension HexStringConvert on String {
  Uint8List toBytes() => ByteUtils.hexStringToBytes(this);
}

/// Extension to convert int to other types, a int can be a single byte or multiple bytes
extension IntConvert on int {
  String toHexStringAsByte() => ByteUtils.byteToHexString(this);
  String toHexStringAsBytes(int length,
          {Endianness endianness = Endianness.Big}) =>
      ByteUtils.intToHexString(this, length, endianness: endianness);
  Uint8List toBytes(int length, {Endianness endianness = Endianness.Big}) =>
      ByteUtils.intToBytes(this, length, endianness: endianness);
}

/// Extension to convert Hex String to other types
extension BigIntConvert on BigInt {
  Uint8List toBytes(int length, {Endianness endianness = Endianness.Big}) =>
      ByteUtils.bigIntToBytes(this, length, endianness: endianness);
}

/// Extension to convert bool to int
extension BoolConvert on bool {
  int toInt() => ByteUtils.boolToInt(this);
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

  int readInt(int number, {Endianness endianness = Endianness.Big}) {
    if (number > 8) {
      throw "Number of bytes converted to a int must be in [0,8)";
    }
    Uint8List d = readBytes(number);
    int value = 0;
    if (endianness == Endianness.Big) {
      for (var n = 0; n < d.length; n++) {
        value <<= 8;
        value += d[n];
      }
    } else if (endianness == Endianness.Little) {
      for (var n = d.length - 1; n >= 0; n--) {
        value <<= 8;
        value += d[n];
      }
    }
    return value;
  }

  BigInt readBigInt(int number, {Endianness endianness = Endianness.Big}) {
    Uint8List d = readBytes(number);
    BigInt value = new BigInt.from(0);
    if (endianness == Endianness.Big) {
      for (var n = 0; n < d.length; n++) {
        value <<= 256;
        value += new BigInt.from(d[d.length - n - 1]);
      }
    } else if (endianness == Endianness.Little) {
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
    return ByteUtils.bytesToHexString(list);
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
