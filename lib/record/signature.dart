import 'dart:convert';
import 'dart:typed_data';

import '../ndef.dart';
import 'wellknown.dart';

/// Signature Record is uesd to protect the integrity and authenticity of NDEF Messages.
class SignatureRecord extends WellKnownRecord {
  static const String classType = "Sig";

  @override
  String get decodedType {
    return SignatureRecord.classType;
  }

  static const int classMinPayloadLength = 6;

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
    str += "certificateStore=" + certificateStore.toString() + " ";
    str += "certificateURI=$certificateURI";
    return str;
  }

  static const int classVersion = 0x20;

  static List<String> signatureTypeMap = [
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
    "ECDSA-P256"
  ];

  static List<String> hashTypeMap = ["", "", "SHA-256"];

  static List<String> certificateFormatMap = ["X.509", "M2M"];

  String signatureURI, certificateURI;
  List<Uint8List> _certificateStore;
  Uint8List signature;
  int signatureTypeIndex, hashTypeIndex, certificateFormatIndex;

  SignatureRecord(
      {String signatureType,
      String hashType = "SHA-256",
      Uint8List signature,
      String signatureURI = "",
      String certificateFormat = "X.509",
      List<Uint8List> certificateStore,
      String certificateURI = ""}) {
    this.signatureType = signatureType;
    this.hashType = hashType;
    this.signature = signature != null ? signature : new Uint8List(0);
    this.signatureURI = signatureURI;
    this.certificateFormat = certificateFormat;
    this._certificateStore = new List<Uint8List>();
    if (certificateStore != null) {
      for (var c in certificateStore) {
        addCertificateStore(c);
      }
    }
    this.certificateURI = certificateURI;
  }

  String get signatureType {
    return signatureTypeMap[signatureTypeIndex];
  }

  set signatureType(String signatureType) {
    for (int i = 0; i < signatureTypeMap.length; i++) {
      if (signatureType == signatureTypeMap[i]) {
        signatureTypeIndex = i;
        return;
      }
    }
    throw "No signature type called $signatureType";
  }

  String get hashType {
    return hashTypeMap[hashTypeIndex];
  }

  set hashType(String hashType) {
    for (int i = 0; i < hashTypeMap.length; i++) {
      if (hashType != "" && hashType == hashTypeMap[i]) {
        hashTypeIndex = i;
        return;
      }
    }
    throw "No hash type called $hashType";
  }

  String get certificateFormat {
    return certificateFormatMap[certificateFormatIndex];
  }

  set certificateFormat(String certificateFormat) {
    for (int i = 0; i < certificateFormatMap.length; i++) {
      if (certificateFormat == certificateFormatMap[i]) {
        certificateFormatIndex = i;
        return;
      }
    }
    throw "No certificate format called $certificateFormat";
  }

  List<Uint8List> get certificateStore {
    return new List<Uint8List>.from(_certificateStore, growable: false);
  }

  void addCertificateStore(Uint8List certificate) {
    if (certificate.length >= 1 << 16) {
      throw "Bytes length of certificate must be < 2^16, got ${certificate.length}";
    }
    if (_certificateStore.length >= 1 << 4) {
      throw "Number of certificates in certificate store must be < 2^4, got ${_certificateStore.length}";
    }
    _certificateStore.add(certificate);
  }

  Uint8List get payload {
    var payload;

    //Version Field pass
    //Signature Field
    int signatureURIPresent = (signatureURI == "") ? 0 : 1;
    int signatureFlag = (signatureURIPresent << 7) | signatureTypeIndex;

    var signatureURIBytes =
        signatureURIPresent == 0 ? signature : utf8.encode(signatureURI);
    var signatureLenthBytes = signatureURIBytes.length.toBytes(2);
    var signatureBytes = [signatureFlag, hashTypeIndex] +
        signatureLenthBytes +
        signatureURIBytes;

    //Certificate Field
    int certificateURIPresent = (certificateURI == "") ? 0 : 1;
    int certificateFlag = (certificateURIPresent << 7) |
        (certificateFormatIndex << 4) |
        certificateStore.length;
    var certificateStoreBytes = new List<int>();
    for (int i = 0; i < certificateStore.length; i++) {
      certificateStoreBytes.addAll(certificateStore[i].length.toBytes(2));
      certificateStoreBytes.addAll(certificateStore[i]);
    }
    var certificateURIBytes = new List<int>();
    if (certificateURIPresent != 0) {
      certificateURIBytes.addAll(certificateURI.length.toBytes(2));
      certificateURIBytes.addAll(utf8.encode(certificateURI));
    }
    var certificateBytes = new Uint8List.fromList(
        [certificateFlag] + certificateStoreBytes + certificateURIBytes);

    payload = [classVersion] + signatureBytes + certificateBytes;
    return new Uint8List.fromList(payload);
  }

  set payload(Uint8List payload) {
    ByteStream stream = new ByteStream(payload);

    int version = stream.readByte();
    int signatureFlag = stream.readByte();
    hashTypeIndex = stream.readByte();

    //Version Field
    if (version != classVersion) {
      //TODO:find the document of smartposter 2.0
      throw "Signature Record is only implemented for smartposter 2.0";
    }

    //Signature Field
    int signatureURIPresent = (signatureFlag & 0x80) >> 7;
    signatureTypeIndex = signatureFlag & 0x7F;
    int signatureURILength = stream.readInt(2);

    if (signatureURIPresent == 1)
      signatureURI = utf8.decode(stream.readBytes(signatureURILength));
    else
      signature = stream.readBytes(signatureURILength);

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
