library ndef;

// base class
export 'src/record.dart';
// utility
export 'src/byteStream.dart';
// record types
export 'src/record/absoluteUri.dart';
export 'src/record/mime.dart';
export 'src/record/deviceinfo.dart';
export 'src/record/signature.dart';
export 'src/record/smartposter.dart';
export 'src/record/text.dart';
export 'src/record/uri.dart';

import 'dart:typed_data';
import 'src/record.dart';
import 'src/byteStream.dart';

/// decode raw NDEF messages from byte array
List<Record> decodeRawNdefMessage(Uint8List data,
    {var typeFactory = Record.typeFactory}) {
  var records = new List<Record>();
  var stream = new ByteStream(data);
  while (!stream.isEnd()) {
    var record = Record.decodeStream(stream, typeFactory);
    if (records.length == 0) {
      if (record.flags.MB == false) {
        throw "MB flag is not set in first record";
      }
    } else {
      if (record.flags.MB == true) {
        throw "MB flag is set in middle record";
      }
    }
    records.add(record);
  }
  if (records.last.flags.ME != true) {
    throw "ME flag is not set in last record";
  }
  if (records.last.flags.CF == true) {
    throw "CF flag is set in last record";
  }
  return records;
}

/// decode partially parsed NDEF record
Record decodePartialNdefMessage(
    TypeNameFormat tnf, Uint8List type, Uint8List payload,
    {Uint8List id}) {
  var decoded = Record.doDecode(tnf, type, payload, id: id);
  return decoded;
}

/// encode an NDEF message to byte array
Uint8List encodeNdefMessage(List<Record> records, {bool canonicalize = true}) {
  if (records.length == 0) {
    return new Uint8List(0);
  }

  if (canonicalize) {
    records.first.flags.MB = true;
    records.last.flags.ME = true;
  }

  var encoded = new List<int>();
  records.forEach((r) {
    encoded.addAll(r.encode());
  });

  return new Uint8List.fromList(encoded);
}
