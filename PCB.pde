public abstract class PCB {
  
  int pid; //who am I?
  STATE state; //STATE
  int baseAddress; //where in RAM am I?
  int programCounter; //how far have I progressed
  String reference; //Which program it is for

  PCB(int ba, String ref) {
    pid = pidCounter++;
    state = STATE.NEW;
    baseAddress = ba;
    programCounter=0;
    reference = ref;
  }
  
  public abstract void start();
  
  public abstract void finish();

  public String toString() {
    String result=sim.int2String(pid, 4)+" :"+sim.int2String(programCounter, 3)+" :";
    if (state == STATE.NEW)      result += "NEW    ";
    else if (state == STATE.READY) result += "READY  ";
    else if (state == STATE.RUNNING) result += "RUNNING";
    else if (state == STATE.BLOCKED) result += "BLOCKED";
    else                result += "EXITING";
    result += ": "+reference;
    return result;
  }
  
}
