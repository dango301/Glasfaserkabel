//USER SETTINGS
float
  threshold = 1; // percentage by which min must be larger than max
int
  freq = 100, 
  xScale = 15;


import processing.serial.*;
Serial port;

HashMap<String, Character> bin = new HashMap<String, Character>();
String converted[] = {""};
String
  input, 
  cheat = "", 
  prevCheat = "", 
  ss = "110101", // START/STOPP
  bits = "";
int
  nPeriods = 1, 
  x = 0, 
  nMsg = 0, 
  maxBits = ss.length();
float
  prevY = height, // must be at max so it dosn't disturb min/max/avg
  min, 
  max, 
  avg = 0, 
  start = -1, 
  lastCall = 0;
boolean
  looping = true, 
  active = false;


void setup() {
  port = new Serial(this, Serial.list()[0], 9600);
  port.bufferUntil(10); // ASCII Code: Linefeed (LF or new line); waits for a linebreak in the input string and strored values in between in a buffer
  size(1200, 600);
  threshold = threshold / 100 + 1;
  background(255);
  println();

  bin.put("000", ' ');
  bin.put("001", 'e');
  bin.put("0100", 'n');
  bin.put("0101", 'i');
  bin.put("0110", 's');
  bin.put("0111", 'r');
  bin.put("10000", 'a');
  bin.put("10001", 't');
  bin.put("10010", 'd');
  bin.put("10011", 'h');
  bin.put("10100", 'u');
  bin.put("10101", 'l');
  bin.put("10110", 'c');
  bin.put("10111", 'g');
  bin.put("110000", 'm');
  bin.put("110001", 'o');
  bin.put("110010", 'b');
  bin.put("110011", 'w');
  bin.put("110100", 'f');
  bin.put("110101", '|'); // START/STOPP
  bin.put("110110", 'k');
  bin.put("110111", 'z');
  bin.put("111000", 'p');
  bin.put("111001", 'v');
  bin.put("111010", 'j');
  bin.put("111011", 'y');
  bin.put("111100", 'x');
  bin.put("111101", 'q');
  bin.put("111110", '.');
  bin.put("111111", ',');
}

// get values from buffer specified above; function interrupts program wherever it was to execute itself, then continues
void serialEvent(Serial p) {
  String[]inStrings = split(p.readString(), ',');
  input = inStrings[0];
  if (inStrings.length > 1) cheat = trim(inStrings[1]);
}

void keyPressed() {
  if (key == ' ') {
    if (looping) noLoop();
    else loop();
    looping = !looping;
  }
  if (key == 'r') reset();
}
void reset() {
  bits = "";
  if (converted[nMsg] != "") {
    converted = append(converted, "");
    nMsg++;
  }
  active = false;
  start = -1;
  nPeriods = 1;
  min = prevY;
  max = prevY;
  println("======================================");
}


void  draw() {
  try {
    float cTime = millis();
    int val = Integer.parseInt(trim(input));
    float y = map(val, 0, 1023, 0, height);

    stroke(0);
    strokeWeight(1);
    line(x, prevY, x + xScale, y);

    if (cTime > 3000) { // assuming 3.0s to get correct input
      fill(0);
      noFill();
      if (y < min) min = y;
      if (y > max) max = y;
    } else {
      min = y;
      max = y;
    }

    avg = (max + min) / 2;
    stroke(50, 168, 82);
    strokeWeight(3);
    point(x + xScale, avg);
    strokeWeight(2);
    stroke(0, 0, 255);
    point(x + xScale, min);
    stroke(255, 0, 0);
    point(x + xScale, max);

    if (!cheat.equals("")) {
      fill(0);
      text(cheat, x + xScale, y - 16);
      strokeWeight(12);
      stroke(128);
      point(x + xScale, y);
      prevCheat = cheat;
      cheat = "";
    }

    boolean canStart = y < avg && prevY > avg && max > min * threshold; // CONDITIONS FOR START OF MEASUREMENTS; 
    if (start == -1 && canStart) {
      start = cTime - (freq * 0.5); // start in middle of period so start would be around 50% of freq earlier
      lastCall = start;
      stroke(255, 0, 255);
      strokeWeight(2);
      line(x+xScale, 0, x + xScale, height);
    }


    if (start != -1 && cTime - lastCall >= freq) { // MEASUREMENT EVERY PERIOD
      //PROBLEM AREA FOR TIMING
      lastCall = start + (nPeriods++ * freq);
      //float lateness = millis() - lastCall;
      //println(lateness);
      decipher(y, avg); // INTERPRETATION DER DATEN
    }
    prevY = y;
  }
  catch(NumberFormatException nfe) {
    //println(nfe);
  }

  x += xScale;
  if (x > width) {
    //save("24th-"+(millis() / 1000)+".png");
    x = 0;
    background(255);
  }

  for (int i = 1; i <= nMsg + 1; i++) {
    text("Message " + i + ": " + converted[i - 1], 25, 25 * i);
  }
}


void decipher(float y, float avg) {

  boolean _bit = y < avg;
  String bit = _bit ? "1" : "0";
  bits += bit;
  if (!prevCheat.equals("") && !bit.equals(prevCheat)) {
    stroke(255, 0, 255); // purple
    //println("MISTAKE");
  } else stroke(_bit ? 0 : 255, 0, _bit ? 255 : 0); // 0 is red, 1 is green
  strokeWeight(10);
  point(x + xScale, y);
  prevCheat = "";

  int overflow = bits.length() - maxBits;
  if (overflow > 0) bits = bits.substring(overflow);
  println(bits);

  if (bits.equals(ss)) {
    stroke(255, 255, 0);
    strokeWeight(2);
    line(x+xScale, 0, x + xScale, height);
    if (active) {
      println(converted[nMsg]);
      println("END OF MESSAGE");
      reset();
      return;
    }
    println("START OF MESSAGE");
    bits = "";
    active = true;
    return;
  }
  if (!active) return;


  int i = 0;
  String b = "";
  while (i < bits.length()) {
    b += bits.charAt(i++);
    if (bin.get(b) != null) {
      converted[nMsg] += bin.get(b);
      bits = "";
      println(converted[nMsg]);
      return;
    }
  }
}
