library ndef;

// main parser / generator
export 'src/record.dart';
// utility
export 'src/byteStream.dart';
// record types
export 'src/absoluteUri.dart';
export 'src/mime.dart';
export 'src/signature.dart';
export 'src/smartposter.dart';
export 'src/text.dart';
export 'src/uri.dart';

import 'dart:ffi';
import 'dart:typed_data';
import 'src/record.dart';
import 'src/byteStream.dart';


List<Record> decodeNdefMessage(Uint8List data) {

  var records = new List<Record>();
  var stream = new ByteStream(data);
  while (!stream.isEnd()) {
    records.add(Record.decode(stream));
  }

  return records;
}


Uint8List encodeNdefMessage(List<Record> records) {
  assert(records.length > 0);

  // canonicalize
  records.first.flags.MB = true;
  records.last.flags.ME = true;

  var encoded = new Uint8List(0);
  records.forEach((r) {
    encoded.addAll(r.encode());
  });

  return encoded;
}
