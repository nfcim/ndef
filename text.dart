

import 'dart:convert';
import 'package:utf/utf.dart' as utf;

import 'record.dart';

class TextRecord extends Record{

  static const String recordType="urn:nfc:wkt:T";

  String encoding,language,text;

  TextRecord(String encoding,String language,String text){
    this.encoding=encoding;
    this.language=language;
    this.text=text;
  }

  get payload{
    List<int> PAYLOAD;
    List<int> languagePayload=utf8.encode(language);
    List<int> textPayload;
    int encodingFlag;
    if(encoding=="UTF-8"){
      textPayload=utf8.encode(text);
      encodingFlag=0;
    }else if(encoding=="UTF-16"){
      textPayload=utf.encodeUtf16(text);
      encodingFlag=1;
    }
    int FLAG=(encodingFlag<<7) | languagePayload.length;
    PAYLOAD=[FLAG]+languagePayload+textPayload;
    
    return PAYLOAD;
  }

  static dynamic decode_payload(List<int> PAYLOAD){
    int FLAG=PAYLOAD[0];
    
    assert(FLAG&0x3F!=0,"language code length can not be zero");
    assert(FLAG&0x3F<PAYLOAD.length,"language code length exceeds payload length");

    String encoding;
    if(FLAG>>7 == 1){
      encoding="UTF-16";
    }else{
      encoding="UTF-8";
    }

    List<int> languagePayload=PAYLOAD.sublist(1,FLAG&0x3F);
    List<int> textPayload=PAYLOAD.sublist(1+FLAG&0x3F);
    String language,text;
    language=utf8.decode(languagePayload);
    if(encoding=="UTF-8"){
      text=utf8.decode(textPayload);
    }else if(encoding=="UTF-16"){
      text=utf.decodeUtf16(textPayload);
    }

    return TextRecord(encoding,language,text);
  }
}
