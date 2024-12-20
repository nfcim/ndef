## 0.1.0

* Initial release, preliminary decoding & encoding support
* Support types:
  * NFC Well Known
    * Text
    * URI with well-known prefix
    * Digital signature
    * Smart poster
    * Connection handover
  * Media (MIME data)
    * Bluetooth easy pairing / Bluetooth low energy
    * other MIME data
  * Absolute URI

## 0.2.0

* Fix some bugs on Connection handover records
* Fix encoding / decoding of text records in UTF-16 (remove dependency of discontinued `utf` library)
* Use extension methods to simplify usage

## 0.2.1

* Fix some bugs caused by `null` when use blank records
* Simplify method to compare bytes (remove dependency of `collection` library)

## 0.2.2

* Adjust exception information
* Move Version class from HandoverRecord to utilities

## 0.2.3

* Bump dependencies including `uuid` and `version`
* Minor bug fixes

## 0.3.0

* Upgrade to Flutter 2.0
* Add null-safety support (#8)
* Fix some typos in code
* Use more precise exception in precondition-checking code (#9)

## 0.3.1

Note: this tag is not pushed to GitHub, but published to pub.dev.

* Remove unneeded `required` in `decodePartialNdefMessage`
* Remove unused test
* Change to a formal version of MIT License

## 0.3.2

* Upgrade to Dart v3
* Fix multiple bugs (#14, #15, #17, #18)

## 0.3.3

* Restructure the project (no functional changes)
* Fix numerous lint warnings

## 0.3.4

* No functional changes
* Fix more lint warnings
