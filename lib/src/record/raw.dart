import 'dart:typed_data';

import '../record.dart';

class RawRecord extends Record {
  Uint8List type, payload;

  RawRecord(this.type, this.payload);

  @override
  Uint8List encode() {
    return super.encodeRaw(this.type, this.payload);
  }
}
