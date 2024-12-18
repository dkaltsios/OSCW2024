public enum STATE { NEW, READY, BLOCKED, RUNNING, EXITING }
public enum SDLRTYPE { PREEMPTIVE, NONPREEMPTIVE }
public enum MMANAGERTYPE { VARIABLE, FIXED }

Hardware myPC;
OperatingSystem myOS;
Simulator sim;
static int pidCounter;

void setup(){
  size(1400, 800);
  pidCounter = 0;
  //setup the hardware. Arguments: Number of RAM Chips, Size of each chip (in chars)
  myPC = new Hardware(4, 60);
  //setup the OS. arguments: Number of user partitions in RAM when we boot
  myOS = new OperatingSystem(1);
  //Create and add to the kernel the kernel processes.
  //NOTE: the names are important. They are used to access the kernel processes from other processes
  //The order that are added determine the kernel image
  //Arguments: Name, Code, IRQ
  myOS.addToKernel(new IdleKernel("idle", "I", 5));
  //Arguments: Name, Code, IRQ, Memory manager Algorithm
  myOS.addToKernel(new MemoryManagerKernel("memoryManager", "*M", 3, new FirstFitMM()));
  //Arguments: Name, Code, IRQ
  myOS.addToKernel(new CreateProcessKernel("createProcess", "C", 2));
  //Arguments: Name, Code, IRQ
  myOS.addToKernel(new AdmitProcessKernel("admitProcess", "A", 1));
  //Arguments: Name, Code, IRQ
  myOS.addToKernel(new SchedulerKernel("scheduler", "S", 4, new ShortestJobFirstScheduler()));
  //Arguments: Name, Code, IRQ, scheduler Algorithm
  myOS.addToKernel(new ExitProcessKernel("exitProcess", "X", 6));
  //Arguments: Name, Code, IRQ
  myOS.addToKernel(new CoalesceKernel("coalesce", "N", 7));
  sim = new Simulator();
  sim.setupSimulation();
}

void draw(){
  sim.update();
}

void keyPressed(){
  
  if(key == CODED){
    if(keyCode == LEFT){
      sim.decreaseSpeed();
    }else if(keyCode == RIGHT){
      sim.increaseSpeed();
    }
  }else{
    if(key == '1'){
      myPC.keyBoardEvent(1);  
    }else if(key == '2'){
      myPC.keyBoardEvent(2);  
    }else if(key == '3'){
      myPC.keyBoardEvent(3);  
    }else if(key == 'p' || key == 'P'){
      sim.isRunning = !sim.isRunning;  
    }else if(key == 'q' || key == 'Q'){
      sim.endSimulation();  
    }else if(key == 's' || key == 'S'){
      sim.step();
      sim.render();
    }
  }
}
