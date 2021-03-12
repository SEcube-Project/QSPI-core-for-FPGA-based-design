int cs = 13;
int spi_clk = 12;
int sdio_3 = 8;
int sdio_2 = 7;
int sdio_1 = 4;
int sdio_0 = 2;
int read_ok = 0;
void setup() {
  Serial.begin(19200);
  // put your setup code here, to run once:
  pinMode(cs, INPUT);
  pinMode(spi_clk, INPUT);
  pinMode(sdio_3, INPUT);
  pinMode(sdio_2, INPUT);
  pinMode(sdio_1, INPUT);
  pinMode(sdio_0, INPUT);

}

void loop() {
  if (digitalRead(cs) == 0) {
    delay(0.5);
     if (read_ok == 0) {
      if (digitalRead(spi_clk) == 0) {
      Serial.print("CLK: ");
      Serial.print(digitalRead(spi_clk));
      Serial.print(" ");
      Serial.print(digitalRead(sdio_3));
      Serial.print(digitalRead(sdio_2));
      Serial.print(digitalRead(sdio_1));
      Serial.print(digitalRead(sdio_0));
      Serial.println(""); 
      read_ok = 1;
    }
    }
    if (read_ok == 1) {
      while (digitalRead(spi_clk) == 0) {}  
      read_ok = 0;
    } 
  }
}
