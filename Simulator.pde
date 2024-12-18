public class Simulator extends Drawable{

  //Graphics related
  final color lightgreen = #28F741;
  final color green = #28AD1F;
  final color darkgreen = #075D32;

  final color pink = #FFC4F5;
  final color red = #F22735;
  final color maroon =#A00606;

  final color aqua = #62C1FA;
  final color blue = #4C55EA;
  final color darkblue = #0A05A7;

  final color yellow = #FAF026;
  final color orange = #FC8F00;

  final color white = #FFFFFF;
  final color black = #000000;

  final color lightgray =#CCCCCC;
  final color gray = #777777;
  final color darkgray = #333333;

  final int maxFrameRate = 40;

  private PFont courierBold;
  private PFont courier;

  private color CPUoutColor;
  private color CPUinColor;
  private color busColor;
  private color fetchExecute;  
  
  private CPU cpu;
  private RAM ram;
  private PartitionList partitionList;
  private OSInfo osInfo;
  private Requests requests;
  private KeyboardBuffer keyBuffer;
  private ProcessTable processTable;
  private ProcessQueue readyQueue;
  private Screen screen;
  private Clock clock;
  
  private float firstcolX, firstrowY, secondrowY;
  
  private int speed;
  private boolean isRunning;  
  private ArrayList<Request> userRequests;
  
  String explanation;
  
  //Statistics related
  ArrayList<ProcessStats> processStatistics;
  int idleTime;
  int contextSwitchTime;
  int utilisationTime;
  int timesBlocked;
  int requestTotal;
  int requestFails;
  PrintWriter output;
  
  Simulator(){
    this.initialise(0,0,width, height);
    speed = 20;
    isRunning = true;
    frameRate(maxFrameRate);
    firstcolX = 10;
    firstrowY = 10;
    secondrowY = 230;
    
    cpu = new CPU();
    cpu.initialise(firstcolX, firstrowY, 100, 0);
    
    ram = new RAM(myOS.partitionTable);
    ram.placeNextTo(cpu,30).resize(width-20-ram.getX(), 0);
    
    partitionList = new PartitionList(myOS.partitionTable);
    partitionList.initialise(ram.getX(), 190, ram.getW(), 0);
    
    osInfo = new OSInfo(18);
    osInfo.initialise(firstcolX, secondrowY, 150f, 0f);
    
    requests = new Requests(18);
    requests.placeNextTo(osInfo, 10).resize(110, 0);
    
    keyBuffer = new KeyboardBuffer(18);
    keyBuffer.placeNextTo(requests, 10).resize(50, 0);
    
    processTable = new ProcessTable(myOS.processTable, 18);
    processTable.placeNextTo(keyBuffer, 10).resize(380, 0);
    
    readyQueue = new ProcessQueue(myOS.readyQueue, "READY QUEUE", 18);
    readyQueue.placeNextTo(processTable, 10).resize(220, 0);
    
    clock = new Clock();
    clock.initialise(firstcolX+75, secondrowY+225, 150, 150);
    
    screen = new Screen();
    screen.initialise(firstcolX, 550, 300, 0);
     
    courierBold = createFont("courbd.ttf", 18);
    courier = createFont("cour.ttf", 18);
    
    userRequests = new ArrayList<Request>();
    processStatistics = new ArrayList<ProcessStats>();
    output = createWriter("Simulation.log");
    addToLog("=============== New Simulation ===============");
    addToLog("==============================================\n");
  }
  
  //PUBLIC METHODS///////////////////////////////
  ///////////////////////////////////////////////
  
  public void setupSimulation(){
    setupRequests(false);
    myPC.powerOn();
  }
  
  public void increaseSpeed(){
    speed -=5;
    speed = constrain(speed, 1, maxFrameRate);
  }
  
  public void decreaseSpeed(){
    speed +=5;
    speed = constrain(speed, 1, maxFrameRate);
  }
  
  public void addToLog(String message){
    println(message);  
    output.println(message);
    explanation += message+"\n";
  }
  
  public void newRequest(int req){
    userRequests.add(new Request(myPC.clock, req)); 
  }
  
  public void step(){
    addToLog("============== SIMULATION STEP "+(myPC.clock+1)+" ==============");
    if(!userRequests.isEmpty() && myPC.clock >= userRequests.get(0).time){
      myPC.keyBoardEvent(userRequests.get(0).request);  
      userRequests.remove(0);
    }
    myPC.ticToc();
    render();
  }
  
  public void update(){
    explanation = "";
    if(frameCount % speed == 0  && isRunning && frameCount>1){
      render();
      step();
    }if(sim.isRunning){
      clock.render();
    }
  }
  
  public void endSimulation(){
    float avLT = 0;
    float avRT = 0;
    float avTT = 0;
    addToLog("======================================");
    addToLog(" - Simulation ended on Time "+myPC.clock);
    addToLog("Statistics:");
    if (processStatistics.isEmpty()) {
      addToLog(" - No statistics");
    } else {
      addToLog(":   PID   : LoadTime : startTim : respTime : TurnTime :     Name");
      for (ProcessStats ps : processStatistics) {
        addToLog(ps.toString());
        avLT += ps.loadTime;
        avRT += ps.responseTime;
        avTT += ps.turnarroundTime;
      }
      avRT /= processStatistics.size();
      avTT /= processStatistics.size();
      avLT /= processStatistics.size();
      addToLog(" - Total requests            = "+ requestTotal);
      addToLog(" - Requests served           = "+ processStatistics.size());
      addToLog(" - Requests failed           = "+ requestFails);
      addToLog(" - Average Load Time         = "+ avLT);
      addToLog(" - Average Responce Time     = "+ avRT);
      addToLog(" - Average Turnarround Time  = "+ avTT);
      addToLog(" - Total simulation time     = "+ myPC.clock);
      addToLog(" - Idle time (IT)            = "+ idleTime);
      addToLog(" - Context switch time (CWT) = "+ contextSwitchTime);
      addToLog(" - Utility time (UT)         = "+ utilisationTime);
      addToLog(" - Simulation time = idle + CWT + UT +(1?) ["+myPC.clock+" = "+(idleTime+contextSwitchTime+utilisationTime)+" +(1?)]");
    }
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
    exit();  
  }
  
  public void render(){
    background(aqua);
    if (myPC.clock % 2 == 1) {
      fetchExecute = lightgreen;
      CPUoutColor = white;
      CPUinColor = fetchExecute;
      busColor = lightgreen;
    } else {
      fetchExecute = blue;
      CPUoutColor = white;
      CPUinColor = fetchExecute;
      busColor = gray;
    }
    
    cpu.render();
    ram.render();
    partitionList.render();
    
    osInfo.render();
    requests.render();
    keyBuffer.render();
    processTable.render();
    readyQueue.render();    
        
    clock.render();
    screen.render(); 
    
  }
  
  //PRIVATE METHODS//////////////////////////////
  ///////////////////////////////////////////////
  
  private void setupRequests(boolean batch) {
    //FEEL FREE TO EXPERIMENT WITH THIS LIST
    //REMEMBER new Request(time, keyPressed)
    userRequests.add(new Request(batch?0:3, 1));
    userRequests.add(new Request(batch?0:18, 2));
    userRequests.add(new Request(batch?0:28, 3));
    userRequests.add(new Request(batch?0:40, 1));
    userRequests.add(new Request(batch?0:48, 2));
    userRequests.add(new Request(batch?0:60, 3));
    userRequests.add(new Request(batch?0:68, 1));
    userRequests.add(new Request(batch?0:110, 3));
    userRequests.add(new Request(batch?0:131, 2));
    userRequests.add(new Request(batch?0:141, 2));
    userRequests.add(new Request(batch?0:162, 3));
  }
    
}

/////////////////////////////////////////////////////
public abstract class Drawable{
  protected float x, y, w, h;
  
  public void initialise(float x, float y, float w, float h){
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
  
  public Drawable resize(float w, float h){
    this.w = w;
    this.h = h;
    return this;
  }
  
  public Drawable placeNextTo(Drawable other, float d){
    this.x = other.getX() + other.getW() + d;
    this.y = other.getY();
    return this;
  }
    
  public float getX(){return x;}
  public float getY(){return y;}
  public float getW(){return w;}
  public float getH(){return h;}
  
  public String int2String(int num, int stringSize) {
    String intAsString = String.valueOf(num);
    String space="";
    int intSize = intAsString.length();
    if(stringSize>intSize){
      int d = stringSize - intSize;
      for(int i=0; i<d; i++){
          space += " ";  
      }
      intAsString = space+intAsString;
    }
    return intAsString;
  }
  
  public abstract void render();
}
//////////////////////////////////////////
public class CPU extends Drawable{

  public void render() {
    pushMatrix();
    translate(x, y);
    rectMode(CORNER);
    textFont(sim.courierBold);
    stroke(0);
    strokeWeight(5);
    //outer rect of top CPU
    fill(sim.CPUoutColor);
    rect(0, 0, w, w);
    strokeWeight(1);
    fill(sim.CPUinColor);
    //inner rect of top CPU
    rect(w*0.16, w*0.16, w*0.68, w*0.68, 7);
    fill(sim.black);
    pushStyle();
    textSize(50);
    textAlign(CENTER, CENTER);
    text(myPC.IR, w*0.5, w*0.5);
    popStyle();
    triangle(w*0.05, w*0.85, w*0.05, w*0.95, w*0.15, w*0.95);
    pushStyle();
    textAlign(CENTER, CENTER);
    textSize(10);
    strokeWeight(1);
    //interrupts
    if (myPC.interruptsEnabled) {
      fill(sim.green);
      rect(0, w, w, w*0.20);
      fill(sim.black);
      text("Int/pts Enabled", w*0.5, w*1.1);
    } else {
      fill(sim.red);
      rect(0, w, w, w*0.20);
      fill(sim.black);
      text("Int/pts Disabled", w*0.5, w*1.1);
    }
    for(int i=0; i<myPC.IRQ.length/2; i++){
      if(i<=myOS.kernel.size()){
        if(myPC.IRQ[i]){
          fill(sim.red);
          rect((i)*(w/(myPC.IRQ.length/2)), 1.2*w, (w/(myPC.IRQ.length/2)), 0.2*w);
          fill(sim.black);
        }else{
          fill(sim.green);  
          rect((i)*(w/(myPC.IRQ.length/2)), 1.2*w, (w/(myPC.IRQ.length/2)), 0.2*w);
          fill(sim.black);
        }
        text(myPC.IRQname[i], (i+0.5)*(w/(myPC.IRQ.length/2)), w*1.3);
      }else{
        fill(sim.white);
        rect((i)*(w/(myPC.IRQ.length/2)), 1.2*w, (w/(myPC.IRQ.length/2)), 0.2*w);
      }
    }
    for(int i=0; i<myPC.IRQ.length/2; i++){
      if(i+myPC.IRQ.length<=myOS.kernel.size()){
        if(myPC.IRQ[i+myPC.IRQ.length/2]){
          fill(sim.red);
          rect((i)*(w/(myPC.IRQ.length/2)), 1.4*w, (w/(myPC.IRQ.length/2)), 0.2*w);
          fill(sim.black);
        }else{
          fill(sim.green);  
          rect((i)*(w/(myPC.IRQ.length/2)), 1.4*w, (w/(myPC.IRQ.length/2)), 0.2*w);
          fill(sim.black);
        }
        text(myPC.IRQname[i+myPC.IRQ.length/2], (i+0.5)*(w/(myPC.IRQ.length/2)), w*1.5);
      }else{
        fill(sim.white);
        rect((i)*(w/(myPC.IRQ.length/2)), 1.4*w, (w/(myPC.IRQ.length/2)), 0.2*w);
      }
    }
    //counter register
    fill(sim.white);
    rect(0, 1.6*w, w, w*0.20);
    fill(sim.black);
    text("Counter: "+myPC.counter, w*0.5, w*1.7);
    //MAR
    fill(sim.white);
    rect(0, 1.8*w, w, w*0.20);
    fill(sim.black);
    text("MAR: "+myPC.MAR, w*0.5, w*1.9);

    popStyle();
    popMatrix();
  }
  
}
/////////////////////////////////////////
public class Clock extends Drawable{ 
  
  public void render() {
    fill(sim.fetchExecute);
    float inc = (frameCount % sim.speed)*TWO_PI/sim.speed;
    noStroke();
    arc(x, y, w, w, -HALF_PI, -HALF_PI+inc, PIE);
    pushStyle();
    textFont(sim.courierBold);
    textSize(w*0.4);
    fill(sim.black);
    textAlign(CENTER, CENTER);
    text(myPC.clock, x, y);
    popStyle();
  }
  
}
//////////////////////////////////////////
public class OSInfo extends Drawable{
  private float ts;
  
  OSInfo(float textSize){
    ts = textSize;
  }
  
  public void render(){
    pushMatrix();
    translate(x, y);
    noStroke();
    rectMode(CORNER);
    textSize(ts);
    fill(sim.darkgreen);
    rect(0, 0, w, ts*1.2);
    rect(0, 2*ts*1.2+5, w, ts*1.2);
    fill(sim.white);
    rect(0, ts*1.2, w, ts*1.2);
    rect(0, 3*ts*1.2+5, w, ts*1.2);
    
    textAlign(CENTER, CENTER);
    textFont(sim.courierBold);
    fill(sim.white);
    text("Running", w/2, ts/2);    
    text("Sus/ded", w/2, 2*ts*1.2+ts/2+5);
  
    fill(sim.black);
    textFont(sim.courier);
    text(myOS.active==null?"NULL":myOS.active.reference, w/2, ts*1.2+ts/2);
    String sus = myOS.suspended==null?"NULL":myOS.suspended.reference;
    text(sus, w/2, 3*ts*1.2+ts/2+5);
    popMatrix();
  }
}
//////////////////////////////////////////
public class RAM extends Drawable{
  
  ArrayList<Partition> partitionTable;
  float sqSize;
  
  RAM(ArrayList<Partition> partitionTable){
    this.partitionTable = partitionTable;
  }
  
  public void render() {
    sqSize = w / myPC.maxRAMSizeInBank;
    pushMatrix();
    translate(x, y);
    textFont(sim.courier);
    
    for (int i=0; i<myPC.RAMBanks; i++) {
      drawRAMBank(i, false);
    }
    for (int i=myPC.RAMBanks; i<myPC.maxRAMBanks; i++) {
      drawRAMBank(i, true);
    }
    popMatrix();
  }
  
  private void drawRAMBank(int bank, boolean empty) {
    int squares = myPC.RAMSizeInBank;
    stroke(0);
    pushMatrix();
    translate(0, 45*bank);
    textAlign(CENTER, CENTER);
    int partitionIndex;
    if (!empty) {
      //draw the BUS lines
      for (int i=0; i<myPC.maxRAMSizeInBank; i++) {
        drawBus(i, sqSize, sim.darkgray);
      }
      for (int i=0; i<myPC.maxRAMSizeInBank; i++) {
        if(i<squares){
        //Draw the partitions
          partitionIndex = findPI(bank*myPC.RAMSizeInBank+i);
          //println("Bank = "+bank+" Address = "+(bank*myPC.RAMSizeInBank+i)+" PI = "+partitionIndex);
          if (partitionIndex%2==1) {
            fill(sim.white);
          } else {
            fill(sim.black);
          }
          noStroke();
          if(partitionIndex>-1){
            rect(i*sqSize, -0.15*sqSize, sqSize, sqSize*1.3);
          }
          if(partitionIndex>-1){
            if((bank*myPC.RAMSizeInBank+i) == partitionTable.get(partitionIndex).baseAddress){
              pushStyle();
              textSize(8);
              fill(sim.black);
              textAlign(CENTER, BOTTOM);
              text(bank*myPC.RAMSizeInBank+i, i*sqSize, -0.15*sqSize);
              popStyle();
            }
          }
          
          //draw the ram
          if (myPC.MAR == i+bank*myPC.RAMSizeInBank) {
            fill(sim.fetchExecute);
            drawBus(i, sqSize, sim.busColor);
          } else if (myPC.RAM[bank][i]== ' '){
            fill(sim.white);
          }else if (bank == 0 && i<partitionTable.get(0).size){
            fill(sim.lightgray);
          }else{
            fill(sim.pink);
          }
          stroke(sim.black);
          
          square(i*sqSize, 0, sqSize);
          fill(0);
          text(myPC.RAM[bank][i], i*sqSize+sqSize/2, sqSize/2);
        }else{
          fill(sim.gray);
          stroke(sim.black);
          rect(i*sqSize, -0.15*sqSize, sqSize, sqSize*1.3);
        }
      }
    } else {
      for (int i=0; i<myPC.maxRAMSizeInBank; i++) {
        fill(sim.gray);
        stroke(sim.black);
        rect(i*sqSize, -0.15*sqSize, sqSize, sqSize*1.3);
        drawBus(i, sqSize, sim.gray);
      }
    }
    popMatrix();
  }
  
  private int findPI(int address) {
    int result = -1;
    for (Partition p : partitionTable) {
      if (address>=p.baseAddress && address<p.baseAddress+p.size) {
        result =  partitionTable.indexOf(p);
        break;
      }
    }
    return result;
  }
  
  private void drawBus(int i, float sqSize, color c){
    stroke(c);
    strokeWeight(2);
    strokeCap(ROUND);
    line(i*sqSize+0.5*sqSize, sqSize, i*sqSize+0.5*sqSize, 1.5*sqSize);
    line(i*sqSize+0.5*sqSize, 1.5*sqSize, -2*sqSize, 1.5*sqSize);
    strokeWeight(1);
    stroke(sim.black);
  }  
  
}
//////////////////////////////////
public class Requests extends Drawable{
  private int ts;
  
  Requests(int ts){
    this.ts =ts;
  }
  
  public void render() {
    pushMatrix();
    translate(x, y);

    noStroke();
    rectMode(CORNER);
    textSize(ts);
    textFont(sim.courierBold);

    fill(sim.darkgreen);
    rect(0, 0, w, ts*1.2);
    textAlign(CENTER, CENTER);
    fill(sim.white);
    text("USER REQs", w/2, ts/2-2);


    fill(sim.green);
    rect(0, ts*1.2, w, ts*1.2);
    textAlign(LEFT, CENTER);
    fill(sim.white);
    text("  t : Key", 0, ts*1.2+ts/2-2);

    textFont(sim.courier);
    int count =0;
    for (int i=0; i<sim.userRequests.size(); i++) {
      if (sim.userRequests.get(i).time <= myPC.clock) {
        if (i == 0) {
          fill(sim.red);
        } else {
          fill(sim.pink);
        }
      } else {
        fill(sim.white);
      }
      rect(0, (count+2)*ts*1.2, w, ts*1.2+2);
      fill(sim.black);
      text(sim.userRequests.get(i).toString(), 0, (count+2)*ts*1.2+ts/2-2);
      count++;
    }
    popMatrix();
  }
  
}
///////////////////////////////////////
public class KeyboardBuffer extends Drawable{
  int ts;
  
  KeyboardBuffer(int ts){
    this.ts = ts;  
  }
 
  public void render(){
    pushMatrix();
    translate(x, y);

    noStroke();
    rectMode(CORNER);
    textSize(ts);
    textFont(sim.courierBold);

    fill(sim.darkgreen);
    rect(0, 0, w, ts*1.2);
    textAlign(CENTER, CENTER);
    fill(sim.white);
    text("BUFF", w/2, ts/2-2);


    fill(sim.green);
    rect(0, ts*1.2, w, ts*1.2);
    textAlign(CENTER, CENTER);
    fill(sim.white);
    text("Key", w/2, ts*1.2+ts/2-2);

    textFont(sim.courier);

    for (int i=0; i<myPC.keyboardBuffer.size(); i++) {
      fill(sim.white);
      rect(0, (i+2)*ts*1.2, w, ts*1.2+2);
      fill(sim.black);
      text(myPC.keyboardBuffer.get(i), w/2, (i+2)*ts*1.2+ts/2-2);
    }
    popMatrix();          
  }
  
}
////////////////////////////////
public class PartitionList extends Drawable{
  
  ArrayList<Partition> partitionTable;
  
  PartitionList(ArrayList<Partition> partitionTable){
    this.partitionTable = partitionTable;  
  }
  
  public void render(){
    float sqSize;
    float start=0;
    pushMatrix();
    pushStyle();
    translate(x, y);
    for(int i=0; i<partitionTable.size(); i++){
      sqSize = w * partitionTable.get(i).size / myPC.RAMSize ;
      if(partitionTable.get(i).isFree){
        fill(sim.white);  
      }else{
        fill(sim.lightgray);  
      }
      rect(start, 0, sqSize, 20);
      fill(sim.black);
      textAlign(CENTER, CENTER);
      textSize(18);
      text(partitionTable.get(i).size, start+sqSize/2, 10);
      textSize(12);
      textAlign(CENTER, BOTTOM);
      text(partitionTable.get(i).baseAddress, start, 0);
      start += sqSize;
    }
    popStyle();
    popMatrix();
  }
}
///////////////////////////////
public class ProcessTable extends Drawable{
  int ts;
  ArrayList<PCB> processTable;
  
  
  ProcessTable(ArrayList<PCB> table, int ts){
    this.ts = ts;  
    this.processTable = table;
  }

  public void render(){
    pushMatrix();
    translate(x, y);

    noStroke();
    rectMode(CORNER);
    textSize(ts);
    textFont(sim.courierBold);

    fill(sim.darkgreen);
    rect(0, 0, w, ts*1.2);
    textAlign(CENTER, CENTER);
    fill(sim.white);
    text("PROCESS TABLE", w/2, ts/2-2);

    fill(sim.green);
    rect(0, ts*1.2, w, ts*1.2);
    textAlign(LEFT, CENTER);
    fill(sim.white);
    text(" PID : PC : STATE   : Name", 0, ts*1.2+ts/2-2);

    textFont(sim.courier);
    int count =0;
    for (PCB p : processTable) {
      if (p instanceof KernelProcess) fill(sim.lightgray);
      else fill(sim.white);
      rect(0, (count+2)*ts*1.2, w, ts*1.2+2);
      if (p.state==STATE.NEW) fill(sim.orange);
      else if (p.state==STATE.READY) fill(sim.darkgreen);
      else if (p.state==STATE.BLOCKED) fill(sim.red);
      else if (p.state==STATE.RUNNING) fill(sim.blue);
      else fill(sim.maroon);
      text(p.toString(), 0, (count+2)*ts*1.2+ts/2-2);
      count++;
    }
    popMatrix();
  }
  
}
////////////////////////////////////////
public class ProcessQueue extends Drawable{
  ArrayList<UserProcess> queue;
  String title;
  int ts;
  
  ProcessQueue(ArrayList<UserProcess> queue, String title, int ts){
    this.queue = queue;
    this.title = title;
    this.ts = ts;
  }

  public void render(){
    pushMatrix();
    translate(x, y); 

    noStroke();
    rectMode(CORNER);
    textSize(ts);
    textFont(sim.courierBold);

    fill(sim.darkgreen);
    rect(0, 0, w, ts*1.2);
    textAlign(CENTER, CENTER);
    fill(sim.white);
    text(title, w/2, ts/2-2);

    fill(sim.green);
    rect(0, ts*1.2, w, ts*1.2);
    textAlign(LEFT, CENTER);
    fill(sim.white);
    text("PID : LT : PR : SZ", 5, ts*1.2+ts/2-2);

    int count =0;
    textFont(sim.courier);
    for (UserProcess p : queue) {
      fill(sim.white);
      rect(0, (count+2)*ts*1.2, w, ts*1.2+2);
      fill(sim.black);
      text(int2String(p.pid, 3)+" :"+int2String(p.loadTime, 3)+" :"+int2String(p.priority,2)+"  : "+int2String(p.codeSize,2), 5, (count+2)*ts*1.2+ts/2-2);
      count++;
    }
    popMatrix();
  }
}
///////////////////////////////
public class Screen extends Drawable{

  void render() {
    textFont(sim.courierBold);
    fill(sim.black);
    textAlign(LEFT, TOP);
    text(sim.explanation, x, y);
  }
  
}
