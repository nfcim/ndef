import 'dart:convert';
import 'dart:typed_data';

import '../record.dart';
import '../byteStream.dart';

class SignatureRecord extends Record {
  static const String recordType = "urn:nfc:wkt:Sig";

  static const String decodedType = "Sig";

  @override
  String get _decodedType {
    return SignatureRecord.decodedType;
  }

  static int version = 2;

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

  String signatureURI,
      certificateURI;
  List<Uint8List> certificateStore;
  Uint8List signature;
  int signatureTypeIndex,hashTypeIndex,certificateFormatIndex;

  SignatureRecord(
      String signatureType,
      String hashType,
      Uint8List signature,
      String signatureURI,
      String certificateFormat,
      List<Uint8List> certificateStore,
      String certificateURI) {
    this.signatureType = signatureType;
    this.hashType = hashType;
    this.signature = signature;
    this.signatureURI = signatureURI;
    this.certificateFormat = certificateFormat;
    this.certificateStore = certificateStore;
    this.certificateURI = certificateURI;
  }

  get signatureType{
    return signatureTypeMap[signatureTypeIndex];
  }

  set signatureType(String string){
    for(int i=0;i<signatureTypeMap.length;i++){
      if(string==signatureTypeMap[i]){
        signatureTypeIndex=i;
        return;
      }
    }
    throw "No signature type called $string";
  }

  get hashType {
    return hashTypeMap[hashTypeIndex];
  }

  set hashType(String string){
    for(int i=0;i<hashTypeMap.length;i++){
      if(string!="" && string==hashTypeMap[i]){
        hashTypeIndex=i;
        return;
      }
    }
    throw "No hash type called $string";
  }

  get certificateFormat {
    return certificateFormatMap[certificateFormatIndex];
  }

  set certificateFormat(String string){
    for(int i=0;i<certificateFormatMap.length;i++){
      if(string==certificateFormatMap[i]){
        certificateFormatIndex=i;
        return;
      }
    }
    throw "No certificate format called $string";
  }

  get payload {
    Uint8List payload;

    //Version Field pass
    //Signature Field
    int signatureURIPresent=(signatureURI==null)? 0:1;
    int signatureFlag = (signatureURIPresent<<7) | signatureTypeIndex;

    Uint8List signatureURIBytes=utf8.encode((signatureURI==null?signature:signatureURI));
    Uint8List signatureLenthBytes=ByteStream.int2List(signatureURIBytes.length, 2);
    Uint8List signatureBytes=[signatureFlag,hashTypeIndex]+signatureLenthBytes+signatureURIBytes;

    //Certificate Field
    int certificateURIPresent=(certificateURI==null)? 0:1;
    int certificateFlag=(certificateURIPresent<<7) | (certificateFormatIndex<<4) | certificateStore.length;
    Uint8List certificateStoreBytes=new Uint8List(0);
    for(int i=0;i<certificateStore.length;i++){
      certificateStoreBytes.addAll(ByteStream.int2List(certificateStore[i].length, 2));
      certificateStoreBytes.addAll(certificateStore[i]);
    }
    Uint8List certificateURIBytes=new Uint8List(0);
    if(certificateURI!=null){
      certificateURIBytes.addAll(ByteStream.int2List(certificateURI.length, 2));
      certificateURIBytes.addAll(utf8.encode(certificateURI));
    }
    Uint8List certificateBytes=[certificateFlag]+certificateStoreBytes+certificateURIBytes;

    payload=[version]+signatureBytes+certificateBytes;
    return payload;
  }

  set payload(Uint8List payload) {
    ByteStream stream = new ByteStream(payload);

    int version = stream.readByte(); //PAYLOAD[0];
    int signatureFlag = stream.readByte(); //PAYLOAD[1];
    hashTypeIndex = stream.readByte(); //PAYLOAD[2];

    //Version Field
    if (version != 2) {
      //TODO:find the document of smartposter 2.0
      throw "Signature Record is only implemented for smartposter 2.0";
    }

    //Signature Field
    int signatureURIPresent = (signatureFlag & 0x80)>>7;
    signatureTypeIndex = signatureFlag & 0x7F;
    int signatureURILength = stream.readInt(2);

    if (signatureURIPresent == 1)
      signatureURI = utf8.decode(stream.readBytes(signatureURILength));
    else
      signature = stream.readBytes(signatureURILength);

    //Certificate Field
    int certificateFlag = stream.readByte();
    int certificateURIPresent = (certificateFlag & 0x80)>>7;
    certificateFormatIndex=(certificateFlag & 0x70)>>4;
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
