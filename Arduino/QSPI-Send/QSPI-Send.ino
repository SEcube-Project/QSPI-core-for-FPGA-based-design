int cs = 13;
int spi_clk = 12;
int sdio_3 = 8;
int sdio_2 = 7;
int sdio_1 = 4;
int sdio_0 = 2;

int counter = 0;

void setup() {
  Serial.begin(19200);
  // put your setup code here, to run once:
  pinMode(cs, INPUT);
  pinMode(spi_clk, INPUT);
  pinMode(sdio_3, OUTPUT);
  pinMode(sdio_2, OUTPUT);
  pinMode(sdio_1, OUTPUT);
  pinMode(sdio_0, OUTPUT);
}

void loop() {
  if (digitalRead(cs) == 0) {
    if (digitalRead(spi_clk) == 0) {
      if (counter == 0) {
        Serial.println("Sending 1");
        digitalWrite(sdio_3, LOW);
        digitalWrite(sdio_2, LOW);
        digitalWrite(sdio_1, LOW);
        digitalWrite(sdio_0, HIGH);
        counter++;
      } else if (counter == 1) {
        Serial.println("Sending 1");
        digitalWrite(sdio_3, LOW);
        digitalWrite(sdio_2, LOW);
        digitalWrite(sdio_1, LOW);
        digitalWrite(sdio_0, HIGH);    
        counter++;    
      } else if (counter == 2) {
        Serial.println("Sending 2");
        digitalWrite(sdio_3, LOW);
        digitalWrite(sdio_2, LOW);
        digitalWrite(sdio_1, HIGH);
        digitalWrite(sdio_0, LOW);    
        counter++;  
    }   else if (counter == 3) {
      Serial.println("Sending 2");
        digitalWrite(sdio_3, LOW);
        digitalWrite(sdio_2, LOW);
        digitalWrite(sdio_1, HIGH);
        digitalWrite(sdio_0, LOW);    
        counter++;  
    }   else if (counter == 4) {
        Serial.println("Sending 4");
        digitalWrite(sdio_3, LOW);
        digitalWrite(sdio_2, HIGH);
        digitalWrite(sdio_1, LOW);
        digitalWrite(sdio_0, LOW);    
        counter++;  
    }   else if (counter == 5) {
        Serial.println("Sending 4");
        digitalWrite(sdio_3, LOW);
        digitalWrite(sdio_2, HIGH);
        digitalWrite(sdio_1, LOW);
        digitalWrite(sdio_0, LOW);    
        counter++;  
    }   else if (counter == 6) {
        Serial.println("Sending 6");
        digitalWrite(sdio_3, LOW);
        digitalWrite(sdio_2, HIGH);
        digitalWrite(sdio_1, HIGH);
        digitalWrite(sdio_0, LOW);    
        counter++;  
    }   else if (counter == 7) {
        Serial.println("Sending 6");
        digitalWrite(sdio_3, LOW);
        digitalWrite(sdio_2, HIGH);
        digitalWrite(sdio_1, HIGH);
        digitalWrite(sdio_0, LOW);    
        counter++;  
    }   else if (counter == 8) {
        Serial.println("Sending 8 ");
        digitalWrite(sdio_3, LOW);
        digitalWrite(sdio_2, LOW);
        digitalWrite(sdio_1, LOW);
        digitalWrite(sdio_0, HIGH);    
        counter++;  
    }   else if (counter == 9) {
        Serial.println("Sending 8");
        digitalWrite(sdio_3, LOW);
        digitalWrite(sdio_2, LOW);
        digitalWrite(sdio_1, LOW);
        digitalWrite(sdio_0, HIGH);    
        counter++;  
    }   else if (counter == 10) {
        Serial.println("Sending 10");
        digitalWrite(sdio_3, HIGH);
        digitalWrite(sdio_2, LOW);
        digitalWrite(sdio_1, HIGH);
        digitalWrite(sdio_0, LOW);    
        counter++;
    }   else if (counter == 11) {
        Serial.println("Sending 11");
        digitalWrite(sdio_3, HIGH);
        digitalWrite(sdio_2, LOW);
        digitalWrite(sdio_1, HIGH);
        digitalWrite(sdio_0, HIGH);    
        counter++;
    }   else if (counter == 12) {
        Serial.println("Sending 12");
        digitalWrite(sdio_3, HIGH);
        digitalWrite(sdio_2, HIGH);
        digitalWrite(sdio_1, LOW);
        digitalWrite(sdio_0, LOW);    
        counter++;
    }   else if (counter == 13) {
        Serial.println("Sending 13");
        digitalWrite(sdio_3, HIGH);
        digitalWrite(sdio_2, LOW);
        digitalWrite(sdio_1, HIGH);
        digitalWrite(sdio_0, HIGH);    
        counter++;
    }   else if (counter == 14) {
        Serial.println("Sending 14");
        digitalWrite(sdio_3, HIGH);
        digitalWrite(sdio_2, HIGH);
        digitalWrite(sdio_1, HIGH);
        digitalWrite(sdio_0, LOW);    
        counter++;
    }   else if (counter == 15) {
        Serial.println("Sending 15");
        digitalWrite(sdio_3, HIGH);
        digitalWrite(sdio_2, HIGH);
        digitalWrite(sdio_1, HIGH);
        digitalWrite(sdio_0, HIGH);    
        counter = 0;
    }
    while (digitalRead(spi_clk) == 0) {};
    }
  }
}
