#include <TinyGPS++.h>
#include <Wire.h>
#include <VL53L0X.h>


// === ULTRASONIC PINS ===
#define TRIG_LEFT     44
#define ECHO_LEFT     42

#define TRIG_CENTER   47
#define ECHO_CENTER   49

#define TRIG_RIGHT    45
#define ECHO_RIGHT    43

// #define TRIG_GROUND   46
// #define ECHO_GROUND   48

// === VIBRATION MOTORS ===
#define VIB1 40
#define VIB2 41

// === PROTECTION RELAY ===
#define RELAYLEFT 22
#define RELAYLEFT_SPEED 7
#define RELAYRIGHT 24
#define RELAYRIGHT_SPEED 6

// === LIGHT ===
#define LIGHT 50
#define BUZZER 51

// === L298N MOTOR DRIVER WITHOUT EN PINS ===
// Left motor
#define IN1 32
#define IN2 30

// Right motor
#define IN3 26
#define IN4 28

// === DISTANCE THRESHOLDS ===
#define THRESH_LEFT   20
#define THRESH_CENTER 20
#define THRESH_RIGHT  20
#define THRESH_GROUND 5
//--------------------------------------------

int speed = 255;
//--------------------------------------------

VL53L0X sensor;

// Store last measured distance
long lastDistance = 0;
//--------------------------------------------

TinyGPSPlus gps;
#define gpsSerial Serial1   // Neo-6M on RX1(19), TX1(18)

// Variables to store last valid location
double lastLat = 0.0;
double lastLng = 0.0;

// -----------------------------------------------------
// FUNCTION: Get latest available GPS coordinates
// -----------------------------------------------------
// #line 67 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void getLocation();
// #line 108 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void connectMQTT();
// #line 150 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void sendMQTT(String topic, String message);
// #line 183 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// long readUltrasonic(int trigPin, int echoPin);
// #line 198 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// long readTOF();
// #line 219 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void moveLeft();
// #line 234 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void moveRight();
// #line 249 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void moveBack();
// #line 264 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void stopMotors();
// #line 278 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void vibrate1();
// #line 279 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void vibrate2();
// #line 280 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void vibrateBoth();
// #line 281 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void vibrateOff();
// #line 284 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void setup();
// #line 348 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"
// void loop();
// #line 67 "C:\\Users\\shubh\\AppData\\Local\\Temp\\.arduinoIDE-unsaved20251112-14288-c99wwc.n66t\\sketch_dec12a\\sketch_dec12a.ino"

void getLocation() {
  // Check if the latest GPS fix is valid
  if (gps.location.isValid()) {
    lastLat = gps.location.lat();
    lastLng = gps.location.lng();

    Serial.print("Latitude: ");
    Serial.println(lastLat, 6);

    Serial.print("Longitude: ");
    Serial.println(lastLng, 6);

    Serial.println("--------------------------");
  } 
  else {
    Serial.println("No valid GPS fix yet...");
  }
}
//--------------------------------------------

// SIM800L is connected to Serial3 on Arduino Mega
// TX3 = Pin 14, RX3 = Pin 15

#define sim800 Serial3

// MQTT broker details
const char* broker = "test.mosquitto.org";
int brokerPort = 1883;

// MQTT client ID
String clientID = "ArduinoSIM800Client";

void sendAT(String cmd, int wait = 1000) {
  sim800.println(cmd);
  delay(wait);
  while (sim800.available()) Serial.write(sim800.read());
}

// ---------------------------------------------------------
// MQTT CONNECT PACKET
// ---------------------------------------------------------
void connectMQTT() {
  byte packet[50];
  int index = 0;

  packet[index++] = 0x10;  // CONNECT control packet
  int remainingLength = 10 + clientID.length();
  packet[index++] = remainingLength;

  // Protocol name "MQTT"
  packet[index++] = 0x00;
  packet[index++] = 0x04;
  packet[index++] = 'M';
  packet[index++] = 'Q';
  packet[index++] = 'T';
  packet[index++] = 'T';

  packet[index++] = 0x04;  // Protocol level
  packet[index++] = 0x02;  // Clean session
  packet[index++] = 0x00;  // Keep Alive MSB
  packet[index++] = 0x3C;  // Keep Alive LSB = 60 seconds

  // Client ID
  packet[index++] = 0x00;
  packet[index++] = clientID.length();
  for (int i = 0; i < clientID.length(); i++)
    packet[index++] = clientID[i];

  // Send packet
  sim800.print("AT+CIPSEND=");
  sim800.println(index);
  delay(100);

  for (int i = 0; i < index; i++)
    sim800.write(packet[i]);

  sim800.write(0x1A);
  delay(700);
}

// ---------------------------------------------------------
// SIMPLE MQTT PUBLISH FUNCTION (YOU CALL THIS ANYTIME)
// ---------------------------------------------------------
void sendMQTT(String topic, String message) {
  byte packet[200];
  int index = 0;

  packet[index++] = 0x30;  // MQTT PUBLISH

  int remainingLength = 2 + topic.length() + message.length();
  packet[index++] = remainingLength;

  // Topic
  packet[index++] = 0x00;
  packet[index++] = topic.length();
  for (int i = 0; i < topic.length(); i++)
    packet[index++] = topic[i];

  // Payload
  for (int i = 0; i < message.length(); i++)
    packet[index++] = message[i];

  // Send packet
  sim800.print("AT+CIPSEND=");
  sim800.println(index);
  delay(50);

  for (int i = 0; i < index; i++)
    sim800.write(packet[i]);

  sim800.write(0x1A);
  delay(500);
}
//--------------------------------------------

// === READ ULTRASONIC FUNCTION ===
long readUltrasonic(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 30000);
  long distance = duration * 0.034 / 2;

  if (distance == 0) return 500;
  return distance;
}

// === Measure distance when called ===
long readTOF() {
  long tof = sensor.readRangeContinuousMillimeters();
  if (sensor.timeoutOccurred()) tof = -1;
    
  Serial.print("Distance: ");
  Serial.print(tof);
  Serial.println(" mm");
  return tof;
}

// === MOTOR CONTROL (ON/OFF CONTROL ONLY) ===
void moveLeft() {
  digitalWrite(RELAYLEFT, LOW);
  digitalWrite(RELAYRIGHT, LOW);

  analogWrite(RELAYLEFT_SPEED, speed);
  analogWrite(RELAYRIGHT_SPEED, speed);

  // Left motor backward, Right motor forward
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  
  // digitalWrite(IN3, HIGH);
  // digitalWrite(IN4, LOW);
}

void moveRight() {
  digitalWrite(RELAYLEFT, LOW);
  digitalWrite(RELAYRIGHT, LOW);

  analogWrite(RELAYLEFT_SPEED, speed);
  analogWrite(RELAYRIGHT_SPEED, speed);

  // Right motor backward, Left motor forward
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);

  // digitalWrite(IN3, LOW);
  // digitalWrite(IN4, HIGH);
}

void moveBack() {
  digitalWrite(RELAYLEFT, LOW);
  digitalWrite(RELAYRIGHT, LOW);

  analogWrite(RELAYLEFT_SPEED, speed);
  analogWrite(RELAYRIGHT_SPEED, speed);

  // Both motors backward
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);

  digitalWrite(IN3, LOW);
  digitalWrite(IN4, HIGH);
}

void stopMotors() {
  digitalWrite(RELAYLEFT, HIGH);
  digitalWrite(RELAYRIGHT, HIGH);

  analogWrite(RELAYLEFT_SPEED, 0);
  analogWrite(RELAYRIGHT_SPEED, 0);

  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
}

// === VIBRATION MOTOR CONTROL ===
void vibrate1() { digitalWrite(VIB1, HIGH); }
void vibrate2() { digitalWrite(VIB2, HIGH); }
void vibrateBoth() { digitalWrite(VIB1, HIGH); digitalWrite(VIB2, HIGH); }
void vibrateOff() { digitalWrite(VIB1, LOW); digitalWrite(VIB2, LOW); }

// ==========================================================

void setup() {
  Serial.begin(9600);
  sim800.begin(9600);
  gpsSerial.begin(9600);
  Wire.begin();  // SDA=20, SCL=21 (Mega)

  // TOF INIT
  Serial.println("Initializing VL53L0X...");
  sensor.init();
  sensor.setTimeout(500);
  sensor.startContinuous();
  Serial.println("VL53L0X Ready.");

  Serial.println("GPS Ready...");

  Serial.println("Initializing SIM800...");

  sendAT("AT");
  sendAT("AT+CPIN?");
  sendAT("AT+CREG?");
  sendAT("AT+CGATT=1", 2000);

  sendAT("AT+CIPSHUT");
  sendAT("AT+CIPMUX=0");

  // Change APN according to SIM
  sendAT("AT+CSTT=\"internet\"");
  // Jio → "jionet"
  // Airtel → "airtelgprs.com"
  // VI → "internet"

  sendAT("AT+CIICR", 3000);
  sendAT("AT+CIFSR");

  // Connect TCP
  sendAT("AT+CIPSTART=\"TCP\",\"test.mosquitto.org\",1883", 4000);

  // MQTT CONNECT
  connectMQTT();

  Serial.println("MQTT Connected.");

  pinMode(TRIG_LEFT, OUTPUT);   pinMode(ECHO_LEFT, INPUT);
  pinMode(TRIG_CENTER, OUTPUT); pinMode(ECHO_CENTER, INPUT);
  pinMode(TRIG_RIGHT, OUTPUT);  pinMode(ECHO_RIGHT, INPUT);
  // pinMode(TRIG_GROUND, OUTPUT); pinMode(ECHO_GROUND, INPUT);

  pinMode(RELAYLEFT, OUTPUT);  pinMode(RELAYRIGHT, OUTPUT);
  pinMode(RELAYLEFT_SPEED, OUTPUT);  pinMode(RELAYRIGHT_SPEED, OUTPUT);
  pinMode(LIGHT, OUTPUT);

  pinMode(VIB1, OUTPUT);
  pinMode(VIB2, OUTPUT);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  stopMotors();
  vibrateOff();
}

// ==========================================================
void loop() {
  // Keep feeding GPS data in the background
  while (gpsSerial.available()) {
    gps.encode(gpsSerial.read());
  }
  // Getting Location
  getLocation();
  // lastLat, lastLng

  long distLeft = readUltrasonic(TRIG_LEFT, ECHO_LEFT);
  long distCenter = readUltrasonic(TRIG_CENTER, ECHO_CENTER);
  long distRight = readUltrasonic(TRIG_RIGHT, ECHO_RIGHT);
  // long distGround = readUltrasonic(TRIG_GROUND, ECHO_GROUND);
  long distGround = readTOF();

  Serial.print("L: "); Serial.print(distLeft);
  Serial.print("  C: "); Serial.print(distCenter);
  Serial.print("  R: "); Serial.print(distRight);
  Serial.print("  G: "); Serial.println(distGround);

  // CALL THIS ANYTIME YOU WANT TO SEND A MESSAGE
  // sendMQTT("iot/test", "Hello from SIM800 over Serial3!");

  // ===== PRIORITY 1: GROUND OBSTACLE =====
  if (distGround > THRESH_GROUND) {
    Serial.println("Danger..!! Pothole or Stairs Ahead");
    vibrateBoth();
    moveBack();
    delay(250);
    stopMotors();
    vibrateOff();
    return;
  }

  // ===== LEFT OBSTACLE =====
  else if (distLeft < THRESH_LEFT) {
    Serial.println("Obstacle at Left, Turning Right");
    vibrate1();
    moveRight();
    // delay(250);
    // stopMotors();
    // vibrateOff();
    return;
  }

  // ===== RIGHT OBSTACLE =====
  else if (distRight < THRESH_RIGHT) {
    Serial.println("Obstacle at Right, Turning Left");
    vibrate2();
    moveLeft();
    // delay(250);
    // stopMotors();
    // vibrateOff();
    return;
  }

  // ===== CENTER OBSTACLE =====
  else if (distCenter < THRESH_CENTER) {
    Serial.print("Obstacle Ahead, ");
    vibrateBoth();

    if (distLeft > distRight) {
      Serial.println("Turning Left");
      moveLeft();
    } else {
      Serial.println("Turning Right");
      moveRight();
    }

    // delay(250);
    // stopMotors();
    // vibrateOff();
    return;
  }

  // ===== NOTHING DETECTED =====
  stopMotors();
  vibrateOff();
}



















