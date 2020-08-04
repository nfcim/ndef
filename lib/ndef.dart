library ndef;

// base class
export 'record.dart';
// utility
export 'utilities.dart';
// record types
export 'record/absoluteUri.dart';
export 'record/mime.dart';
export 'record/deviceinfo.dart';
export 'record/signature.dart';
export 'record/smartposter.dart';
export 'record/text.dart';
export 'record/uri.dart';

import 'dart:typed_data';
import 'record.dart';
import 'utilities.dart';

/// Decode raw NDEF messages (containing at least one [NDEFRecord]) from byte array.
List<NDEFRecord> decodeRawNdefMessage(Uint8List data,
    {var typeFactory = NDEFRecord.defaultTypeFactory}) {
  var records = new List<NDEFRecord>();
  var stream = new ByteStream(data);
  while (!stream.isEnd()) {
    var record = NDEFRecord.decodeStream(stream, typeFactory);
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

/// Decode a NDEF record, providing its parts separately.
/// This is most useful in mobile envrionment because the APIs will give you these information in a separate manner.
NDEFRecord decodePartialNdefMessage(
    TypeNameFormat tnf, Uint8List type, Uint8List payload,
    {Uint8List id}) {
  var decoded = NDEFRecord.doDecode(tnf, type, payload, id: id);
  return decoded;
}

/// Encode an NDEF message (containing several [NDEFRecord]s) to byte array.
/// Set [canonicalize] to set the MB and ME fields automatically in the first / last record.
Uint8List encodeNdefMessage(List<NDEFRecord> records,
    {bool canonicalize = true}) {
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
