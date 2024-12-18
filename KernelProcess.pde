public abstract class KernelProcess extends PCB{
  String code;
  char completeInstruction;
  int IRQnum;
    
  KernelProcess(String name, String c, int IRQ){
    super(0, name);  
    IRQnum = IRQ;
    code = c;
    completeInstruction = code.charAt(code.length()-1);
    state = STATE.READY;
  }
   
  public void start(){
    myOS.kernelMode = true;
    myPC.interruptsEnabled = false;
    this.state = STATE.RUNNING;
    myPC.counter = 0;
    myPC.BA = this.baseAddress;  
    myOS.active = this;
  }
  
  public void setIRQ(boolean value){
    myPC.IRQ[IRQnum] = value;  
  }
  
  public String compileTo(String kernelImage){
    this.baseAddress = kernelImage.length();
    return kernelImage + code;
  }
  
}

///////////////////////////////////////////////////////////
public class IdleKernel extends KernelProcess{
    
  IdleKernel(String name, String code, int IRQ){
    super(name, code, IRQ);
  }
  
  //Overwrite default start to enable interrupts
  public void start(){
    super.start();
    myPC.interruptsEnabled = true; 
  }
  
  public void finish(){
    myPC.counter = 0;
  }
  
}

///////////////////////////////////////////////////////////
public class MemoryManagerKernel extends KernelProcess{
  
  MemoryManagerAlgorithm algorithm;
  
  MemoryManagerKernel(String name, String code, int IRQ, MemoryManagerAlgorithm mm){
    super(name, code, IRQ);
    algorithm = mm;
  }
  
  //Overwrite default start to suspent user processes
  //If the scheduler is non preemtive, the active process
  //can never be a user process
  public void start(){
    if (myOS.active instanceof UserProcess ) {
      sim.addToLog(" >MyOS: suspending process "+myOS.active.pid);
      myOS.suspended = (UserProcess) myOS.active;
      myOS.suspended.pause();
      myOS.readyQueue.add(myOS.suspended);
      sim.addToLog(" >MyOS: adding suspended process ("+myOS.active.pid+") to ready queue");
    }else {
      myOS.kernel.get("idle").state=STATE.READY;
    }
    super.start();
  }
  
  public void finish(){
    myOS.newProcessImage = myPC.HDD.get(myOS.request)+myOS.processTail;
    myOS.partitionFound = algorithm.selectPartition();
    this.state = STATE.READY;
    myPC.interruptsEnabled = true;
  }
  
}

///////////////////////////////////////////////////////////////
public class CreateProcessKernel extends KernelProcess{
  
  CreateProcessKernel(String name, String code, int IRQ){
    super(name, code, IRQ);
  }
  
  public void finish(){
    myOS.newProcess = new UserProcess(myOS.partitionFound.baseAddress, myOS.request);
    myOS.processTable.add(myOS.newProcess);
    myOS.writeToPartition(myOS.partitionFound, myOS.newProcessImage);
    sim.addToLog("  >Process Creator: process with PID "+myOS.newProcess.pid+" created at partition "+ myOS.partitionTable.indexOf(myOS.partitionFound)+" (BA "+myOS.partitionFound.baseAddress+"). Starting process admitter");
    myOS.raiseIRQ("admitProcess");
    this.state = STATE.READY;
    myPC.interruptsEnabled = true;
  }
}

///////////////////////////////////////////////////////////////
public class AdmitProcessKernel extends KernelProcess{
  
  AdmitProcessKernel(String name, String code, int IRQ){
    super(name, code, IRQ); 
  }
  
  public void finish(){
    this.state = STATE.READY;
    myOS.newProcess.state = STATE.READY;
    myOS.newProcess.loadTime = myPC.clock;
    myOS.readyQueue.add(myOS.newProcess);
    sim.addToLog("  >Process Admitter: Admitted process "+ myOS.newProcess.pid+ " to the readyQueue. Starting Scheduler");
    myOS.raiseIRQ("scheduler");
    myPC.interruptsEnabled = true;
  }
  
}

///////////////////////////////////////////////////////////////
public class SchedulerKernel extends KernelProcess{
  private ShortTermScheduler scheduler;
  
  SchedulerKernel(String name, String code, int IRQ, ShortTermScheduler sc){
    super(name, code, IRQ);
    scheduler = sc;
  }
  
  public boolean isPreEmptive(){
    boolean result = scheduler.type == SDLRTYPE.PREEMPTIVE;
    return result;
  }
  
  public void finish(){
    myOS.active = scheduler.selectUserProcess();
    if(myOS.active == null){
      sim.addToLog("  >Scheduler: ready queue is empty. Switching to IDLE");
      myOS.raiseIRQ("idle");
      myPC.interruptsEnabled = true;
    }else{
      sim.addToLog("  >Scheduler: selected from the ready queue process "+myOS.active.pid);
      myOS.readyQueue.remove(myOS.active);
      myPC.interruptsEnabled = isPreEmptive();
    }
    if(myOS.active!=null) myOS.active.start();
    myOS.kernelMode = false;
    this.state = STATE.READY;
  }
}

///////////////////////////////////////////////////////////////
public class ExitProcessKernel extends KernelProcess{
  
  ExitProcessKernel(String name, String code, int IRQ){
    super(name, code, IRQ);
  }
  
  public void finish(){
    myOS.emptyPartition(myOS.deleteProcess.baseAddress);
    myOS.processTable.remove(myOS.deleteProcess);
    sim.addToLog("  >Exit: finished exiting process "+myOS.deleteProcess.pid+". Starting scheduler");
    myOS.deleteProcess = null;
    myOS.startKernelProcess("scheduler");
    this.state = STATE.READY;
  }
  
}
////////////////////////////////////////////////////////////////

 public class CoalesceKernel extends KernelProcess{
   //private int deleteProcessBA;
   CoalesceKernel(String name, String code, int IRQ) {
     super(name, code, IRQ);
     //deleteProcessBA = ba;
   }
   /*
   public void finish() {
     // We store previous, current and next partitions 
     Partition currentPartition = myOS.searchPartitionTable(deleteProcessBA);
     // Ensure that the partition is not null
     if (currentPartition == null) {
       sim.addToLog("  >Coalesce: No partition found for base address " + deleteProcessBA);
       return;
     }
     // Get the previous and next partitions
     Partition previousPartition = null;
     Partition nextPartition = null;  
     if (isNotFirst(currentPartition)) {
       previousPartition = myOS.partitionTable.get(myOS.partitionTable.indexOf(currentPartition) - 1);
     }
     if (isNotLast(currentPartition)) {
       nextPartition = myOS.partitionTable.get(myOS.partitionTable.indexOf(currentPartition) + 1);
     }
     if (isPreviousAndNextFree(previousPartition, nextPartition)) {
       // Merge partitions previous and next with current
       previousPartition.size += currentPartition.size + nextPartition.size;
       myOS.partitionTable.remove(currentPartition);
       myOS.partitionTable.remove(nextPartition);
       sim.addToLog("  >Coalesce: Merged previous, current, and next partitions.");
     } else if (isPreviousFree(previousPartition)) {
       // Merge partitions previous with current
       previousPartition.size += currentPartition.size;  
       myOS.partitionTable.remove(currentPartition);  
       sim.addToLog("  >Coalesce: Merged previous and current partitions.");
     } else if (isNextFree(nextPartition)) {
       // Merge partitions next with current
       currentPartition.size += nextPartition.size;
       myOS.partitionTable.remove(nextPartition);
       sim.addToLog("  >Coalesce: Merged current and next partitions.");
     } else {
       sim.addToLog("  >Coalesce: No adjacent free partitions to merge.");
     }
     // Change its state to ready
     this.state = STATE.READY;
   }
   */
   public void finish() {
     // Iterate through the partition table to find and merge adjacent free partitions
     for (int i = 0; i < myOS.partitionTable.size() - 1; i++) {
       Partition currentPartition = myOS.partitionTable.get(i);
       Partition nextPartition = myOS.partitionTable.get(i + 1);    
       if (currentPartition.isFree && nextPartition.isFree) {
         // Merge current and next partitions
         currentPartition.size += nextPartition.size;
         myOS.partitionTable.remove(nextPartition);
         i--; // Adjust index to recheck the current partition with the next one
         sim.addToLog("  >Coalesce: Merged partitions at index " + i + " and " + (i + 1));
       }
     }
     // Change its state to ready
     this.state = STATE.READY;
   } 
   
   private boolean isNotFirst(Partition currentPartition) {
     return myOS.partitionTable.indexOf(currentPartition) > 0;
   }
   private boolean isNotLast(Partition currentPartition) {
     return myOS.partitionTable.indexOf(currentPartition) < myOS.partitionTable.size() - 1;
   }
   private boolean isPreviousAndNextFree(Partition previousPartition, Partition nextPartition) {
     return isPreviousFree(previousPartition) && isNextFree(nextPartition);
   }
   private boolean isPreviousFree(Partition previousPartition) {
     return previousPartition != null && previousPartition.isFree;
   }
   private boolean isNextFree(Partition nextPartition) {
     return nextPartition != null && nextPartition.isFree;
   }
}
////////////////////////////////////////////////////////////////

// public class CompactKernel extends KernelProcess{
//   private int deleteProcessBA;
//   CompactKernel(String name, String code, int IRQ, int ba) {
//     super(name, code, IRQ);
//     deleteProcessBA = ba;
//   }
  
//   public void finish() {
    
//   }
// }