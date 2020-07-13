

import 'dart:convert';

import 'record.dart';
import 'byteStream.dart';

class URIRecord extends Record{
  static const String recordType="urn:nfc:wkt:U";
  static List<String> uriPrefixMap=[
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
  
  String uriPrefix,uriData;

  URIRecord(String uriPrefix,String uriData){
    this.uriPrefix=uriPrefix;
    this.uriData=uriData;
  }

  get uri{
    return this.uriPrefix+this.uriData;
  }

  get payload{
    List<int> PAYLOAD;
    for(int i=0;i<uriPrefixMap.length;i++){
      if(uriPrefixMap[i]==uriPrefix){
        PAYLOAD=[i]+utf8.encode(uriData);
        return PAYLOAD;
      }
    }
  }

  static dynamic decode_payload(List<int> PAYLOAD){
    int uriIdentifier=PAYLOAD[0];
    String uriPrefix="";
    if(uriIdentifier<uriPrefixMap.length){
      uriPrefix=uriPrefixMap[uriIdentifier];
    }else{
      //More identifier codes are reserved for future use
      uriPrefix="";
      //uriPrefix="unknown:";
    }
    String uriData=utf8.decode(PAYLOAD.sublist(1));

    return URIRecord(uriPrefix,uriData);
  }
}


void main(){
  var res=URIRecord.decode_payload(ByteStream.decodeHexString('066e66637079'));
  print(res.uri);
}
