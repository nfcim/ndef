import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/records/well_known/well_known.dart';
import 'package:ndef/utilities.dart';

/// A NDEF Signature Record used to protect the integrity and authenticity of NDEF Messages.
class SignatureRecord extends WellKnownRecord {
  static const String classType = "Sig";

  @override
  String get decodedType {
    return SignatureRecord.classType;
  }

  static const int classMinPayloadLength = 6;

  @override
  int get minPayloadLength {
    return classMinPayloadLength;
  }

  @override
  String toString() {
    var str = "SignatureRecord: ";
    str += "signatureType=$signatureType ";
    str += "hashType=$hashType ";
    str += "signature=${signature.toHexString()} ";
    str += "signatureURI=$signatureURI ";
    str += "certificateFormat=$certificateFormat ";
    str += "certificateStore=$certificateStore ";
    str += "certificateURI=$certificateURI";
    return str;
  }

  /// The signature record version.
  static const int classVersion = 0x20;

  /// Map of supported signature types.
  static List<String?> signatureTypeMap = [
    null,
    "RSASSA-PSS-1024",
    "RSASSA-PKCS1-v1_5-1024",
    "DSA-1024",
    "ECDSA-P192",
    "RSASSA-PSS-2048",
    "RSASSA-PKCS1-v1_5-2048",
    "DSA-2048",
    "ECDSA-P224",
    "ECDSA-K233",
    "ECDSA-B233",
    "ECDSA-P256",
  ];

  /// Map of supported hash types.
  static List<String> hashTypeMap = ["", "", "SHA-256"];

  /// Map of supported certificate formats.
  static List<String> certificateFormatMap = ["X.509", "M2M"];

  /// URI for the signature.
  String? signatureURI;

  /// URI for the certificate.
  String? certificateURI;
  late List<Uint8List> _certificateStore;

  /// The signature bytes.
  late Uint8List signature;

  /// Internal index for signature type.
  late int signatureTypeIndex;

  /// Internal index for hash type.
  late int hashTypeIndex;

  /// Internal index for certificate format.
  late int certificateFormatIndex;

  /// Constructs a [SignatureRecord] with signature and certificate information.
  SignatureRecord({
    String? signatureType,
    String hashType = "SHA-256",
    Uint8List? signature,
    this.signatureURI = "",
    String certificateFormat = "X.509",
    List<Uint8List>? certificateStore,
    this.certificateURI = "",
  }) {
    this.signatureType = signatureType;
    this.hashType = hashType;
    this.signature = signature ?? Uint8List(0);
    this.certificateFormat = certificateFormat;
    _certificateStore = <Uint8List>[];
    if (certificateStore != null) {
      for (var c in certificateStore) {
        addCertificateStore(c);
      }
    }
  }

  /// Gets the signature type string.
  String? get signatureType {
    return signatureTypeMap[signatureTypeIndex];
  }

  /// Sets the signature type (must be in the signature type map).
  set signatureType(String? signatureType) {
    for (int i = 0; i < signatureTypeMap.length; i++) {
      if (signatureType == signatureTypeMap[i]) {
        signatureTypeIndex = i;
        return;
      }
    }
    throw ArgumentError(
      "Signature type $signatureType is not supported, please select one from $signatureTypeMap",
    );
  }

  /// Gets the hash type string.
  String get hashType {
    return hashTypeMap[hashTypeIndex];
  }

  /// Sets the hash type (must be in the hash type map).
  set hashType(String hashType) {
    for (int i = 0; i < hashTypeMap.length; i++) {
      if (hashType != "" && hashType == hashTypeMap[i]) {
        hashTypeIndex = i;
        return;
      }
    }
    throw ArgumentError(
      "Hash type $hashType is not supported, please select one from [, SHA-256]",
    );
  }

  /// Gets the certificate format string.
  String get certificateFormat {
    return certificateFormatMap[certificateFormatIndex];
  }

  /// Sets the certificate format (must be in the certificate format map).
  set certificateFormat(String certificateFormat) {
    for (int i = 0; i < certificateFormatMap.length; i++) {
      if (certificateFormat == certificateFormatMap[i]) {
        certificateFormatIndex = i;
        return;
      }
    }
    throw ArgumentError(
      "Certificate format $certificateFormat is not supported, please select one from $certificateFormatMap",
    );
  }

  /// Gets a copy of the certificate store.
  List<Uint8List> get certificateStore {
    return List<Uint8List>.from(_certificateStore, growable: false);
  }

  /// Adds a certificate to the certificate store.
  ///
  /// Throws [RangeError] if the certificate is too large or the store is full.
  void addCertificateStore(Uint8List certificate) {
    if (certificate.length >= 1 << 16) {
      throw RangeError.range(certificate.length, 1 << 16, null);
    }
    if (_certificateStore.length >= 1 << 4) {
      throw RangeError.range(_certificateStore.length, 1 << 4, null);
    }
    _certificateStore.add(certificate);
  }

  @override
  Uint8List get payload {
    List<int> payload;

    //Version Field pass
    //Signature Field
    int signatureURIPresent = (signatureURI == "") ? 0 : 1;
    int signatureFlag = (signatureURIPresent << 7) | signatureTypeIndex;

    var signatureURIBytes =
        signatureURIPresent == 0 ? signature : utf8.encode(signatureURI!);
    var signatureLENGTHBytes = signatureURIBytes.length.toBytes(2);
    var signatureBytes = [signatureFlag, hashTypeIndex] +
        signatureLENGTHBytes +
        signatureURIBytes;

    //Certificate Field
    int certificateURIPresent = (certificateURI == "") ? 0 : 1;
    int certificateFlag = (certificateURIPresent << 7) |
        (certificateFormatIndex << 4) |
        certificateStore.length;
    var certificateStoreBytes = <int>[];
    for (int i = 0; i < certificateStore.length; i++) {
      certificateStoreBytes.addAll(certificateStore[i].length.toBytes(2));
      certificateStoreBytes.addAll(certificateStore[i]);
    }
    var certificateURIBytes = <int>[];
    if (certificateURIPresent != 0) {
      certificateURIBytes.addAll(certificateURI!.length.toBytes(2));
      certificateURIBytes.addAll(utf8.encode(certificateURI!));
    }
    var certificateBytes = Uint8List.fromList(
      [certificateFlag] + certificateStoreBytes + certificateURIBytes,
    );

    payload = [classVersion] + (signatureBytes) + certificateBytes;
    return Uint8List.fromList(payload);
  }

  @override
  set payload(Uint8List? payload) {
    ByteStream stream = ByteStream(payload!);

    int version = stream.readByte();
    int signatureFlag = stream.readByte();
    hashTypeIndex = stream.readByte();

    //Version Field
    if (version != classVersion) {
      //TODO:find the document of smartposter 2.0
      throw ArgumentError(
        "Signature Record is only implemented for smartposter 2.0, got ${Version.formattedString(version)}",
      );
    }

    //Signature Field
    int signatureURIPresent = (signatureFlag & 0x80) >> 7;
    signatureTypeIndex = signatureFlag & 0x7F;
    int signatureURILength = stream.readInt(2);

    if (signatureURIPresent == 1) {
      signatureURI = utf8.decode(stream.readBytes(signatureURILength));
    } else {
      signature = stream.readBytes(signatureURILength);
    }

    //Certificate Field
    int certificateFlag = stream.readByte();
    int certificateURIPresent = (certificateFlag & 0x80) >> 7;
    certificateFormatIndex = (certificateFlag & 0x70) >> 4;
    int certificateNumberOfCertificates = certificateFlag & 0x0F;

    for (int i = 0; i < certificateNumberOfCertificates; i++) {
      int len = stream.readInt(2);
      certificateStore.add(stream.readBytes(len));
    }

    if (certificateURIPresent == 1) {
      int length = stream.readInt(2);
      certificateURI = utf8.decode(stream.readBytes(length));
    }
  }
}
