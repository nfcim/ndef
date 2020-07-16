library ndef;

// base class
export 'src/record.dart';
// utility
export 'src/byteStream.dart';
// record types
export 'src/record/absoluteUri.dart';
export 'src/record/mime.dart';
export 'src/record/signature.dart';
export 'src/record/smartposter.dart';
export 'src/record/text.dart';
export 'src/record/uri.dart';

import 'dart:typed_data';
import 'src/record.dart';
import 'src/byteStream.dart';

/// decode raw NDEF messages from byte array
List<Record> decodeRawNdefMessage(Uint8List data) {
  
  var records = new List<Record>();
  var stream = new ByteStream(data);
  while (!stream.isEnd()) {
    records.add(Record.decodeStream(stream));
  }

  return records;
}

/// decode partially parsed NDEF record
Record decodePartialNdefMessage(TypeNameFormat tnf, Uint8List type, Uint8List payload, {Uint8List id}) {
  var decoded = Record.doDecode(tnf, type, payload, id: id);
  // add default flags
  var flags = new RecordFlags();
  flags.TNF = TypeNameFormat.values.indexOf(tnf);
  decoded.flags = flags;
  return decoded;
}

/// encode an NDEF message to byte array
Uint8List encodeNdefMessage(List<Record> records, {bool canonicalize = true}) {
  assert(records.length > 0);

  if (canonicalize) {
    records.first.flags.MB = true;
    records.last.flags.ME = true;
  }

  var encoded = new Uint8List(0);
  records.forEach((r) {
    encoded.addAll(r.encode());
  });

  return encoded;
}
