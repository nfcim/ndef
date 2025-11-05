import 'dart:typed_data';

/// Represents the byte order (endianness) for multi-byte values.
enum Endianness { 
  /// Big-endian byte order (most significant byte first).
  Big, 
  /// Little-endian byte order (least significant byte first).
  Little 
}

/// Utility class to play with raw bytes.
///
/// Provides static methods for converting between bytes, integers, hex strings,
/// and other data formats commonly used in NDEF record processing.
class ByteUtils {
  /// Converts a boolean [value] to an integer (0 or 1).
  static int boolToInt(bool value) {
    return value ? 1 : 0;
  }

  /// Converts [bytes] to an integer with the specified [endianness].
  static int bytesToInt(Uint8List? bytes,
      {Endianness endianness = Endianness.Big}) {
    var stream = ByteStream(bytes!);
    return stream.readInt(stream.length, endianness: endianness);
  }

  /// Converts an integer [value] to bytes with specified [length] and [endianness].
  static Uint8List intToBytes(int value, int length,
      {Endianness endianness = Endianness.Big}) {
    assert(length <= 8);
    var list = <int>[];

    var v = value;
    for (int i = 0; i < length; i++) {
      list.add(v % 256);
      v ~/= 256;
    }
    if (v != 0) {
      throw "Value $value is overflow from range of $length bytes";
    }
    if (endianness == Endianness.Big) {
      list = list.reversed.toList();
    }
    return Uint8List.fromList(list);
  }

  /// Converts an integer [value] to a hex string with specified [length] and [endianness].
  static String intToHexString(int value, int length,
      {Endianness endianness = Endianness.Big}) {
    return bytesToHexString(intToBytes(value, length, endianness: endianness));
  }

  /// Converts [bytes] to a BigInt with the specified [endianness].
  static BigInt bytesToBigInt(Uint8List bytes,
      {Endianness endianness = Endianness.Big}) {
    var stream = ByteStream(bytes);
    return stream.readBigInt(stream.length, endianness: endianness);
  }

  /// Converts a BigInt [value] to bytes with specified [length] and [endianness].
  static Uint8List bigIntToBytes(BigInt? value, int length,
      {endianness = Endianness.Big}) {
    Uint8List? list = List<int?>.filled(0, null, growable: false) as Uint8List;
    BigInt? v = value;
    for (int i = 0; i < length; i++) {
      list.add((v! % (BigInt.from(256))).toInt());
      v ~/= (BigInt.from(256));
    }

    /// unrelated_type_equality_check checked!
    BigInt zero = 0 as BigInt;
    if (v != zero) {
      throw "Value $value is overflow from range of $length bytes";
    }
    if (endianness == Endianness.Big) {
      list = list.reversed as Uint8List?;
    }
    return Uint8List.fromList(list!);
  }

  /// Converts a single byte [value] to a 2-character hex string.
  static String byteToHexString(int value) {
    assert(value >= 0 && value < 256,
        "Value to decode into Hex String must be in the range of [0,256)");
    var str = value.toRadixString(16);
    if (str.length == 1) {
      str = '0$str';
    }
    return str;
  }

  /// Converts a hex string to bytes.
  ///
  /// Spaces in the hex string are ignored.
  static Uint8List hexStringToBytes(String hex) {
    // Delete blank space
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
    return Uint8List.fromList(result);
  }

  /// Converts bytes to hex string, returns an empty string when bytes is null or empty.
  static String bytesToHexString(Uint8List? bytes) {
    if (bytes == null) {
      return "";
    }
    String hex = "";
    for (var n = 0; n < bytes.length; n++) {
      hex += byteToHexString(bytes[n]);
    }
    return hex;
  }

  /// Checks if two byte arrays [bytes1] and [bytes2] are equal.
  static bool bytesEqual(Uint8List? bytes1, Uint8List? bytes2) {
    if (identical(bytes1, bytes2)) return true;
    if (bytes1 == null || bytes2 == null) return false;
    int length = bytes1.length;
    if (length != bytes2.length) return false;
    for (int i = 0; i < length; i++) {
      if (bytes1[i] != bytes2[i]) return false;
    }
    return true;
  }
}

/// Extension to convert [Uint8List] (Bytes) to other types.
extension BytesConvert on Uint8List {
  /// Converts bytes to an integer with the specified [endianness].
  int toInt({Endianness endianness = Endianness.Big}) =>
      ByteUtils.bytesToInt(this, endianness: endianness);
  
  /// Converts bytes to a hex string.
  String toHexString() => ByteUtils.bytesToHexString(this);
  
  /// Converts bytes to a BigInt.
  BigInt toBigInt() => ByteUtils.bytesToBigInt(this);
  
  /// Returns a reversed copy of the bytes.
  Uint8List toReverse() {
    return Uint8List.fromList(reversed.toList());
  }
}

/// Extension to convert hex String to bytes.
extension HexStringConvert on String {
  /// Converts a hex string to bytes.
  Uint8List toBytes() => ByteUtils.hexStringToBytes(this);
}

/// Extension to convert int to other types.
///
/// An int can represent a single byte or multiple bytes.
extension IntConvert on int {
  /// Converts a single byte integer to a hex string.
  String toHexStringAsByte() => ByteUtils.byteToHexString(this);
  
  /// Converts an integer to a hex string with specified [length] and [endianness].
  String toHexStringAsBytes(int length,
          {Endianness endianness = Endianness.Big}) =>
      ByteUtils.intToHexString(this, length, endianness: endianness);
  
  /// Converts an integer to bytes with specified [length] and [endianness].
  Uint8List toBytes(int length, {Endianness endianness = Endianness.Big}) =>
      ByteUtils.intToBytes(this, length, endianness: endianness);
}

/// Extension to convert BigInt to bytes.
extension BigIntConvert on BigInt {
  /// Converts a BigInt to bytes with specified [length] and [endianness].
  Uint8List toBytes(int length, {Endianness endianness = Endianness.Big}) =>
      ByteUtils.bigIntToBytes(this, length, endianness: endianness);
}

/// Extension to convert bool to int.
extension BoolConvert on bool {
  /// Converts a boolean to an integer (0 or 1).
  int toInt() => ByteUtils.boolToInt(this);
}

/// Byte stream utility class for decoding.
///
/// Provides sequential reading operations on byte arrays with position tracking.
class ByteStream {
  late Uint8List _data;
  int _current = 0;

  /// Gets the number of bytes that have been read so far.
  int get readLength {
    return _current;
  }

  /// Gets the number of bytes remaining to be read.
  int get unreadLength {
    return _data.length - _current;
  }

  /// Gets the total length of the byte stream.
  int get length {
    return _data.length;
  }

  /// Constructs a [ByteStream] from the given [data].
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

  /// Checks if the stream has reached the end.
  bool isEnd() {
    return _current == _data.length;
  }

  /// Reads and returns a single byte from the stream.
  int readByte() {
    checkBytesAvailable(1);
    return _data[_current++];
  }

  /// Reads and returns [number] bytes from the stream.
  Uint8List readBytes(int number) {
    checkBytesAvailable(number);
    Uint8List d = _data.sublist(_current, _current + number);
    _current += number;
    return d;
  }

  /// Reads [number] bytes and converts them to an integer with the specified [endianness].
  int readInt(int number, {Endianness endianness = Endianness.Big}) {
    if (number > 8) {
      throw "Number of bytes converted to a int must be in [0,8), got $number";
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

  /// Reads [number] bytes and converts them to a BigInt with the specified [endianness].
  BigInt readBigInt(int number, {Endianness endianness = Endianness.Big}) {
    Uint8List d = readBytes(number);
    BigInt value = BigInt.from(0);
    if (endianness == Endianness.Big) {
      for (var n = 0; n < d.length; n++) {
        value <<= 256;
        value += BigInt.from(d[d.length - n - 1]);
      }
    } else if (endianness == Endianness.Little) {
      for (var n = d.length - 1; n >= 0; n--) {
        value <<= 256;
        value += BigInt.from(d[d.length - n - 1]);
      }
    }
    return value;
  }

  /// Reads all remaining bytes from the stream.
  Uint8List readAll() {
    return readBytes(unreadLength);
  }

  /// Reads [number] bytes and converts them to a hex string.
  String readHexString(int number) {
    Uint8List list = readBytes(number);
    return ByteUtils.bytesToHexString(list);
  }

  /// Checks if [number] bytes are available in the stream.
  ///
  /// Throws an error if not enough bytes are available.
  void checkBytesAvailable(int number) {
    if (number > unreadLength) {
      throw "There is not enough $number bytes in stream";
    }
  }

  /// Checks if the stream is empty (all bytes have been read).
  ///
  /// Throws an error if there are unread bytes.
  void checkEmpty() {
    if (unreadLength != 0) {
      throw "Stream has $unreadLength bytes after decode";
    }
  }
}

/// Utility class to represent protocol version in NDEF records.
///
/// Versions are encoded as a single byte with major version in the upper 4 bits
/// and minor version in the lower 4 bits.
class Version {
  /// The raw version value as a byte.
  late int value;

  /// Returns a formatted version string from a raw [value].
  static String formattedString(int? value) {
    var version = Version(value: value);
    return version.string;
  }

  /// Constructs a [Version] with an optional raw [value].
  Version({int? value}) {
    if (value != null) {
      this.value = value;
    } else {
      value = 0;
    }
  }

  /// Constructs a [Version] from [major] and [minor] version numbers.
  Version.fromDetail(int major, int minor) {
    setDetail(major, minor);
  }

  /// Constructs a [Version] from a version string (e.g., "1.2").
  Version.fromString(String string) {
    this.string = string;
  }

  /// Gets the major version number.
  int get major {
    return value >> 4;
  }

  /// Sets the major version number.
  set major(int major) {
    value = major << 4 + minor;
  }

  /// Gets the minor version number.
  int get minor {
    return value & 0xf;
  }

  /// Sets the minor version number.
  set minor(int minor) {
    value = major << 4 + minor;
  }

  /// Gets the version as a formatted string (e.g., "1.2").
  String get string {
    return "$major.$minor";
  }

  /// Sets the version from a formatted string (e.g., "1.2").
  set string(String string) {
    var versions = string.split('.');
    if (versions.length != 2) {
      throw "Format of version string must be major.minor, got $string";
    }
    value = (int.parse(versions[0]) << 4) + int.parse(versions[1]);
  }

  /// Sets the version from [major] and [minor] version numbers.
  void setDetail(int major, int minor) {
    value = major << 4 + minor;
  }
}
