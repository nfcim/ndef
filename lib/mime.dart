import 'record.dart';

class MIMERecord extends Record {
  static const String recordType = "media";

  String contentType;
  List<int> payload;

  MIMERecord(String contentType, List<int> payload) {
    this.contentType = contentType;
    this.payload = payload;
  }

  static dynamic decode_payload(List<int> PAYLOAD) {}
}
