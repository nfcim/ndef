import 'dart:convert';

import 'record.dart';
import 'byteStream.dart';

class SignatureRecord extends Record {
  static const String recordType = "urn:nfc:wkt:Sig";

  static List<String> signatureTypeMap = [
    "",
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

  String signatureType,
      hashType,
      signatureURI,
      certificateFormat,
      certificateURI;
  List<List<int>> certificateStore;
  List<int> signature;

  SignatureRecord(
      String signatureType,
      String hashType,
      List<int> signature,
      String signatureURI,
      String certificateFormat,
      List<List<int>> certificateStore,
      String certificateURI) {
    this.signatureType = signatureType;
    this.hashType = hashType;
    this.signature = signature;
    this.signatureURI = signatureURI;
    this.certificateFormat = certificateFormat;
    this.certificateStore = certificateStore;
    this.certificateURI = certificateURI;
  }

  static dynamic decode_payload(List<int> PAYLOAD) {
    ByteStream stream = new ByteStream(PAYLOAD);

    int version = stream.readByte(); //PAYLOAD[0];
    int signatureFlag = stream.readByte(); //PAYLOAD[1];
    int hashTypeIndex = stream.readByte(); //PAYLOAD[2];

    //Version Field
    if (version != 2) {
      //TODO:find the document of smartposter 2.0
    }

    //Signature Field
    int signatureURIPresent = signatureFlag & 0x80;
    int signatureTypeIndex = signatureFlag & 0x7F;
    String signatureType = signatureTypeMap[signatureTypeIndex];
    String hashType = hashTypeMap[hashTypeIndex];
    int signatureURILength = stream.readInt(2);

    List<int> signature;
    String signatureURI;

    if (signatureURIPresent == 1)
      signatureURI = utf8.decode(stream.readBytes(signatureURILength));
    else
      signature = stream.readBytes(signatureURILength);

    //Certificate Field
    int certificateFlag = stream.readByte();
    int certificateURIPresent = certificateFlag & 0x80;
    String certificateFormat = certificateFormatMap[certificateFlag & 0x70];
    int certificateNumberOfCertificates = certificateFlag & 0x0F;

    List<List<int>> certificateStore;
    for (int i = 0; i < certificateNumberOfCertificates; i++) {
      int length = stream.readInt(2);
      List<int> cert = stream.readBytes(length);
      certificateStore.add(cert);
    }

    String certificateURI;
    if (certificateURIPresent == 1) {
      int length = stream.readInt(2);
      certificateURI = utf8.decode(stream.readBytes(length));
    }

    return SignatureRecord(signatureType, hashType, signature, signatureURI,
        certificateFormat, certificateStore, certificateURI);
  }
}
