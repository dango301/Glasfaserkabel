//USER SETTING
int freq = 100;


import processing.serial.*;
Serial port;

HashMap<Character, String> bin = new HashMap<Character, String>();
String validChars = "abcdefghijklmnopqrstuvwxyz., ";
boolean inputMode = true;
float prog;
String input = "", bits = "";

void setup() {
  if (freq < 9 || freq > 999)
    throw new RuntimeException("Frequency out of range [10; 999]");
    
  port = new Serial(this, Serial.list()[0], 9600);
  port.bufferUntil(10); // ASCII Code: Linefeed (LF or new line); waits for a linebreak in the input string and strored values in between in a buffer
  size(600, 200);

  bin.put(' ', "000");
  bin.put('e', "001");  //3Bit
  bin.put('n', "0100"); 
  bin.put('i', "0101");
  bin.put('s', "0110");
  bin.put('r', "0111");//4Bit
  bin.put('a', "10000");
  bin.put('t', "10001"); 
  bin.put('d', "10010");
  bin.put('h', "10011");
  bin.put('u', "10100");
  bin.put('l', "10101");
  bin.put('c', "10110");
  bin.put('g', "10111"); //5Bit
  bin.put('m', "110000");
  bin.put('o', "110001");
  bin.put('b', "110010");
  bin.put('w', "110011");
  bin.put('f', "110100");
  bin.put('|', "110101"); // START/STOPP
  bin.put('k', "110110");
  bin.put('z', "110111");
  bin.put('p', "111000");
  bin.put('v', "111001");
  bin.put('j', "111010");
  bin.put('y', "111011");
  bin.put('x', "111100");
  bin.put('q', "111101");
  bin.put('.', "111110");
  bin.put(',', "111111");//6Bit
}
String createBits(String in) {
  bits = freq < 100 ? "0" : "";
  bits += str(freq) + bin.get('|');
  for (int i = 0; i< in.length(); i++)
    bits += bin.get(in.charAt(i));
  bits += bin.get('|');
  println(bits);
  return bits;
}

void keyPressed() {
  if (inputMode) {
    if (key == '\n') {
      if (input == "") return;
      inputMode = false;
      port.write(createBits(input));
      return;
    }
    if (key == BACKSPACE && input != "") {
      input = input.substring(0, input.length() -1);
      return;
    }

    for (int i = 0; i < validChars.length(); i++) {
      if (validChars.charAt(i) == key) {
        input += key;
        println(input);
        return;
      }
    }
    println("Invalid Character: " + key);
  } else if (prog >= 1 && key == '\n') {
    port.write("RESET");
    inputMode = true;
    input = "";
    prog = 0;
    text("Resetting...", 0, 50);
    delay(250);
  }
}


void serialEvent(Serial p) {
  if (inputMode) return;
  try {
    float pos = Integer.parseInt(trim(p.readString()));
    prog = ++pos / (bits.length() - 3);
    //println(pos, bits.length(), prog);
  }
  catch(NumberFormatException nfe) {
    println(nfe);
  }
}

void draw() {
  background(0);
  fill(255);
  text(input, 25, 25);
  if (prog >= 1) fill(0, 255, 0);
  if (!inputMode) rect(0, height, prog * width, -50);
}
