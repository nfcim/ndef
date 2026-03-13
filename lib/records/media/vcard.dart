import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/records/media/mime.dart';

/// Escapes special characters in a vCard value.
String _escapeValue(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll(',', r'\,')
      .replaceAll(';', r'\;')
      .replaceAll('\n', r'\n');
}

/// Unescapes special characters in a vCard value.
String _unescapeValue(String value) {
  return value
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\,', ',')
      .replaceAll(r'\;', ';')
      .replaceAll(r'\\', r'\');
}

/// Extracts the TYPE parameter value from a parameter string.
///
/// Handles both vCard 3.0/4.0 format ("TYPE=CELL") and vCard 2.1
/// format ("CELL") where the type is specified without a TYPE= prefix.
String? _extractTypeParam(String parameters) {
  if (parameters.isEmpty) return null;
  // Handle "TYPE=CELL" and "type=cell" formats (vCard 3.0/4.0)
  final match =
      RegExp(r'TYPE=([^;,]+)', caseSensitive: false).firstMatch(parameters);
  if (match != null) return match.group(1);
  // Handle vCard 2.1 format where type is bare: "TEL;CELL:number"
  // The parameter is the type itself (e.g., "CELL", "HOME", "WORK")
  final bareParam = parameters.split(';').first.trim().toUpperCase();
  const knownTypes = {
    'CELL', 'HOME', 'WORK', 'FAX', 'PAGER', 'VOICE', 'MSG',
    'PREF', 'BBS', 'MODEM', 'CAR', 'ISDN', 'VIDEO',
    // Address types
    'DOM', 'INTL', 'POSTAL', 'PARCEL',
  };
  if (knownTypes.contains(bareParam)) return bareParam;
  return null;
}

/// A NDEF record for vCard contact sharing (RFC 6350).
///
/// This record type uses the MIME type "text/vcard" and contains
/// contact information in vCard format for easy sharing through NFC.
///
/// Supports vCard 2.1, 3.0, and 4.0 formats. When creating new records,
/// defaults to vCard 3.0.
///
/// Example:
/// ```dart
/// var vcardRecord = VCardRecord(
///   formattedName: 'John Doe',
///   name: VCardName(
///     familyName: 'Doe',
///     givenName: 'John',
///   ),
///   emails: ['john@example.com'],
///   phones: [VCardPhone(number: '+1-555-0100', type: 'CELL')],
///   organization: 'ACME Corp',
/// );
/// ```
class VCardRecord extends MimeRecord {
  /// The MIME type for vCard records.
  static const String classType = "text/vcard";

  /// vCard version (default: "3.0")
  String version;

  /// Formatted name (FN property, required in vCard 3.0+)
  String? formattedName;

  /// Structured name (N property)
  VCardName? name;

  /// Email addresses
  List<String> emails;

  /// Phone numbers with optional type info
  List<VCardPhone> phones;

  /// Organization name
  String? organization;

  /// Job title
  String? title;

  /// Postal addresses
  List<VCardAddress> addresses;

  /// URL
  String? url;

  /// Note / additional text
  String? note;

  @override
  String get decodedType => VCardRecord.classType;

  /// Constructs a [VCardRecord] with contact information.
  VCardRecord({
    this.version = '3.0',
    this.formattedName,
    this.name,
    List<String>? emails,
    List<VCardPhone>? phones,
    this.organization,
    this.title,
    List<VCardAddress>? addresses,
    this.url,
    this.note,
    super.id,
  })  : emails = emails ?? [],
        phones = phones ?? [],
        addresses = addresses ?? [],
        super(decodedType: VCardRecord.classType);

  @override
  String toString() {
    var str = "VCardRecord: ";
    if (formattedName != null) str += "name=$formattedName ";
    if (emails.isNotEmpty) str += "emails=$emails ";
    if (phones.isNotEmpty) str += "phones=$phones ";
    if (organization != null) str += "org=$organization ";
    return str;
  }

  /// Builds a vCard string from the structured properties.
  String _buildVCard() {
    if (formattedName == null && name == null) {
      throw ArgumentError(
        'At least formattedName or name is required for a vCard record',
      );
    }

    final lines = <String>[];
    lines.add('BEGIN:VCARD');
    lines.add('VERSION:$version');

    if (formattedName != null) {
      lines.add('FN:${_escapeValue(formattedName!)}');
    }

    if (name != null) {
      lines.add('N:${name!.encode()}');
    }

    for (var email in emails) {
      lines.add('EMAIL:${_escapeValue(email)}');
    }

    for (var phone in phones) {
      if (phone.type != null) {
        lines.add('TEL;TYPE=${phone.type}:${_escapeValue(phone.number)}');
      } else {
        lines.add('TEL:${_escapeValue(phone.number)}');
      }
    }

    if (organization != null) {
      lines.add('ORG:${_escapeValue(organization!)}');
    }

    if (title != null) {
      lines.add('TITLE:${_escapeValue(title!)}');
    }

    for (var addr in addresses) {
      lines.add(addr.encode());
    }

    if (url != null) {
      lines.add('URL:${_escapeValue(url!)}');
    }

    if (note != null) {
      lines.add('NOTE:${_escapeValue(note!)}');
    }

    lines.add('END:VCARD');
    return lines.join('\r\n');
  }

  /// Parses a vCard string into structured properties.
  void _parseVCard(String vcardText) {
    // Unfold lines (RFC 6350 section 3.2): a line starting with space/tab
    // is a continuation of the previous line.
    final unfolded = vcardText.replaceAll(RegExp(r'\r?\n[ \t]'), '');

    final lines = unfolded.split(RegExp(r'\r?\n'));

    // Reset fields
    formattedName = null;
    name = null;
    emails = [];
    phones = [];
    addresses = [];
    organization = null;
    title = null;
    url = null;
    note = null;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Parse property name and value, handling parameters
      final colonIndex = line.indexOf(':');
      if (colonIndex < 0) continue;

      final propertyPart = line.substring(0, colonIndex);
      final value = line.substring(colonIndex + 1);

      // Extract base property name (before any parameters)
      final semicolonIndex = propertyPart.indexOf(';');
      final propertyName = semicolonIndex >= 0
          ? propertyPart.substring(0, semicolonIndex).toUpperCase()
          : propertyPart.toUpperCase();
      final parameters =
          semicolonIndex >= 0 ? propertyPart.substring(semicolonIndex + 1) : '';

      switch (propertyName) {
        case 'VERSION':
          version = value;
          break;
        case 'FN':
          formattedName = _unescapeValue(value);
          break;
        case 'N':
          name = VCardName.decode(value);
          break;
        case 'EMAIL':
          emails.add(_unescapeValue(value));
          break;
        case 'TEL':
          final type = _extractTypeParam(parameters);
          phones.add(VCardPhone(number: _unescapeValue(value), type: type));
          break;
        case 'ORG':
          organization = _unescapeValue(value);
          break;
        case 'TITLE':
          title = _unescapeValue(value);
          break;
        case 'ADR':
          addresses.add(VCardAddress.decode(value, parameters));
          break;
        case 'URL':
          url = _unescapeValue(value);
          break;
        case 'NOTE':
          note = _unescapeValue(value);
          break;
      }
    }
  }

  @override
  Uint8List? get payload {
    final vcardString = _buildVCard();
    return Uint8List.fromList(utf8.encode(vcardString));
  }

  @override
  set payload(Uint8List? payload) {
    if (payload == null || payload.isEmpty) {
      throw ArgumentError('Payload cannot be null or empty');
    }

    final vcardString = utf8.decode(payload);
    _parseVCard(vcardString);
  }
}

/// Structured name for vCard N property.
///
/// Components follow the vCard spec order:
/// family;given;additional;prefix;suffix
class VCardName {
  String familyName;
  String givenName;
  String additionalNames;
  String honorificPrefixes;
  String honorificSuffixes;

  VCardName({
    this.familyName = '',
    this.givenName = '',
    this.additionalNames = '',
    this.honorificPrefixes = '',
    this.honorificSuffixes = '',
  });

  /// Escapes a single N-property component (`;` and `\` must be escaped).
  static String _escapeComponent(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll(';', r'\;');
  }

  /// Unescapes a single N-property component.
  static String _unescapeComponent(String value) {
    return value.replaceAll(r'\;', ';').replaceAll(r'\\', r'\');
  }

  /// Encodes the name to vCard N property value format.
  String encode() {
    return '${_escapeComponent(familyName)};${_escapeComponent(givenName)}'
        ';${_escapeComponent(additionalNames)}'
        ';${_escapeComponent(honorificPrefixes)}'
        ';${_escapeComponent(honorificSuffixes)}';
  }

  /// Decodes a vCard N property value string.
  ///
  /// Splits on unescaped `;` delimiters to correctly handle escaped
  /// semicolons within component values.
  static VCardName decode(String value) {
    final parts = _splitUnescaped(value, ';');
    return VCardName(
      familyName: parts.isNotEmpty ? _unescapeComponent(parts[0]) : '',
      givenName: parts.length > 1 ? _unescapeComponent(parts[1]) : '',
      additionalNames: parts.length > 2 ? _unescapeComponent(parts[2]) : '',
      honorificPrefixes: parts.length > 3 ? _unescapeComponent(parts[3]) : '',
      honorificSuffixes: parts.length > 4 ? _unescapeComponent(parts[4]) : '',
    );
  }

  /// Splits a string on unescaped occurrences of [delimiter].
  static List<String> _splitUnescaped(String value, String delimiter) {
    final parts = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      if (value[i] == delimiter) {
        // Check if preceded by an odd number of backslashes (escaped)
        var backslashes = 0;
        var j = i - 1;
        while (j >= 0 && value[j] == '\\') {
          backslashes++;
          j--;
        }
        if (backslashes.isOdd) {
          buffer.write(value[i]);
        } else {
          parts.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(value[i]);
      }
    }
    parts.add(buffer.toString());
    return parts;
  }

  @override
  String toString() => '${givenName.isNotEmpty ? givenName : ''}'
      '${givenName.isNotEmpty && familyName.isNotEmpty ? ' ' : ''}'
      '${familyName.isNotEmpty ? familyName : ''}';
}

/// Phone number with optional type (CELL, WORK, HOME, etc.)
class VCardPhone {
  String number;
  String? type;

  VCardPhone({required this.number, this.type});

  @override
  String toString() => type != null ? '$type:$number' : number;
}

/// Postal address for vCard ADR property.
///
/// Components follow the vCard spec order:
/// PO Box;Extended;Street;City;Region;Postal Code;Country
class VCardAddress {
  String? type;
  String poBox;
  String extended;
  String street;
  String city;
  String region;
  String postalCode;
  String country;

  VCardAddress({
    this.type,
    this.poBox = '',
    this.extended = '',
    this.street = '',
    this.city = '',
    this.region = '',
    this.postalCode = '',
    this.country = '',
  });

  /// Encodes the address to vCard ADR property line.
  String encode() {
    final value = '$poBox;$extended;$street;$city;$region;$postalCode;$country';
    if (type != null) {
      return 'ADR;TYPE=$type:$value';
    }
    return 'ADR:$value';
  }

  /// Decodes a vCard ADR property value string.
  static VCardAddress decode(String value, String parameters) {
    final parts = value.split(';');
    final type = _extractTypeParam(parameters);
    return VCardAddress(
      type: type,
      poBox: parts.isNotEmpty ? parts[0] : '',
      extended: parts.length > 1 ? parts[1] : '',
      street: parts.length > 2 ? parts[2] : '',
      city: parts.length > 3 ? parts[3] : '',
      region: parts.length > 4 ? parts[4] : '',
      postalCode: parts.length > 5 ? parts[5] : '',
      country: parts.length > 6 ? parts[6] : '',
    );
  }

  @override
  String toString() {
    final parts = [street, city, region, postalCode, country]
        .where((s) => s.isNotEmpty)
        .join(', ');
    return type != null ? '$type: $parts' : parts;
  }
}
