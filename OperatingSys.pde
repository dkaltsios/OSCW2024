public class OperatingSystem {
  public int partitions;
  
  //Shared OS data
  public ArrayList<Partition> partitionTable;
  public ArrayList<PCB> processTable;
  public ArrayList<UserProcess> readyQueue;
  public final String processTail = "hhhhhssss";
  public String request;
  public String newProcessImage;
  public Partition partitionFound;
  public UserProcess newProcess;
  public UserProcess deleteProcess;
  public PCB active;
  public UserProcess suspended;

  //Kernel Information
  public boolean kernelMode;
  public String kernelImage="";
  public HashMap<String, KernelProcess> kernel;
  //public IdleKernel idle;
  //public MemoryManagerKernel memoryManager;
  //public CreateProcessKernel createProcess;
  //public AdmitProcessKernel admitProcess;
  //public SchedulerKernel scheduler;
  //public ExitProcessKernel exitProcess;

  OperatingSystem(int p) {
    partitions = p;
    partitionTable = new ArrayList<Partition>();
    processTable = new ArrayList<PCB>();
    readyQueue = new ArrayList<UserProcess>();
    kernel = new HashMap<String, KernelProcess>();
  }

  //PUBLIC METHODS
  ////////////////////////////
    //Lower the number higher the priority
    //1 for invoke process admitter
    //2 for invoke process creator  
    //3 for invoke memory manager
    //4 for invoke process scheduler 
    //5 for invoke idle
    //6 for invoke process eliminator 
    
  public void addToKernel(KernelProcess k){
    kernel.put(k.reference, k);
    kernelImage = k.compileTo(kernelImage);  
  }

  public void boot() {
    sim.addToLog(" >myOS: Booting OS");
    int partitionBA = 0;
    partitionTable.add(new Partition(partitionBA, kernelImage.length()));
    partitionBA += kernelImage.length();
    int partitionSize = (myPC.RAMSize-kernelImage.length()) / partitions;
    for (int i=0; i<partitions; i++) {
      partitionTable.add(new Partition(partitionBA, partitionSize));
      partitionBA += partitionSize;
    } 
    myPC.IRQname[0]='K';
    for(KernelProcess k: kernel.values()){
      processTable.add(k);
      myPC.IRQname[k.IRQnum] = k.completeInstruction;;
    }
    loadOSImage();
  }
  
  public void handleInterrupt(int IRQnum){
    for(KernelProcess k : kernel.values()){
      if(IRQnum == k.IRQnum){
        k.start();
        break;
      }
    }
  }

  public void call(char instruction) {
    if(instruction == '*'){
      if (kernelMode) {
        sim.contextSwitchTime+=2;
      }else{
        sim.utilisationTime+=2;
      }
    }else if(instruction == '$'){
      sim.utilisationTime+=2;
      sim.addToLog(" >myOS: Exiting the running process");
      myOS.deleteProcess = (UserProcess) myOS.active;
      myOS.deleteProcess.finish();
      sim.processStatistics.add(new ProcessStats(deleteProcess));
      kernel.get("exitProcess").setIRQ(true);
    }else if(instruction == kernel.get("idle").completeInstruction){
      sim.idleTime+=2;
      sim.addToLog(" >myOS: System is idle. Waiting for user input");
      finishKernelProcess("idle");
    }else if(instruction == kernel.get("memoryManager").completeInstruction){
      sim.contextSwitchTime+=2;
      sim.addToLog(" >myOS: Finished running memory manager");
      finishKernelProcess("memoryManager");
    }else if(instruction == kernel.get("createProcess").completeInstruction){
      sim.contextSwitchTime+=2;
      sim.addToLog(" >myOS: Finished creating process");
      finishKernelProcess("createProcess");
    }else if(instruction == kernel.get("admitProcess").completeInstruction){
      sim.contextSwitchTime+=2;
      sim.addToLog(" >myOS: Finished admitting process to the ready queue");
      finishKernelProcess("admitProcess");
    }else if(instruction == kernel.get("scheduler").completeInstruction){
      sim.contextSwitchTime+=2;
      sim.addToLog(" >myOS: Finished scheduling");
      finishKernelProcess("scheduler");
    }else if(instruction == kernel.get("exitProcess").completeInstruction){
      sim.contextSwitchTime+=2;
      sim.addToLog(" >myOS: Finished exiting program "+myOS.active.pid);
      finishKernelProcess("exitProcess");
    }else{
      sim.addToLog(" >myOS: ERROR 101 Undefined instruction");
    }
  }
  
  public void startKernelProcess(String name){
    kernel.get(name).start();
  }
  
  public void finishKernelProcess(String name){
    kernel.get(name).finish();
  }
  
  public void raiseIRQ(String name){
    kernel.get(name).setIRQ(true);
  }

  //PRIVATE METHODS
  ///////////////////////////

  private void loadOSImage() {
    writeToPartition(partitionTable.get(0), kernelImage);
    sim.addToLog("  >myOS: Kernel image written to OS partition. Starting IDLE");
    startKernelProcess("idle");
  }

  private void writeToPartition(Partition p, String processImage) {
    if (p.size >= processImage.length()) {
      for (int i=0; i<processImage.length(); i++) {
        writeToRAM(p.baseAddress+i, processImage.charAt(i));
      }
      p.isFree = false;
    }
  } 

  private void writeToRAM(int address, char x) {
    int bank = address / myPC.RAMSizeInBank;
    int position = address % myPC.RAMSizeInBank;
    myPC.RAM[bank][position] = x;
  }
  
  private void emptyPartition(int ba) {
    Partition p = searchPartitionTable(ba);
    for (int i=0; i<p.size; i++) {
      myOS.writeToRAM(p.baseAddress+i, ' ');
    }
    p.isFree = true;
  }
  
  private Partition searchPartitionTable(int ba) {
    Partition p = null;
    for (int i=0; i< myOS.partitionTable.size(); i++) {
      if (myOS.partitionTable.get(i).baseAddress == ba) {
        p = myOS.partitionTable.get(i);
        break;
      }
    }
    return p;
  }
  
}
