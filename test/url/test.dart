import 'package:ndef/ndef.dart';

void main() {
  UriRecord test = new UriRecord();
  test.prefix = "https://www.";
  test.content = "0x02";

  print(test.decodedType);
  print(test.minPayloadLength);
  print(test);
  print(test.basicInfoString);

}