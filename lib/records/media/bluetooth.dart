import 'dart:typed_data';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:ndef/records/media/mime.dart';
import 'package:ndef/utilities.dart';

class _Address {
  late Uint8List addr;

  _Address({String? address}) {
    if (address != null) {
      this.address = address;
    }
  }

  _Address.fromBytes(Uint8List? bytes) {
    if (bytes != null) {
      assert(bytes.length == 6, "Bytes length of address data must be 6 bytes");
      addr = bytes;
    }
  }

  String get address {
    String address = "";
    for (int i = 0; i < 5; i++) {
      address += "${ByteUtils.byteToHexString(addr[i])}:";
    }
    address += ByteUtils.byteToHexString(addr[5]);
    return address;
  }

  set address(String address) {
    RegExp exp = RegExp(r"^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$");
    if (exp.hasMatch(address)) {
      var nums = address.split(RegExp("[-:]"));
      var bts = <int>[];
      assert(nums.length == 6);
      for (var n in nums) {
        bts.add(int.parse(n, radix: 16));
      }
      addr = Uint8List.fromList(bts);
    } else {
      throw ArgumentError("Pattern of adress string is wrong, got $address");
    }
  }
}

/// Bluetooth Easy Pairing address.
class EPAddress extends _Address {
  /// Constructs an [EPAddress] from an address string.
  EPAddress({String? address}) : super(address: address);

  /// Constructs an [EPAddress] from raw bytes.
  EPAddress.fromBytes(Uint8List bytes) : super.fromBytes(bytes);

  /// Gets the address as raw bytes.
  Uint8List get bytes {
    return addr;
  }

  @override
  String toString() {
    var str = "EPAddress: ";
    str += "address=$address";
    return str;
  }

  /// Sets the address from raw bytes.
  set bytes(Uint8List bytes) {
    if (bytes.length != 6) {
      throw ArgumentError.value(
        bytes.length,
        "Bytes length of Bluetooth LE Address must be 6",
      );
    }
    addr = bytes;
  }
}

/// Bluetooth Low Energy address type.
enum LEAddressType {
  /// Public device address.
  public,

  /// Random device address.
  random,
}

/// Bluetooth Low Energy address with type.
class LEAddress extends _Address {
  /// The address type (public or random).
  late LEAddressType type;

  /// Constructs an [LEAddress] with the specified [type] and [address].
  LEAddress({LEAddressType? type, String? address}) : super(address: address) {
    this.type = type!;
  }

  LEAddress.fromTypeBytes(LEAddressType? type, Uint8List bytes)
    : super.fromBytes(bytes) {
    this.type = type!;
  }

  LEAddress.fromBytes(Uint8List? bytes) {
    if (bytes != null) {
      this.bytes = bytes;
    }
  }

  @override
  String toString() {
    var str = "LEAddress: ";
    str += "address=$address";
    return str;
  }

  Uint8List get bytes {
    return Uint8List.fromList(addr + [LEAddressType.values.indexOf(type)]);
  }

  set bytes(Uint8List bytes) {
    if (bytes.length != 7) {
      throw ArgumentError.value(
        bytes.length,
        "Bytes length of Bluetooth LE Address must be 7",
      );
    }
    addr = bytes.sublist(0, 6);
    type = LEAddressType.values[bytes[6]];
  }
}

class DeviceClass {
  static const List<String> serviceClassNameList = [
    "Limited Discoverable Mode",
    "Reserved (bit 14)",
    "Reserved (bit 15)",
    "Positioning",
    "Networking",
    "Rendering",
    "Capturing",
    "Object Transfer",
    "Audio",
    "Telephony",
    "Information",
  ];

  static const deviceClassList = {
    0: [
      'Miscellaneous',
      [
        {'000000': 'Uncategorized'},
      ],
    ],
    1: [
      'Computer',
      [
        {
          '000000': 'Uncategorized',
          '000001': 'Desktop workstation',
          '000010': 'Server-class computer',
          '000011': 'Laptop',
          '000100': 'Handheld PC/PDA (clam shell)',
          '000101': 'Palm sized PC/PDA',
          '000110': 'Wearable computer (Watch sized)',
          '000111': 'Tablet',
        },
      ],
    ],
    2: [
      'Phone',
      [
        {
          '000000': 'Uncategorized',
          '000001': 'Cellular',
          '000010': 'Cordless',
          '000011': 'Smartphone',
          '000100': 'Wired modem or voice gateway',
          '000101': 'Common ISDN Access',
        },
      ],
    ],
    3: [
      'LAN / Network Access point',
      [
        {
          '000': 'Fully available',
          '001': '1 - 17% utilized',
          '010': '17 - 33% utilized',
          '011': '33 - 50% utilized',
          '100': '50 - 67% utilized',
          '101': '67 - 83% utilized',
          '110': '83 - 99% utilized',
          '111': 'No service available',
        },
      ],
    ],
    4: [
      'Audio / Video',
      [
        {
          '000000': 'Uncategorized',
          '000001': 'Wearable Headset Device',
          '000010': 'Hands-free Device',
          '000011': '(Reserved)',
          '000100': 'Microphone',
          '000101': 'Loudspeaker',
          '000110': 'Headphones',
          '000111': 'Portable Audio',
          '001000': 'Car audio',
          '001001': 'Set-top box',
          '001010': 'HiFi Audio Device',
          '001011': 'VCR',
          '001100': 'Video Camera',
          '001101': 'Camcorder',
          '001110': 'Video Monitor',
          '001111': 'Video Display and Loudspeaker',
          '010000': 'Video Conferencing',
          '010001': '(Reserved)',
          '010010': 'Gaming/Toy',
        },
      ],
    ],
    5: [
      'Peripheral',
      [
        {
          '00': '',
          '01': 'Keyboard',
          '10': 'Pointing device',
          '11': 'Combo keyboard/pointing device',
        },
        {
          '0000': 'Uncategorized device',
          '0001': 'Joystick',
          '0010': 'Gamepad',
          '0011': 'Remote control',
          '0100': 'Sensing device',
          '0101': 'Digitizer tablet',
          '0110': 'Card Reader',
          '0111': 'Digital Pen',
          '1000': 'Handheld scanner for ID codes',
          '1001': 'Handheld gestural input device',
        },
      ],
    ],
    6: [
      'Imaging',
      [
        {
          '0001': "Display",
          '0010': "Camera",
          '0011': "Display/Camera",
          '0100': "Scanner",
          '0101': "Display/Scanner",
          '0110': "Camera/Scanner",
          '0111': "Display/Camera/Scanner",
          '1000': "Printer",
          '1001': "Display/Printer",
          '1010': "Camera/Printer",
          '1011': "Display/Camera/Printer",
          '1100': "Scanner/Printer",
          '1101': "Display/Scanner/Printer",
          '1110': "Camera/Scanner/Printer",
          '1111': "Display/Camera/Scanner/Printer",
        },
      ],
    ],
    7: [
      'Wearable',
      [
        {
          '000001': 'Wristwatch',
          '000010': 'Pager',
          '000011': 'Jacket',
          '000100': 'Helmet',
          '000101': 'Glasses',
        },
      ],
    ],
    8: [
      "Toy",
      [
        {
          '000001': "Robot",
          '000010': "Vehicle",
          '000011': "Doll / Action figure",
          '000100': "Controller",
          '000101': "Game",
        },
      ],
    ],
    9: [
      "Health",
      [
        {
          '000000': "Undefined",
          '000001': "Blood Pressure Monitor",
          '000010': "Thermometer",
          '000011': "Weighing Scale",
          '000100': "Glucose Meter",
          '000101': "Pulse Oximeter",
          '000110': "Heart/Pulse Rate Monitor",
          '000111': "Health Data Display",
          '001000': "Step Counter",
          '001001': "Body Composition Analyzer",
          '001010': "Peak Flow Monitor",
          '001011': "Medication Monitor",
          '001100': "Knee Prosthesis",
          '001101': "Ankle Prosthesis",
          '001110': "Generic Health Manager",
          '001111': "Personal Mobility Device",
        },
      ],
    ],
    31: ['Uncategorized', []],
  };

  late int value;

  /// try to use required here indicating that value is non nullable.
  DeviceClass({required this.value});

  DeviceClass.fromBytes(Uint8List bytes) {
    this.bytes = bytes;
  }

  @override
  String toString() {
    var str = "DeviceClass: ";
    str += "majorServiceClass=$majorServiceClass ";
    str += "majorDeviceClass=$majorDeviceClass ";
    str += "minorDeviceClass=$minorDeviceClass";
    return str;
  }

  static String getServiceClassName(int index) {
    assert(
      index >= 13 && index < 24,
      "Index of Service Class Name must be in [13,24)",
    );
    return serviceClassNameList[index - 13];
  }

  List<String>? get majorServiceClass {
    if (value & 3 == 0) {
      return null;
    }
    var classes = <String>[];
    for (int i = 13; i < 24; i++) {
      if (value >> i & 1 == 1) {
        classes.add(getServiceClassName(i));
      }
    }
    return classes;
  }

  String? get majorDeviceClass {
    if (value & 3 == 0) {
      return null;
    }
    int major = (value >> 8) & 31;
    if (deviceClassList.containsKey(major)) {
      // Strong cast to String?, maybe have problems
      return deviceClassList[major]![0] as String?;
    } else {
      return 'Reserved ${major.toRadixString(2)}b';
    }
  }

  String? get minorDeviceClass {
    if (value & 3 == 0) {
      return null;
    }
    int major = (value >> 8) & 31;
    int minor = (value >> 2) & 63;
    String minorString = minor.toRadixString(2).padLeft(6, "0");
    String minorString0 = minorString;
    if (deviceClassList.containsKey(major)) {
      var text = <String>[];
      for (var mapping in deviceClassList[major]![1] as Iterable) {
        // Strong cast, MAYBE have problems
        var bits = minorString.substring(0, mapping.keys.first.length);
        if (mapping.containsKey(bits)) {
          text.add(mapping[bits]);
        } else {
          text.add('Reserved ${minorString0}b');
        }
        minorString = minorString.substring(bits.length);
      }
      var res = "";
      for (var i = 0; i < text.length - 1; i++) {
        res += ('${text[i]} and ');
      }
      res += text.last;
      return res;
    } else {
      return "Undefined ${minor.toRadixString(2)}b";
    }
  }

  Uint8List get bytes {
    return ByteUtils.intToBytes(value, 3, endianness: Endianness.Little);
  }

  set bytes(Uint8List bytes) {
    if (bytes.length != 3) {
      throw ArgumentError.value(
        bytes.length,
        "Bytes length of Class of Device must be 3",
      );
    }
    value = ByteUtils.bytesToInt(bytes, endianness: Endianness.Little);
  }
}

class ServiceClass {
  static const String baseUuid = "-0000-1000-8000-00805F9B34FB";

  static const Map<int, String> uuidNameMap = {
    0x00001000: "Service Discovery Server",
    0x00001001: "Browse Group Descriptor",
    0x00001101: "Serial Port",
    0x00001102: "LAN Access Using PPP",
    0x00001103: "Dialup Networking",
    0x00001104: "IrMC Sync",
    0x00001105: "OBEX Object Push",
    0x00001106: "OBEX File Transfer",
    0x00001107: "IrMC Sync Command",
    0x00001108: "Headset",
    0x00001109: "Cordless Telephony",
    0x0000110a: "Audio Source",
    0x0000110b: "Audio Sink",
    0x0000110c: "A/V Remote Control Target",
    0x0000110d: "Advanced Audio Distribution",
    0x0000110e: "A/V Remote Control",
    0x0000110f: "A/V Remote Control Controller",
    0x00001110: "Intercom",
    0x00001111: "Fax",
    0x00001112: "Headset - Audio Gateway (AG)",
    0x00001113: "WAP",
    0x00001114: "WAP Client",
    0x00001115: "PANU",
    0x00001116: "NAP",
    0x00001117: "GN",
    0x00001118: "Direct Printing",
    0x00001119: "Reference Printing",
    0x0000111a: "Basic Imaging Profile",
    0x0000111b: "Imaging Responder",
    0x0000111c: "Imaging Automatic Archive",
    0x0000111d: "Imaging Referenced Objects",
    0x0000111e: "Handsfree",
    0x0000111f: "Handsfree Audio Gateway",
    0x00001120: "Direct Printing Reference",
    0x00001121: "Reflected UI",
    0x00001122: "Basic Printing",
    0x00001123: "Printing Status",
    0x00001124: "Human Interface Device",
    0x00001125: "Hardcopy Cable Replacement",
    0x00001126: "HCR Print",
    0x00001127: "HCR Scan",
    0x00001128: "Common ISDN Access",
    0x0000112d: "SIM Access",
    0x0000112e: "Phonebook Access - PCE",
    0x0000112f: "Phonebook Access - PSE",
    0x00001130: "Phonebook Access",
    0x00001131: "Headset - HS",
    0x00001132: "Message Access Server",
    0x00001133: "Message Notification Server",
    0x00001134: "Message Access Profile",
    0x00001135: "GNSS",
    0x00001136: "GNSS Server",
    0x00001200: "PnP Information",
    0x00001201: "Generic Networking",
    0x00001202: "Generic File Transfer",
    0x00001203: "Generic Audio",
    0x00001204: "Generic Telephony",
    0x00001205: "UPNP Service",
    0x00001206: "UPNP IP Service",
    0x00001300: "ESDP UPNP IP PAN",
    0x00001301: "ESDP UPNP IP LAP",
    0x00001302: "ESDP UPNP L2CAP",
    0x00001303: "Video Source",
    0x00001304: "Video Sink",
    0x00001305: "Video Distribution",
    0x00001400: "HDP",
    0x00001401: "HDP Source",
    0x00001402: "HDP Sink",
  };

  late Uint8List _uuidData;

  /// uuidData is non nullable, so use required keyword here.
  ServiceClass({required Uint8List uuidData}) {
    this.uuidData = uuidData;
  }

  @override
  String toString() {
    var str = "ServiceClass: ";
    str += "uuid=$uuid";
    return str;
  }

  String get uuid {
    if (bytes.length == 2) {
      return "0000${bytes.toReverse().toHexString()}$baseUuid";
    } else if (bytes.length == 4) {
      return bytes.toReverse().toHexString() + baseUuid;
    } else {
      return Uuid.unparse(uuidData);
    }
  }

  /// UUID name if supported or UUID
  String? get name {
    if (bytes.length <= 4 || uuid.substring(8) == baseUuid) {
      var v = _uuidValue;
      if (uuidNameMap.containsKey(v)) {
        return uuidNameMap[v];
      }
    }
    return uuid;
  }

  Uint8List get uuidData {
    return _uuidData;
  }

  int get _uuidValue {
    return _uuidData.toInt(endianness: Endianness.Little);
  }

  set uuidData(Uint8List uuidData) {
    if (bytes.length == 2 || bytes.length == 4 || bytes.length == 16) {
      _uuidData = bytes;
    } else {
      throw ArgumentError.value(
        bytes.length,
        "Bytes length of uuidData must be 2, 4, or 16",
      );
    }
  }

  Uint8List get bytes {
    return _uuidData;
  }

  set bytes(Uint8List bytes) {
    uuidData = bytes;
  }
}

enum EIRType {
  Zero,
  Flags,
  Inc16BitUUID,
  Com16BitUUID,
  Inc32BitUUID,
  Com32BitUUID,
  Inc128BitUUID,
  Com128BitUUID,
  ShortenedLocalName,
  CompleteLocalName,
  TXPowerLevel,
  ClassOfDevice,
  SimplePairingHashC192,
  SimplePairingRandomizerR192,
  SimplePairingHashC256,
  SimplePairingRandomizerR256,
  SecurityManagerTKValue,
  SecurityManagerOutOfBandFlags,
  SlaveConnectionIntervalRange,
  SS16BitUUID,
  SS32BitUUID,
  SS128BitUUID,
  ServiceData16Bit,
  ServiceData32Bit,
  ServiceData128Bit,
  Appearance,
  PublicTargetAddress,
  RandomTargetAddress,
  AdvertisingInterval,
  LESecureConnectionsConfirmationValue,
  LESecureConnectionsRandomValue,
  LEBluetoothDeviceAddress,
  LERole,
  URI,
  LESupportedFeatures,
  ChannelMapUpdateIndication,
  ManufacturerSpecificData,
}

class EIR {
  static const Map<int, EIRType> numTypeMap = {
    0x00: EIRType.Zero,
    0x01: EIRType.Flags,
    0x02: EIRType.Inc16BitUUID,
    0x03: EIRType.Com16BitUUID,
    0x04: EIRType.Inc32BitUUID,
    0x05: EIRType.Com32BitUUID,
    0x06: EIRType.Inc128BitUUID,
    0x07: EIRType.Com128BitUUID,
    0x08: EIRType.ShortenedLocalName,
    0x09: EIRType.CompleteLocalName,
    0x0D: EIRType.ClassOfDevice,
    0x0E: EIRType.SimplePairingHashC192,
    0x0F: EIRType.SimplePairingRandomizerR192,
    0x10: EIRType.SecurityManagerTKValue,
    0x11: EIRType.SecurityManagerOutOfBandFlags,
    0x19: EIRType.Appearance,
    0x1B: EIRType.LEBluetoothDeviceAddress,
    0x1C: EIRType.LERole,
    0x1D: EIRType.SimplePairingHashC256,
    0x1E: EIRType.SimplePairingRandomizerR256,
    0x22: EIRType.LESecureConnectionsConfirmationValue,
    0x23: EIRType.LESecureConnectionsRandomValue,
    0x24: EIRType.URI,
    0x28: EIRType.ChannelMapUpdateIndication,
    0xFF: EIRType.ManufacturerSpecificData,
  };

  static const Map<EIRType, int> typeNumMap = {
    EIRType.Zero: 0x00,
    EIRType.Flags: 0x01,
    EIRType.Inc16BitUUID: 0x02,
    EIRType.Com16BitUUID: 0x03,
    EIRType.Inc32BitUUID: 0x04,
    EIRType.Com32BitUUID: 0x05,
    EIRType.Inc128BitUUID: 0x06,
    EIRType.Com128BitUUID: 0x07,
    EIRType.ShortenedLocalName: 0x08,
    EIRType.CompleteLocalName: 0x09,
    EIRType.ClassOfDevice: 0x0D,
    EIRType.SimplePairingHashC192: 0x0E,
    EIRType.SimplePairingRandomizerR192: 0x0F,
    EIRType.SecurityManagerTKValue: 0x10,
    EIRType.SecurityManagerOutOfBandFlags: 0x11,
    EIRType.Appearance: 0x19,
    EIRType.LEBluetoothDeviceAddress: 0x1B,
    EIRType.LERole: 0x1C,
    EIRType.SimplePairingHashC256: 0x1D,
    EIRType.SimplePairingRandomizerR256: 0x1E,
    EIRType.LESecureConnectionsConfirmationValue: 0x22,
    EIRType.LESecureConnectionsRandomValue: 0x23,
    EIRType.URI: 0x24,
    EIRType.ChannelMapUpdateIndication: 0x28,
    EIRType.ManufacturerSpecificData: 0xFF,
  };

  static const Map<EIRType, String> typeNameMap = {
    EIRType.Zero: "Zero",
    EIRType.Flags: "Flags",
    EIRType.Inc16BitUUID: "Incomplete List of 16-bit Service UUIDs",
    EIRType.Com16BitUUID: "Complete List of 16-bit Service UUIDs",
    EIRType.Inc32BitUUID: "Incomplete List of 32-bit Service UUIDs",
    EIRType.Com32BitUUID: "Complete List of 32-bit Service UUIDs",
    EIRType.Inc128BitUUID: "Incomplete List of 128-bit Service UUIDs",
    EIRType.Com128BitUUID: "Complete List of 128-bit Service UUIDs",
    EIRType.ShortenedLocalName: "Shortened Local Name",
    EIRType.CompleteLocalName: "Complete Local Name",
    EIRType.ClassOfDevice: "Class of Device",
    EIRType.SimplePairingHashC192: "Simple Pairing Hash C-192",
    EIRType.SimplePairingRandomizerR192: "Simple Pairing Randomizer R-192",
    EIRType.SecurityManagerTKValue: "Security Manager TK Value",
    EIRType.SecurityManagerOutOfBandFlags: "Security Manager Out of Band Flags",
    EIRType.Appearance: "Appearance",
    EIRType.LEBluetoothDeviceAddress: "LE Bluetooth Device Address",
    EIRType.LERole: "LE Role",
    EIRType.SimplePairingHashC256: "Simple Pairing Hash C-256",
    EIRType.SimplePairingRandomizerR256: "Simple Pairing Randomizer R-256",
    EIRType.LESecureConnectionsConfirmationValue:
        "LE Secure Connections Confirmation Value",
    EIRType.LESecureConnectionsRandomValue:
        "LE Secure Connections Random Value",
    EIRType.URI: "URI",
    EIRType.ChannelMapUpdateIndication: "Channel Map Update Indication",
    EIRType.ManufacturerSpecificData: "Manufacturer Specific Data",
  };

  int? _typeNum;
  late Uint8List data;

  EIR({EIRType? type, Uint8List? data}) {
    if (type != null) {
      this.type = type;
    }
    if (data != null) {
      this.data = data;
    }
  }

  EIR.fromTypeNum(int typeNum, this.data) {
    this.typeNum = typeNum;
  }

  EIR.fromBytes(Uint8List bytes) {
    this.bytes = bytes;
  }

  Uint8List get bytes {
    return ([typeNum] + data) as Uint8List; // Strong cast, MAYBE have problems.
  }

  set bytes(Uint8List bytes) {
    typeNum = bytes[0];
    data = bytes.sublist(1);
  }

  int? get typeNum {
    return _typeNum;
  }

  set typeNum(int? typeNum) {
    if (!numTypeMap.containsKey(typeNum)) {
      throw ArgumentError("EIR type Number $typeNum is not supported");
    }
    _typeNum = typeNum;
  }

  String? get typeString {
    return typeNum == null ? null : typeNameMap[type];
  }

  EIRType? get type {
    return typeNum == null ? null : numTypeMap[typeNum];
  }

  set type(EIRType? type) {
    for (var entry in numTypeMap.entries) {
      if (type == entry.value) {
        typeNum = entry.key;
        break;
      }
    }
    if (typeNum == null) {
      throw ArgumentError(
        "EIR type $type is not supported, please select one from ${EIRType.values}",
      );
    }
  }
}

/// Base class for Bluetooth NDEF records.
///
/// Contains Extended Inquiry Response (EIR) data attributes for Bluetooth pairing.
class BluetoothRecord extends MimeRecord {
  /// Map of EIR type to data attributes.
  late Map<EIRType?, Uint8List> attributes;

  /// Constructs a [BluetoothRecord] with optional [attributes].
  BluetoothRecord({Map<EIRType, Uint8List>? attributes}) {
    this.attributes = attributes ?? <EIRType, Uint8List>{};
  }

  /// Gets the attribute value for the specified EIR [type].
  Uint8List? getAttribute(EIRType type) {
    return attributes.containsKey(type) ? attributes[type] : null;
  }

  /// Sets the attribute [value] for the specified EIR [type].
  void setAttribute(EIRType? type, Uint8List value) {
    if (!EIR.typeNumMap.containsKey(type)) {
      throw ArgumentError(
        "EIR type $type is not supported, please select one from ${EIRType.values}",
      );
    }
    attributes[type!] = value;
  }

  /// Gets the Bluetooth device name.
  String get deviceName {
    if (attributes.containsKey(EIRType.CompleteLocalName)) {
      return utf8.decode(attributes[EIRType.CompleteLocalName]!);
    } else if (attributes.containsKey(EIRType.ShortenedLocalName)) {
      return utf8.decode(attributes[EIRType.ShortenedLocalName]!);
    } else {
      return "";
    }
  }

  /// Sets the Bluetooth device name.
  set deviceName(String deviceName) {
    attributes[EIRType.CompleteLocalName] = utf8.encode(deviceName);
    if (attributes.containsKey(EIRType.ShortenedLocalName)) {
      attributes.remove(EIRType.ShortenedLocalName);
    }
  }

  /// Gets an integer value for the specified EIR [type].
  BigInt getIntValue(EIRType type) {
    return ByteUtils.bytesToBigInt(
      attributes[type]!,
      endianness: Endianness.Little,
    );
  }

  /// Sets an integer [value] for the specified EIR [type].
  void setIntValue(EIRType type, BigInt value) {
    setAttribute(
      type,
      ByteUtils.bigIntToBytes(value, 16, endianness: Endianness.Little),
    );
  }
}

/// A NDEF record for Bluetooth Easy Pairing (Secure Simple Pairing).
///
/// Contains Bluetooth device information for out-of-band pairing.
class BluetoothEasyPairingRecord extends BluetoothRecord {
  /// The MIME type for Bluetooth Easy Pairing records.
  static const String classType = "application/vnd.bluetooth.ep.oob";

  @override
  String get decodedType {
    return BluetoothEasyPairingRecord.classType;
  }

  @override
  String toString() {
    var str = "BluetoothEasyPairingRecord: ";
    str += "address=${address!.address} ";
    str += "name=$deviceName ";
    str += "attributes=$attributes";
    return str;
  }

  /// Constructs a [BluetoothEasyPairingRecord] with optional [address] and [attributes].
  BluetoothEasyPairingRecord({
    this.address,
    Map<EIRType, Uint8List>? attributes,
  }) : super(attributes: attributes);

  /// The Bluetooth device address.
  EPAddress? address;

  /// Gets the Bluetooth device class.
  DeviceClass get deviceClass {
    return DeviceClass.fromBytes(attributes[EIRType.ClassOfDevice]!);
  }

  /// Sets the Bluetooth device class.
  set deviceClass(DeviceClass dc) {
    attributes[EIRType.ClassOfDevice] = dc.bytes;
  }

  void _addServiceClassList(
    EIRType eirType,
    int unitSize,
    List<ServiceClass> list,
  ) {
    if (attributes.containsKey(eirType)) {
      var bytes = attributes[eirType];
      for (var i = 0; i < bytes!.length; i += unitSize) {
        list.add(ServiceClass(uuidData: bytes.sublist(i, i + unitSize)));
      }
    }
  }

  /// Gets the list of service class UUIDs.
  List<ServiceClass> get serviceClassList {
    var list = <ServiceClass>[];
    _addServiceClassList(EIRType.Inc16BitUUID, 2, list);
    _addServiceClassList(EIRType.Com16BitUUID, 2, list);
    _addServiceClassList(EIRType.Inc32BitUUID, 4, list);
    _addServiceClassList(EIRType.Com32BitUUID, 4, list);
    _addServiceClassList(EIRType.Inc128BitUUID, 16, list);
    _addServiceClassList(EIRType.Com128BitUUID, 16, list);
    return list;
  }

  /// Adds a service class UUID, with [complete] indicating if the list is complete.
  void addServiceClass(ServiceClass serviceClass, {bool complete = false}) {
    var bytes = serviceClass.bytes;
    late EIRType remain, remove;
    if (bytes.length == 2) {
      if (complete == false) {
        remain = EIRType.Inc16BitUUID;
        remove = EIRType.Com16BitUUID;
      } else {
        remain = EIRType.Com16BitUUID;
        remove = EIRType.Inc16BitUUID;
      }
    } else if (bytes.length == 4) {
      if (complete == false) {
        remain = EIRType.Inc32BitUUID;
        remove = EIRType.Com32BitUUID;
      } else {
        remain = EIRType.Com32BitUUID;
        remove = EIRType.Inc32BitUUID;
      }
    } else if (bytes.length == 16) {
      if (complete == false) {
        remain = EIRType.Inc128BitUUID;
        remove = EIRType.Com128BitUUID;
      } else {
        remain = EIRType.Com128BitUUID;
        remove = EIRType.Inc128BitUUID;
      }
    }

    attributes[remain] = Uint8List.fromList(
      (attributes.containsKey(remain) ? attributes[remain] : [])! +
              (attributes.containsKey(remove) ? attributes[remove]! : []) +
              bytes
          as List<int>,
    );
    if (attributes.containsKey(remove)) {
      attributes.remove(remove);
    }
  }

  BigInt get simplePairingHash192 {
    return getIntValue(EIRType.SimplePairingHashC192);
  }

  set simplePairingHash192(BigInt value) {
    setIntValue(EIRType.SimplePairingHashC192, value);
  }

  BigInt get simplePairingRandomizer192 {
    return getIntValue(EIRType.SimplePairingRandomizerR192);
  }

  set simplePairingRandomizer192(BigInt value) {
    setIntValue(EIRType.SimplePairingRandomizerR192, value);
  }

  BigInt get simplePairingHash256 {
    return getIntValue(EIRType.SimplePairingHashC192);
  }

  set simplePairingHash256(BigInt value) {
    setIntValue(EIRType.SimplePairingHashC192, value);
  }

  BigInt get simplePairingRandomizer256 {
    return getIntValue(EIRType.SimplePairingRandomizerR192);
  }

  set simplePairingRandomizer256(BigInt value) {
    setIntValue(EIRType.SimplePairingRandomizerR192, value);
  }

  @override
  Uint8List get payload {
    List<int?> data = <int?>[];
    for (var e in attributes.entries) {
      data.add(e.value.length + 1);
      data.add(EIR.typeNumMap[e.key]);
      data.addAll(e.value);
    }
    List<int>? payload =
        ByteUtils.intToBytes(
          data.length + address!.bytes.length + 2,
          2,
          endianness: Endianness.Little,
        ) +
        address!.bytes +
        data.cast();
    return Uint8List.fromList(payload);
  }

  @override
  set payload(Uint8List? payload) {
    var stream = ByteStream(payload!);
    var oobLength = stream.readInt(2, endianness: Endianness.Little);
    address = EPAddress.fromBytes(stream.readBytes(6));
    while (stream.readLength < oobLength) {
      var length = stream.readByte();
      var data = stream.readBytes(length);
      attributes[EIR.numTypeMap[data[0]]] = data.sublist(1);
    }
  }
}

/// A NDEF record for Bluetooth Low Energy out-of-band pairing.
///
/// Contains Bluetooth LE device information for pairing.
class BluetoothLowEnergyRecord extends BluetoothRecord {
  /// The MIME type for Bluetooth Low Energy records.
  static const String classType = "application/vnd.bluetooth.le.oob";

  @override
  String get decodedType {
    return BluetoothLowEnergyRecord.classType;
  }

  @override
  String toString() {
    var str = "BluetoothLowEnergyRecord: ";
    str += "address=${address?.address ?? '(null)'} ";
    str += "name=$deviceName ";
    str += "attributes=$attributes";
    return str;
  }

  /// Constructs a [BluetoothLowEnergyRecord] with optional [attributes].
  BluetoothLowEnergyRecord({Map<EIRType, Uint8List>? attributes})
    : super(attributes: attributes);

  /// Gets the Bluetooth LE device address.
  LEAddress? get address {
    if (attributes.containsKey(EIRType.LEBluetoothDeviceAddress)) {
      return LEAddress.fromBytes(attributes[EIRType.LEBluetoothDeviceAddress]);
    } else {
      return null;
    }
  }

  set address(LEAddress? address) {
    attributes[EIRType.LEBluetoothDeviceAddress] = address!.bytes;
  }

  static const List<String> leRoleList = [
    "Peripheral",
    "Central",
    "Peripheral/Central",
    "Central/Peripheral",
  ];

  String? get roleCapabilities {
    if (attributes.containsKey(EIRType.LERole)) {
      assert(
        attributes[EIRType.LERole]!.length == 1,
        "Bytes length of LE Role must be 1",
      );
      var index = attributes[EIRType.LERole]![0];
      if (index < leRoleList.length) {
        return leRoleList[index];
      } else {
        return "Reserved 0x${index.toRadixString(16)}";
      }
    } else {
      return null;
    }
  }

  set roleCapabilities(String? value) {
    if (leRoleList.contains(value)) {
      int index = leRoleList.indexOf(value!);
      var bytes = <int>[0];
      bytes.add(index);
      attributes[EIRType.LERole] = Uint8List.fromList(bytes);
    } else {
      throw ArgumentError("Role capability $value is undefined");
    }
  }

  static const Map<int, String> appearanceMap = {
    0x0000: "Unknown",
    0x0040: "Phone",
    0x0080: "Computer",
    0x00c0: "Watch",
    0x00c1: "Watch: Sports Watch",
    0x0100: "Clock",
    0x0140: "Display",
    0x0180: "Remote Control",
    0x01c0: "Eye-glasses",
    0x0200: "Tag",
    0x0240: "Keyring",
    0x0280: "Media Player",
    0x02c0: "Barcode Scanner",
    0x0300: "Thermometer",
    0x0301: "Thermometer: Ear",
    0x0340: "Heart Rate Sensor",
    0x0341: "Heart Rate Sensor: Belt",
    0x0380: "Blood Pressure",
    0x0381: "Blood Pressure: Arm",
    0x0382: "Blood Pressure: Wrist",
    0x03c0: "Human Interface Device",
    0x03c1: "Human Interface Device: Keyboard",
    0x03c2: "Human Interface Device: Mouse",
    0x03c3: "Human Interface Device: Joystick",
    0x03c4: "Human Interface Device: Gamepad",
    0x03c5: "Human Interface Device: Digitizer Tablet",
    0x03c6: "Human Interface Device: Card Reader",
    0x03c7: "Human Interface Device: Digital Pen",
    0x03c8: "Human Interface Device: Barcode Scanner",
    0x0400: "Glucose Meter",
    0x0440: "Running Walking Sensor",
    0x0441: "Running Walking Sensor: In-Shoe",
    0x0442: "Running Walking Sensor: On-Shoe",
    0x0443: "Running Walking Sensor: On-Hip",
    0x0480: "Cycling",
    0x0481: "Cycling: Cycling Computer",
    0x0482: "Cycling: Speed Sensor",
    0x0483: "Cycling: Cadence Sensor",
    0x0484: "Cycling: Power Sensor",
    0x0485: "Cycling: Speed and Cadence Sensor",
    0x0c40: "Pulse Oximeter",
    0x0c41: "Pulse Oximeter: Fingertip",
    0x0c42: "Pulse Oximeter: Wrist Worn",
    0x0c80: "Weight Scale",
    0x1440: "Outdoor Sports",
    0x1441: "Outdoor Sports: Location Display Device",
    0x1442: "Outdoor Sports: Location and Navigation Display Device",
    0x1443: "Outdoor Sports: Location Pod",
    0x1444: "Outdoor Sports: Location and Navigation Pod",
  };

  String? get appearance {
    if (attributes.containsKey(EIRType.Appearance)) {
      assert(
        attributes[EIRType.Appearance]!.length == 4,
        "Bytes length of appearance must be 4",
      );
      int? value = ByteUtils.bytesToInt(
        attributes[EIRType.Appearance],
        endianness: Endianness.Little,
      );
      if (appearanceMap.containsKey(value)) {
        return appearanceMap[value];
      } else {
        return "";
      }
    } else {
      return null;
    }
  }

  set appearance(String? appearance) {
    int? index;
    for (var e in appearanceMap.entries) {
      if (e.value == appearance) {
        index = e.key;
        break;
      }
    }
    if (index == null) {
      throw ArgumentError.notNull("Appearance $appearance is not correct");
    }
    attributes[EIRType.Appearance] = ByteUtils.intToBytes(
      index,
      4,
      endianness: Endianness.Little,
    );
  }

  static const flagsList = [
    "LE Limited Discoverable Mode",
    "LE General Discoverable Mode",
    "BR/EDR Not Supported",
    "Simultaneous LE and BR/EDR to Same Device Capable (Controller)",
    "Simultaneous LE and BR/EDR to Same Device Capable (Host)",
  ];

  List<String>? get flagsEIR {
    if (attributes.containsKey(EIRType.Flags)) {
      var names = <String>[];
      var value = attributes[EIRType.Flags]![0];
      for (var i = 0; i < flagsList.length; i++) {
        if (value >> i & 1 == 1) {
          names.add(flagsList[i]);
        }
      }
      return names;
    } else {
      return null;
    }
  }

  set flagsEIR(List<String>? flags) {
    int value = 0;
    for (int i = 0; i < flags!.length; i++) {
      if (!flagsList.contains(flags[i])) {
        throw ArgumentError("Flag ${flags[i]} is not correct");
      }
      value += 1 << flagsList.indexOf(flags[i]);
    }
    attributes[EIRType.Flags] = Uint8List.fromList([value]);
  }

  BigInt get securityManagerTKValue {
    return getIntValue(EIRType.SecurityManagerTKValue);
  }

  set securityManagerTKValue(BigInt value) {
    setIntValue(EIRType.SecurityManagerTKValue, value);
  }

  BigInt get leSecureConnectionsConfirmationValue {
    return getIntValue(EIRType.LESecureConnectionsConfirmationValue);
  }

  set leSecureConnectionsConfirmationValue(BigInt value) {
    setIntValue(EIRType.LESecureConnectionsConfirmationValue, value);
  }

  BigInt get leSecureConnectionsRandomValue {
    return getIntValue(EIRType.LESecureConnectionsRandomValue);
  }

  set leSecureConnectionsRandomValue(BigInt value) {
    setIntValue(EIRType.LESecureConnectionsRandomValue, value);
  }

  @override
  Uint8List? get payload {
    Uint8List? payload = <int?>[] as Uint8List;
    for (var e in attributes.entries) {
      payload.add(e.value.length + 1);
      payload.add(EIR.typeNumMap[e.key!]!);
      payload.addAll(e.value);
    }
    return Uint8List.fromList(payload);
  }

  @override
  set payload(Uint8List? payload) {
    var stream = ByteStream(payload!);
    while (!stream.isEnd()) {
      var length = stream.readByte();
      var data = stream.readBytes(length);
      attributes[EIR.numTypeMap[data[0]]] = data.sublist(1);
    }
  }
}
