public class Hardware {
  /*Instruction set
   * = any instruction
   $ = an exit instruction
   d = data like static variables / constants
   A program will look like this:
   *******$dddd
   */

  //CPU
  char IR; //Intruction register
  int counter; //Program counter
  int MAR; //Memory Address Register
  int BA; //Base address

  //RAM
  char[][] RAM;
  int RAMBanks; // between 1 to 4 banks
  final int maxRAMSizeInBank = 80;
  final int minRAMSizeInBank = 40;
  final int maxRAMBanks = 4;
  int RAMSizeInBank;   // between 40 to 360 chars
  int RAMSize;

  //HDD
  //filename --> code
  HashMap<String, String>HDD;

  //clock
  int clock;

  //Keyboard Buffer
  ArrayList<Integer> keyboardBuffer;

  //Interrupts
  boolean interruptsEnabled;
  boolean[] IRQ;
  char[] IRQname;

  Hardware(int nb, int bs) {
    RAMBanks = constrain(nb, 1, maxRAMBanks);
    RAMSizeInBank = constrain(bs, minRAMSizeInBank, maxRAMSizeInBank);
    RAM = new char[RAMBanks][RAMSizeInBank];
    HDD = new HashMap<String, String>();
    keyboardBuffer = new ArrayList<Integer>();
    IRQ = new boolean[16];  
    IRQname = new char[IRQ.length];
    //0 for keyboard event
    //>0 for OS 
    
  }

  //PUBLIC  METHODS
  /////////////////////////////
  public void powerOn() {
    checkRAM();
    mountHDD();
    //start my OS
    myOS.boot();
    interruptsEnabled = true;
    for(int i=0; i<IRQ.length; i++){
     IRQ[i] = false;
    }
  }

  public void keyBoardEvent(int k) {
    IRQ[0] = true;  //<>//
    keyboardBuffer.add(k);  //<>//
    sim.addToLog(">User: Pressed button "+k);
  }

  public void ticToc() {
    //increment the clock
    clock++;
    //either do a fetch or an execute
    if (clock % 2 == 1) {
      handleInterrupts();
      fetch();
    } else {
      execute();
    }
  }
  
  //PRIVATE METHODS
  ///////////////////////////

  private void handleInterrupts() {
    if(interruptsEnabled){
      //Lower the number higher the priority
      for(int i=1; i<IRQ.length; i++){ //<>//
        if(IRQ[i]){
          myOS.handleInterrupt(i);
          IRQ[i] = false;
          break;
        }
      }
      if(IRQ[0]){
        int k = keyboardBuffer.remove(0); 
        myOS.request = "program"+k+".exe";
        if (keyboardBuffer.isEmpty()) {
          IRQ[0] = false;
        }
        sim.requestTotal++;
        sim.addToLog(">myPC: Keyboard interrupt handled. Request for "+myOS.request+". Staring Memory Manager");
        myOS.raiseIRQ("memoryManager");
      }
    }
  }

  private void checkRAM() {
    //calculate how much RAM is available
    RAMSize = RAMBanks * RAMSizeInBank;
    //initialise the RAM by writting the ' ' in every position
    for (int i=0; i<RAMBanks; i++) {
      for (int j=0; j<RAMSizeInBank; j++) {
        RAM[i][j] = ' ';
      }
    }
  }

  private void mountHDD() {
    HDD.put("program1.exe", "****$ddd");
    HDD.put("program2.exe", "*********$ddddd");
    HDD.put("program3.exe", "****************$dddddddd");
  }

  private void fetch() {
    MAR = BA + counter;
    IR = RAM[MAR/RAMSizeInBank][MAR%RAMSizeInBank];
    sim.addToLog(">myPC: At time "+clock+" fetched a "+IR);
  }

  private void execute() {
    sim.addToLog(">myPC: At time "+clock+" executed a "+IR);
    myOS.call(IR);
    if(IR=='*'){
      counter++;
    }
  }
}
