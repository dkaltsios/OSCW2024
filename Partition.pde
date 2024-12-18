public class Partition {
  //base address
  int baseAddress;
  //size
  int size;
  //is it free?
  boolean isFree;

  Partition(int ba, int s) {
    baseAddress = ba;
    size = s;
    isFree = true;
  }
}
