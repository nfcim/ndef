import 'dart:typed_data';
import 'dart:convert';

import 'package:ndef/records/media/mime.dart';
import 'package:ndef/utilities.dart';

/// WiFi authentication types according to WSC specification.
enum WifiAuthenticationType {
  /// Open network (no authentication)
  open(0x0001),

  /// WPA Personal
  wpaPersonal(0x0002),

  /// Shared key
  shared(0x0004),

  /// WPA Enterprise
  wpaEnterprise(0x0008),

  /// WPA2 Enterprise
  wpa2Enterprise(0x0010),

  /// WPA2 Personal
  wpa2Personal(0x0020),

  /// WPA/WPA2 Personal
  wpaWpa2Personal(0x0022),

  /// WPA3 Personal (SAE)
  wpa3Personal(0x0040),

  /// WPA3 Enterprise
  wpa3Enterprise(0x0080);

  /// The WSC (WiFi Simple Configuration) value for this authentication type
  final int wscValue;

  const WifiAuthenticationType(this.wscValue);

  /// Creates a [WifiAuthenticationType] from a WSC value
  static WifiAuthenticationType fromWscValue(int value) {
    return values.firstWhere(
      (e) => e.wscValue == value,
      orElse: () => WifiAuthenticationType.open,
    );
  }
}

/// WiFi encryption types according to WSC specification.
enum WifiEncryptionType {
  /// No encryption
  none(0x0001),

  /// WEP encryption
  wep(0x0002),

  /// TKIP encryption
  tkip(0x0004),

  /// AES encryption
  aes(0x0008),

  /// AES/TKIP mixed mode
  aesTkip(0x000C);

  /// The WSC (WiFi Simple Configuration) value for this encryption type
  final int wscValue;

  const WifiEncryptionType(this.wscValue);

  /// Creates a [WifiEncryptionType] from a WSC value
  static WifiEncryptionType fromWscValue(int value) {
    return values.firstWhere(
      (e) => e.wscValue == value,
      orElse: () => WifiEncryptionType.none,
    );
  }
}

/// A NDEF record for WiFi network configuration (WiFi Simple Configuration).
///
/// This record type uses the MIME type "application/vnd.wfa.wsc" and contains
/// WiFi credentials for easy network connection through NFC.
///
/// Example:
/// ```dart
/// var wifiRecord = WifiRecord(
///   ssid: 'MyNetwork',
///   networkKey: 'mypassword',
///   authenticationType: WifiAuthenticationType.wpa2Personal,
///   encryptionType: WifiEncryptionType.aes,
/// );
/// ```
class WifiRecord extends MimeRecord {
  /// The MIME type for WiFi Simple Configuration records.
  static const String classType = "application/vnd.wfa.wsc";

  // WSC Attribute Type IDs
  static const int _attrCredential = 0x100E;
  static const int _attrSsid = 0x1045;
  static const int _attrNetworkKey = 0x1027;
  static const int _attrAuthType = 0x1003;
  static const int _attrEncryptionType = 0x100F;
  static const int _attrMacAddress = 0x1020;
  static const int _attrNetworkIndex = 0x1026;

  /// The WiFi network SSID (network name)
  String? ssid;

  /// The WiFi network password/key
  String? networkKey;

  /// The authentication type (WPA2, WPA3, etc.)
  WifiAuthenticationType authenticationType;

  /// The encryption type (AES, TKIP, etc.)
  WifiEncryptionType encryptionType;

  /// Optional MAC address
  String? macAddress;

  /// Network index (usually 0x01 for infrastructure networks)
  int networkIndex;

  @override
  String get decodedType {
    return WifiRecord.classType;
  }

  /// Constructs a [WifiRecord] with WiFi network credentials.
  ///
  /// [ssid] - Network name (required)
  /// [networkKey] - Network password (optional for open networks)
  /// [authenticationType] - Authentication method (defaults to WPA2 Personal)
  /// [encryptionType] - Encryption method (defaults to AES)
  /// [macAddress] - Optional MAC address in format "AA:BB:CC:DD:EE:FF"
  /// [networkIndex] - Network index (defaults to 1)
  WifiRecord({
    this.ssid,
    this.networkKey,
    this.authenticationType = WifiAuthenticationType.wpa2Personal,
    this.encryptionType = WifiEncryptionType.aes,
    this.macAddress,
    this.networkIndex = 1,
    Uint8List? id,
  }) : super(id: id) {
    // Validate MAC address format if provided
    if (macAddress != null) {
      _macAddressToBytes(macAddress); // This will throw if invalid
    }
  }

  @override
  String toString() {
    var str = "WifiRecord: ";
    str += "ssid=$ssid ";
    str += "authenticationType=$authenticationType ";
    str += "encryptionType=$encryptionType ";
    if (macAddress != null) {
      str += "macAddress=$macAddress ";
    }
    return str;
  }

  /// Encodes a TLV (Type-Length-Value) attribute
  static Uint8List _encodeTLV(int type, Uint8List value) {
    final typeBytes = Uint8List(2);
    typeBytes[0] = (type >> 8) & 0xFF;
    typeBytes[1] = type & 0xFF;

    final lengthBytes = Uint8List(2);
    lengthBytes[0] = (value.length >> 8) & 0xFF;
    lengthBytes[1] = value.length & 0xFF;

    return Uint8List.fromList([...typeBytes, ...lengthBytes, ...value]);
  }

  /// Parses MAC address string to bytes
  static Uint8List? _macAddressToBytes(String? macAddress) {
    if (macAddress == null) return null;

    final regex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    if (!regex.hasMatch(macAddress)) {
      throw ArgumentError('Invalid MAC address format: $macAddress');
    }

    final parts = macAddress.split(RegExp(r'[:-]'));
    return Uint8List.fromList(
      parts.map((part) => int.parse(part, radix: 16)).toList(),
    );
  }

  /// Converts MAC address bytes to string
  static String _macAddressToString(Uint8List bytes) {
    if (bytes.length != 6) {
      throw ArgumentError('MAC address must be 6 bytes');
    }
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  @override
  Uint8List? get payload {
    if (ssid == null) {
      throw ArgumentError('SSID is required');
    }

    // Open networks don't require a password
    if (authenticationType != WifiAuthenticationType.open &&
        (networkKey == null || networkKey!.isEmpty)) {
      throw ArgumentError(
        'Network key is required for secured networks',
      );
    }

    final List<Uint8List> credentialData = [];

    // Network Index
    credentialData.add(
      _encodeTLV(_attrNetworkIndex, Uint8List.fromList([networkIndex])),
    );

    // SSID
    final ssidBytes = utf8.encode(ssid!);
    credentialData.add(_encodeTLV(_attrSsid, Uint8List.fromList(ssidBytes)));

    // Authentication Type
    final authTypeBytes = Uint8List(2);
    authTypeBytes[0] = (authenticationType.wscValue >> 8) & 0xFF;
    authTypeBytes[1] = authenticationType.wscValue & 0xFF;
    credentialData.add(_encodeTLV(_attrAuthType, authTypeBytes));

    // Encryption Type
    final encTypeBytes = Uint8List(2);
    encTypeBytes[0] = (encryptionType.wscValue >> 8) & 0xFF;
    encTypeBytes[1] = encryptionType.wscValue & 0xFF;
    credentialData.add(_encodeTLV(_attrEncryptionType, encTypeBytes));

    // Network Key (if not open)
    if (authenticationType != WifiAuthenticationType.open &&
        networkKey != null &&
        networkKey!.isNotEmpty) {
      final keyBytes = utf8.encode(networkKey!);
      credentialData.add(
        _encodeTLV(_attrNetworkKey, Uint8List.fromList(keyBytes)),
      );
    }

    // MAC Address (optional)
    if (macAddress != null) {
      final macBytes = _macAddressToBytes(macAddress);
      if (macBytes != null) {
        credentialData.add(_encodeTLV(_attrMacAddress, macBytes));
      }
    }

    // Combine all credential data
    final allCredentialData = <int>[];
    for (var data in credentialData) {
      allCredentialData.addAll(data);
    }

    // Create credential container with length
    final credentialLength = Uint8List(2);
    credentialLength[0] = (allCredentialData.length >> 8) & 0xFF;
    credentialLength[1] = allCredentialData.length & 0xFF;

    final credentialType = Uint8List(2);
    credentialType[0] = (_attrCredential >> 8) & 0xFF;
    credentialType[1] = _attrCredential & 0xFF;

    return Uint8List.fromList([
      ...credentialType,
      ...credentialLength,
      ...allCredentialData,
    ]);
  }

  @override
  set payload(Uint8List? payload) {
    if (payload == null || payload.isEmpty) {
      throw ArgumentError('Payload cannot be null or empty');
    }

    final stream = ByteStream(payload);

    // Read credential container
    final credentialType = stream.readInt(2);
    if (credentialType != _attrCredential) {
      throw ArgumentError(
        'Invalid WiFi record format: expected credential container',
      );
    }

    final credentialLength = stream.readInt(2);
    final endPosition = stream.readLength + credentialLength;

    // Parse attributes
    while (stream.readLength < endPosition && !stream.isEnd()) {
      final attrType = stream.readInt(2);
      final attrLength = stream.readInt(2);
      final attrValue = stream.readBytes(attrLength);

      switch (attrType) {
        case _attrSsid:
          ssid = utf8.decode(attrValue);
          break;
        case _attrNetworkKey:
          networkKey = utf8.decode(attrValue);
          break;
        case _attrAuthType:
          final authValue = (attrValue[0] << 8) | attrValue[1];
          authenticationType = WifiAuthenticationType.fromWscValue(authValue);
          break;
        case _attrEncryptionType:
          final encValue = (attrValue[0] << 8) | attrValue[1];
          encryptionType = WifiEncryptionType.fromWscValue(encValue);
          break;
        case _attrMacAddress:
          if (attrValue.length == 6) {
            macAddress = _macAddressToString(attrValue);
          }
          break;
        case _attrNetworkIndex:
          if (attrValue.isNotEmpty) {
            networkIndex = attrValue[0];
          }
          break;
      }
    }
  }
}
