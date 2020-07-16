import 'dart:typed_data';

import '../record.dart';

class RawRecord extends Record {
  Uint8List type, payload;

  RawRecord(this.type, this.payload);

  @override
  Uint8List encodeType() {
    return type;
  }

  @override
  Uint8List encodePayload() {
    return payload;
  }
}
