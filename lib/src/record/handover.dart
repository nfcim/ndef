import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef/ndef.dart';

import '../record.dart';

// Handover is use to connect Wifi or bluetooth

enum CarrierPowerState { inactive, active, activating, unknown }

class AlternativeCarrierRecord extends Record {
  static const String recordType = "urn:nfc:wkt:ac";

  static const String decodedType = "ac";

  @override
  String get _decodedType {
    return AlternativeCarrierRecord.decodedType;
  }

  CarrierPowerState carrierPowerState;
  String carrierDataReference;
  List<String> auxDataReferenceList;

  AlternativeCarrierRecord({String carrierPower}) {}

  get carrierPowerStateIndex {
    return CarrierPowerState.values.indexOf(carrierPowerState);
  }

  set carrierPowerStateIndex(int carrierPowerStateIndex) {
    assert(carrierPowerStateIndex >= 0 && carrierPowerStateIndex < CarrierPowerState.values.length);
    carrierPowerState = CarrierPowerState.values[carrierPowerStateIndex];
  }

  get payload {
    Uint8List payload = new Uint8List(0);
    payload.add(carrierPowerStateIndex);

    // latin1 String and its corresponding Uint8List have the same length
    payload.add(carrierDataReference.length);
    payload.addAll(latin1.encode(carrierDataReference));

    assert(auxDataReferenceList.length < 255,
        "number of auxDataReference must be in [0,256)");

    payload.add(auxDataReferenceList.length);
    for (int i = 0; i < auxDataReferenceList.length; i++) {
      payload.add(auxDataReferenceList[i].length);
      payload.addAll(latin1.encode(auxDataReferenceList[i]));
    }

    return payload;
  }

  set payload(Uint8List payload) {
    var stream = new ByteStream(payload);

    carrierPowerStateIndex = stream.readByte() & 3;
    int carrierDataReferenceLength = stream.readByte();
    carrierDataReference =
        latin1.decode(stream.readBytes(carrierDataReferenceLength));

    int auxDataReferenceCount = stream.readByte();
    for (int i = 0; i < auxDataReferenceCount; i++) {
      int auxDataReferenceLength = stream.readByte();
      auxDataReferenceList
          .add(latin1.decode(stream.readBytes(auxDataReferenceLength)));
    }

    assert(stream.isEnd() == true,
        "payload has ${stream.unreadBytesNum} bytes after decode");
  }
}

class CollisionResolutionRecord extends Record {
  // a 16-bit random number used to resolve a collision
  static const String recordType = "urn:nfc:wkt:cr";

  static const String decodedType = "cr";

  @override
  String get _decodedType {
    return CollisionResolutionRecord.decodedType;
  }

  int _randomNumber;

  CollisionResolutionRecord({int randomNumber}){
    this.randomNumber=randomNumber;
  }

  get randomNumber {
    return _randomNumber;
  }

  set randomNumber(var randomNumber){
    if(randomNumber is Uint8List){
      randomNumber=ByteStream.List2int(randomNumber);
    }else if(!randomNumber is int){
      throw "randomNumber expects an int or Uint8List";
    }
    assert(randomNumber>=0 && randomNumber<=0xffff);
    _randomNumber=randomNumber;
  }

  get payload {
    return ByteStream.int2List(randomNumber, 2);
  }

  set payload(Uint8List payload) {
    this.randomNumber=payload;
  }
}

class ErrorRecord extends Record{
  // used in the HandoverSelectRecord
  static const String recordType = "urn:nfc:wkt:err";

  static const String decodedType = "err";
 
  static const List<String> errorReasonStrings=[
    "temporarily out of memory, may retry after {} milliseconds",
    "permanently out of memory, may retry with at most {} octets",
    "carrier specific error, may retry after {} milliseconds"
  ];

  int errorReason;

  @override
  String get _decodedType {
    return HandoverRequestRecord.decodedType;
  }

  get payload {

  }

  set payload(Uint8List payload){
    ByteStream stream = new ByteStream(payload);
    errorReason=stream.readByte();
    assert(errorReason!=0,"error reason must not be 0");
    //not finished
  }
}

class HandoverRecord extends Record {
  set payload(Uint8List payload) {}
}

class HandoverRequestRecord extends HandoverRecord {
  static const String recordType = "urn:nfc:wkt:Hr";

  static const String decodedType = "Hr";

  @override
  String get _decodedType {
    return HandoverRequestRecord.decodedType;
  }

  get payload {}

  set payload(Uint8List payload) {}
}

class HandoverSelectRecord extends HandoverRecord {}

class HandoverMediationRecord extends HandoverRecord {}

class HandoverInitiateRecord extends HandoverRecord {}

class HandoverCarrierRecord extends HandoverRecord {}
