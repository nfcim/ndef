import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:ndef/utilities.dart';

void main() {
  group('ByteUtils', () {
    test('bytesEqual', () {
      expect(ByteUtils.bytesEqual(null, null), isTrue);
      expect(
        ByteUtils.bytesEqual(
          Uint8List.fromList([1, 2, 3]),
          Uint8List.fromList([1, 2]),
        ),
        isFalse,
      );
      expect(
        ByteUtils.bytesEqual(
          Uint8List.fromList([1, 2, 3]),
          Uint8List.fromList([1, 2, 4]),
        ),
        isFalse,
      );
      expect(
        ByteUtils.bytesEqual(
          Uint8List.fromList([1, 2, 3]),
          Uint8List.fromList([1, 2, 3]),
        ),
        isTrue,
      );
      expect(
        ByteUtils.bytesEqual(Uint8List.fromList([1, 2, 3]), null),
        isFalse,
      );
    });

    test('toHexString on empty bytes', () {
      expect(Uint8List(0).toHexString(), "");
      expect(Uint8List.fromList([]).toHexString(), "");
    });
  });
}
