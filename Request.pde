public class Request {
  int time;
  int request;
  String filename;

  Request(int t, int k) {
    time = t;
    request = k;
    filename = "program"+request+".exe";
  }

  String toString() {
    return sim.int2String(time, 3)+" : "+request;
  }
}
