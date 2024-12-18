class ProcessStats {
  int pid;//int PID; //Who am I?
  int baseAddress; //Where am I?
  int loadTime; //When was I created?
  int startTime;
  String name; //What is the program?
  int responseTime; //how much time did it pass to run the first instruction?
  int turnarroundTime; //how much time did it pass to run the last instruction?

  ProcessStats(UserProcess process) {
    pid = process.pid;
    baseAddress = process.baseAddress;
    loadTime = process.loadTime;
    startTime = process.startTime;
    responseTime = startTime - loadTime;
    turnarroundTime = process.finishTime - loadTime;
    name = process.reference;
  }

  String toString() {
    String result=":";
    result += sim.int2String(pid, 10);
    result += sim.int2String(loadTime, 10);
    result += sim.int2String(startTime, 10);
    result += sim.int2String(responseTime, 10);
    result += sim.int2String(turnarroundTime, 10);
    result += " "+name;
    return result;
  }
}
