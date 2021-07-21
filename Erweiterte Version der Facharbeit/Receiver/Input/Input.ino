
void setup() {
  Serial.begin(9600);
}

void loop() {
  int val = analogRead(A0);
  Serial.println();
  Serial.print(val);

  if (Serial.available() > 0) {
    int in = Serial.read();
    if (in == 0 || in == 1) {
      Serial.print(",");
      Serial.print(in);
    }
  }
}
