//USER SETTINGS
int T = 65; 
float periodDelay = (T * .55);
float avgTreshold =  3; // amount by which avg should be larger than max

int xScale = 7;
float threshold = 1.01; // amount by which min must be larger than max
int resetTime = 1500; // in ms
String correctionBits = "11010110001011110000010011110110100010110101010110001111011000110010100000110001000100110010111001111111000100011001100100000110000101111010100100010011100000110000101011000001001001000110010111110110101";
float prevvY = height;
float negTime = 0;


import processing.serial.*;
Serial port;

HashMap<String, Character> bin = new HashMap<String, Character>();
String converted[] = {""};
String
  input, 
  cheat = "", 
  prevCheat = "", 
  ss = "110101", // START/STOPP
  bits = "", 
  comparisonBits = "";

int
  nPeriods = 1, 
  x = 0, 
  nMsg = 0, 
  maxBits = ss.length();
float
  prevY = height, // must be at max so it dosn't disturb min/max/avg
  max, 
  min, 
  avg = 0, 
  start = -1, 
  lastCall = 0;
boolean
  looping = true, 
  active = false;


void setup() {
  fullScreen(1);
  //size(1200, 600);
  background(255);
  println();
  port = new Serial(this, Serial.list()[1], 9600);
  port.bufferUntil(10); // ASCII Code: Linefeed (LF or new line); waits for a linebreak in the input string and strored values in between in a buffer


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

// get values from buffer specified above; function interrupts program wherever executed, then continues
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
  if (key == 'p') {
    save("17.03.2020, at "+(millis() / 1000)+" seconds.png");
    println("saved Screenshot");
  }
}
void reset() {
  delay(resetTime);
  bits = "";
  if (converted[nMsg] != "") {
    converted = append(converted, "");
    nMsg++;
  }
  active = false;
  start = -1;
  nPeriods = 1;
  max = height;
  min = 0;
  println();

  try {
    int errors = 0;
    int corrLen = correctionBits.length();
    if (corrLen != comparisonBits.length()) throw new ArrayIndexOutOfBoundsException();
    for (int c = 0; c < corrLen; c++)
      if (correctionBits.charAt(c) != comparisonBits.charAt(c)) errors++;
    println("Fehler: " + errors + "; Anzahl übertragene Bits: " + corrLen);
    println("Fehlerrate: " + (100 * float(errors) / float(corrLen)) + " %");
  } 
  catch (ArrayIndexOutOfBoundsException err) {
    println(err);
    println("Lengths do not match. Manually check for missing bits:");
  }
  println(correctionBits);
  println(comparisonBits);
  comparisonBits = "";

  println("========================================================================================================================================================");
  println();
}


void  draw() {
  try {
    float cTime = millis();
    int val = Integer.parseInt(trim(input));
    float y = map(val, 0, 1023, height, 0);

    int periods = 0;
    if (start != -1) {
      if (y > avg || y -20 > prevY) {
        stroke(255, 0, 0);
        if (negTime == 0) negTime = millis();
      } else {
        stroke(0, 0, 255);
        if (negTime != 0) {
          println("Negative Bits transmitted for", millis() - negTime, "ms.");
          periods = millis() - negTime > 30 ? ceil((millis() - negTime) / T - .25) : 0;
          println("Negative Bits transmitted for", periods, "T.");
          negTime = 0;
        }
      }
    }
    strokeWeight(1);
    line(x, prevY, x + xScale, y);

    if (cTime > 3500) { // assuming 3.5s to get correct input
      fill(0);
      noFill();
      if (y < max) max = y;
      if (y > min) min = y;
    } else {
      max = y;
      min = y;
    }



    avg = max * avgTreshold;
    stroke(50, 168, 82);
    strokeWeight(3);
    point(x + xScale, avg);
    strokeWeight(2);
    stroke(0, 0, 255);
    point(x + xScale, max);
    stroke(255, 0, 0);
    point(x + xScale, min);

    if (!cheat.equals("")) {
      fill(0);
      text(cheat, x + xScale, y - 16);
      strokeWeight(12);
      stroke(128);
      point(x + xScale, y);
      prevCheat = cheat;
      cheat = "";
    }

    boolean canStart = y < avg && prevY > avg && min > max * threshold; // CONDITIONS FOR START OF MEASUREMENTS; 
    if (start == -1 && canStart) {
      start = cTime - periodDelay; // start in middle of period so start would be around 50% of T earlier
      lastCall = start;
      stroke(255, 0, 255);
      strokeWeight(2);
      line(x+xScale, 0, x + xScale, height);
    }


    // MEASUREMENT EVERY PERIOD
    if (start != -1 && cTime - lastCall >= T) {
      lastCall = start + (nPeriods++ * T);
      decipher(y, avg, periods); // INTERPRETATION DER DATEN
    }
    prevvY = prevY;
    prevY = y;
  }
  catch(NumberFormatException nfe) {
    //println(nfe);
  }

  x += xScale;
  if (x > width) {
    x = 0;
    background(255);
  }

  for (int i = 1; i <= nMsg + 1; i++) {
    text("Message " + i + ": " + converted[i - 1], 25, 25 * i);
  }
}


void decipher(float y, float avg, int p) {
  // CONDITIONS FOR BIT
  boolean _bit = y < avg;

  boolean corrected = false;
  if (_bit) {
    int n = 1;
    for (int q = 0; q < p - 1; q++)
      if (comparisonBits.charAt(comparisonBits.length() - 1 - q) == '0') n++;

    if (p == n) {
      _bit = false; 
      corrected = true;
      println("CAUGHT!");
    }
  }

  String bit = _bit ? "1" : "0";
  bits += bit;
  comparisonBits += bit;

  if (comparisonBits.length() > correctionBits.length()) {
    println("Programm should have ended by now. Forcefully closing current Message.");
    comparisonBits = comparisonBits.substring(0, comparisonBits.length() - 1); 
    reset();
    return;
  }

  //if (!prevCheat.equals("") && !bit.equals(prevCheat)) {
  int bl = comparisonBits.length();
  if (!str(correctionBits.charAt(bl - 1)).equals(bit))
    stroke(255, 0, 255); // purple
  else
    stroke(_bit ? 0 : 255, 0, _bit ? 255 : 0); // 0 is red, 1 is blue
  if (corrected)
    stroke(0, 255, 0);

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
      println();
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
