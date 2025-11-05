import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/records/well_known/well_known.dart';

/// A NDEF record containing a URI (Uniform Resource Identifier).
///
/// This record uses a prefix compression scheme to reduce the size of common URI prefixes.
class UriRecord extends WellKnownRecord {
  /// Map of URI prefixes for compression.
  static List<String> prefixMap = [
    "",
    "http://www.",
    "https://www.",
    "http://",
    "https://",
    "tel:",
    "mailto:",
    "ftp://anonymous:anonymous@",
    "ftp://ftp.",
    "ftps://",
    "sftp://",
    "smb://",
    "nfs://",
    "ftp://",
    "dav://",
    "news:",
    "telnet://",
    "imap:",
    "rtsp://",
    "urn:",
    "pop:",
    "sip:",
    "sips:",
    "tftp:",
    "btspp://",
    "btl2cap://",
    "btgoep://",
    "tcpobex://",
    "irdaobex://",
    "file://",
    "urn:epc:id:",
    "urn:epc:tag:",
    "urn:epc:pat:",
    "urn:epc:raw:",
    "urn:epc:",
    "urn:nfc:",
  ];

  /// The type identifier for URI records.
  static const String classType = "U";

  @override
  String get decodedType {
    return UriRecord.classType;
  }

  /// The minimum payload length for URI records.
  static const int classMinPayloadLength = 1;

  @override
  int get minPayloadLength {
    return classMinPayloadLength;
  }

  @override
  String toString() {
    var str = "UriRecord: ";
    str += basicInfoString;
    str += "uri=$uriString";
    return str;
  }

  int _prefixIndex = -1;
  
  /// The URI content after the prefix.
  String? content;

  /// Constructs a [UriRecord] with optional [prefix] and [content].
  UriRecord({String? prefix, this.content}) {
    if (prefix != null) {
      this.prefix = prefix;
    }
  }

  /// Constructs a [UriRecord] from a URI or IRI string.
  UriRecord.fromString(String? string) {
    iriString = string!;
  }

  /// Constructs a [UriRecord] from a [Uri] instance.
  UriRecord.fromUri(Uri? uri) {
    uriString = uri.toString();
  }

  /// Gets the URI prefix from the prefix map.
  String? get prefix {
    if (_prefixIndex == -1) {
      return null;
    }
    return prefixMap[_prefixIndex];
  }

  /// Sets the URI prefix (must be in the prefix map).
  set prefix(String? prefix) {
    int prefixIndex = prefixMap.indexOf(prefix!);
    if (prefixIndex == -1) {
      throw ArgumentError(
          "URI Prefix $prefix is not supported, please select one from $prefixMap");
    } else {
      _prefixIndex = prefixIndex;
    }
  }

  /// Gets the full IRI (Internationalized Resource Identifier) string.
  String? get iriString {
    if (prefix == null || content == null) {
      return null;
    }
    return prefix! + content!;
  }

  /// Sets the IRI string, automatically detecting and extracting the prefix.
  set iriString(String? iriString) {
    for (int i = 1; i < prefixMap.length; i++) {
      if (iriString!.startsWith(prefixMap[i])) {
        _prefixIndex = i;
        content = iriString.substring(prefix!.length);
        return;
      }
    }
    _prefixIndex = 0;
    content = iriString;
  }

  /// Gets the full URI string.
  String? get uriString {
    if (prefix == null || content == null) {
      return null;
    }
    return Uri.parse(prefix! + content!).toString();
  }

  /// Sets the URI string.
  set uriString(String? uriString) {
    iriString = uriString;
  }

  /// Gets the URI as a [Uri] instance.
  Uri? get uri {
    if (prefix == null || content == null) {
      return null;
    }
    return Uri.parse(iriString!);
  }

  /// Sets the URI from a [Uri] instance.
  set uri(Uri? uri) {
    iriString = uri.toString();
  }

  /// Encode and Get payload, return null when the prefix or content is null
  @override
  Uint8List? get payload {
    if (content == null || prefix == null) {
      return null;
    }
    return Uint8List.fromList([_prefixIndex] + utf8.encode(content!));
  }

  @override
  set payload(Uint8List? payload) {
    int prefixIndex = payload![0];
    if (prefixIndex < prefixMap.length) {
      _prefixIndex = prefixIndex;
    } else {
      _prefixIndex = 0;
    }
    content = utf8.decode(payload.sublist(1));
  }
}
