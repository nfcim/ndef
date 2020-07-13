

class A{
  int b;

  A(bb){
    this.bb=bb;
  }

  set bb(value){
    print('haha');
    this.b=value;
  }
}

void main(){
  var x=new A(5);
  List<dynamic> l;
  l.add(x);
}
