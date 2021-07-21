int freq; // data transfer rate in ms/bit

boolean first = true;
long lastCall = 0;
String bits = "";
int i = 0;
int led = 11;

void setup() {
  Serial.begin(9600);
  pinMode(led, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);
}

void light(boolean state) {
  digitalWrite(led, state);
  digitalWrite(LED_BUILTIN, state);
}

void(* reset) (void) = 0; // function to reset program
void restart() {
  light(0);
  reset();
}

void loop() {
  if (Serial.available() > 0) {
    if (bits == "" || bits == "RESET") {
      String rawIn = Serial.readString();
      freq = rawIn.substring(0, 3).toInt();
      bits = rawIn.substring(3);
    } else if (Serial.readString() == "RESET") restart();
  }


  if (bits != "" && millis() - lastCall >= freq) {
    if (first) {
      lastCall = millis();
      first = false;
    }
    else
      lastCall += freq; // for more accuracy

    boolean state = bits.charAt(i) == '1';
    Serial.write(state ? 1 : 0); // Cheat
    light(state);
    Serial.println(i);

    if (++i > bits.length()) {
      restart();
    }
  }
}

// MERKE: öffnen der seriellen Monitors setzt Arduino Programm zurück
