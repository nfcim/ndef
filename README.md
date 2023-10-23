# ndef

[![pub version](https://img.shields.io/pub/v/ndef)](https://pub.dev/packages/ndef)
![Test](https://github.com/nfcim/ndef/workflows/Test/badge.svg)

`ndef` is a Dart library to decode & encode NDEF records, supporting multiple types including (grouped by Type Name Format):

* NFC Well-known Records (TNF 1 / `urn:nfc:wkt:`), with:
  * Text (class `T`)
  * URI with well-known prefix (class `U`)
  * Digital signature (class `Sig`)
  * Smart poster (class `Sp`), including sub-record:
    * Action (class `act`)
    * Size (class `s`)
    * Type (class `t`)
  * Connection handover (class `Hr/Hs/Hm/Hi/Hc/ac/cr`)
* Media Records (TNF 2, containing MIME data), with:
  * Bluetooth easy pairing (class `application/vnd.bluetooth.ep.oob`)
  * Bluetooth low energy (class `application/vnd.bluetooth.le.oob`)
* Absolute URI Records (TNF 3)
* External Records (TNF 4 / `urn:nfc:ext:`), with:
  * Android application record (class `android.com:pkg`)

**This library is still under active development and subject to breaking API changes and malfunction. Pull requests and issues are most welcomed, especially on:**

* Bug fixes
* New support for other record types

## Usage

```dart
import 'package:ndef/ndef.dart' as ndef;

// encoding
var uriRecord = new ndef.UriRecord.fromString("https://github.com/nfcim/ndef");
var textRecord = new ndef.TextRecord(text: "Hello");
var encodedUriRecord = uriRecord.encode().toHexString(); /// encode a single record, and use our extension method on [Uint8List]
var encodedAllRecords = ndef.encodeNdefMessage([uriRecord, textRecord]).toHexString(); // encode several records as a message

// decoding
var encodedTextRecord = "d1010f5402656e48656c6c6f20576f726c6421";
var decodedRecords = ndef.decodeRawNdefMessage(encodedTextRecord.toBytes());
assert(decodedRecords.length == 1);
if (decodedRecords[0] is ndef.TextRecord) {
  assert(decodeRecords[0].text == "Hello");
}  else {
  // we will not reach here
}

// data-binding (by implementing payload as dynamic getter / setter)
var origPayload = uriRecord.payload!;
print(origPayload.toHexString());
uriRecord.content = "github.com/nfcim/flutter_nfc_kit";
print(uriRecord.payload!.toHexString()); // changed
uriRecord.payload = origPayload;
print(uriRecord.content); // changed back

// decoding by providing parts of a record
var partiallyDecodedUrlRecord = ndef.decodePartialNdefMessage(ndef.TypeNameFormat.nfcWellKnown, utf8.encode("U"), origPayload, id: Uint8List.fromList([0x1, 0x2]));
```

See [example code](example/lib/main.dart) for a more complete example.

Refer to the [documentation](https://pub.dev/documentation/ndef/) for detailed usage.
