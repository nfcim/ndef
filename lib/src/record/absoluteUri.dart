import '../record.dart';

class absoluteUriRecord extends Record {
  static const String recordType = "absoluteURI";

  String uri;

  absoluteUriRecord(this.uri);
}
