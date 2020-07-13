import 'byteStream.dart';
import 'record.dart';

class Message {
  List<dynamic> record_list = new List<dynamic>();

  Message(List<int> data) {
    ByteStream stream = new ByteStream(data);
    while (!stream.isEnd()) {
      dynamic a = Record.decode(stream);
      record_list.add(a);
    }
  }
}

void main() {
  Message m = new Message(ByteStream.decodeHexString('900000 500000'));
  print(m.record_list);
}
