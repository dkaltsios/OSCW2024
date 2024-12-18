public class UserProcess extends PCB{
  int loadTime;
  //last time it was blocked
  int blockTime;
  //time the process run its first instruction
  int startTime;
  //time the process run its last instruction
  int finishTime;
  //priority
  int priority;
  //size
  int codeSize;

  //CREATE
  UserProcess(int ba, String fn) {
    super(ba, fn);
    loadTime = -1;
    blockTime = -1;
    startTime = -1;
    priority = int(random(6));
    codeSize=0;
    for(int i=0; i<myPC.HDD.get(fn).length(); i++){
      if(myPC.HDD.get(fn).charAt(i) == '*'){
        codeSize++;
      }else break;
    }
  }
  
  //ADMIT [NEW -> READY]
  public void admit(){
    this.state = STATE.READY;  
  }
  
  //START / RESUME execution [READY -> RUN]
  public void start(){
    myOS.kernelMode = false;
    this.state = STATE.RUNNING;
    myPC.counter = this.programCounter;
    myPC.BA = this.baseAddress;
    if(startTime == -1) startTime = myPC.clock;
    myPC.interruptsEnabled = ((SchedulerKernel) myOS.kernel.get("scheduler")).isPreEmptive();
  }

  //PAUSE execution [RUN -> READY]
  public void pause(){
    this.state = STATE.READY;
    this.programCounter = myPC.counter;
  }
  
  //BLOCK [RUN -> BLOCK]
  public void block(){
    this.state = STATE.BLOCKED;
    this.programCounter = myPC.counter;
    this.blockTime = myPC.clock;
  }
  
  //COMPLETE [RUN -> TERMINATED]
  public void finish(){
     this.state = STATE.EXITING; 
     this.finishTime = myPC.clock;
     myPC.interruptsEnabled = true;
  }
  
}
