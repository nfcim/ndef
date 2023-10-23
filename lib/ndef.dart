library ndef;

import 'dart:typed_data';

import 'package:ndef/record.dart';
import 'package:ndef/utilities.dart';

// export all types of records as library
export 'record.dart';
export 'records/absolute_uri.dart';
export 'records/external/android_application.dart';
export 'records/external/external.dart';
export 'records/media/bluetooth.dart';
export 'records/media/mime.dart';
export 'records/well_known/device_info.dart';
export 'records/well_known/handover.dart';
export 'records/well_known/signature.dart';
export 'records/well_known/smart_poster.dart';
export 'records/well_known/text.dart';
export 'records/well_known/uri.dart';
export 'records/well_known/well_known.dart';


/// Decode raw NDEF messages (containing at least one [NDEFRecord]) from byte array
List<NDEFRecord> decodeRawNdefMessage(Uint8List data,
    {var typeFactory = NDEFRecord.defaultTypeFactory}) {
  var records = <NDEFRecord>[];
  var stream = ByteStream(data);
  while (!stream.isEnd()) {
    var record = NDEFRecord.decodeStream(stream, typeFactory);
    if (records.isEmpty) {
      assert(record.flags.MB == true, "MB flag is not set in first record");
    } else {
      assert(record.flags.MB == false, "MB flag is set in middle record");
    }
    records.add(record);
  }
  assert(records.last.flags.ME == true, "ME flag is not set in last record");
  assert(records.last.flags.CF == false, "CF flag is set in last record");
  return records;
}

/// Decode a NDEF record, providing its parts separately.
/// This is most useful in mobile environment because the APIs will give you these information in a separate manner.
NDEFRecord decodePartialNdefMessage(
    TypeNameFormat tnf, Uint8List type, Uint8List payload,
    {Uint8List? id}) {
  var decoded = NDEFRecord.doDecode(tnf, type, payload, id: id);
  return decoded;
}

/// Encode an NDEF message (containing several [NDEFRecord]s) to byte array.
/// Set [canonicalize] to set the MB and ME fields automatically in the first / last record.
Uint8List encodeNdefMessage(List<NDEFRecord> records,
    {bool canonicalize = true}) {
  if (records.isEmpty) {
    return Uint8List(0);
  }

  for (var r in records) {
    r.flags.resetPositionFlag();
  }

  if (canonicalize) {
    records.first.flags.MB = true;
    records.last.flags.ME = true;
  }

  var encoded = <int>[];
  for (var r in records) {
    encoded.addAll(r.encode());
  }

  return Uint8List.fromList(encoded);
}
