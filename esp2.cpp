// ESP8266 Arduino Code for Smart Rice Dispenser - Sensor Controller
// esp2.cpp - Environmental Sensors and Status LEDs

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClient.h>
#include <ArduinoJson.h>
#include <DHT.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Supabase configuration
const char* supabaseUrl = "YOUR_SUPABASE_URL";
const char* supabaseKey = "YOUR_SUPABASE_KEY";

// Hardware pins (ESP8266 NodeMCU)
#define DHT_PIN           D2  // GPIO4
#define DHT_TYPE          DHT22
#define ULTRASONIC_TRIG   D8  // GPIO15
#define ULTRASONIC_ECHO   D0  // GPIO16
#define STATUS_LED_RED    D1  // GPIO5
#define STATUS_LED_GREEN  D7  // GPIO13
#define STATUS_LED_BLUE   D6  // GPIO12
#define BUZZER_PIN        D5  // GPIO14

// Hardware objects
DHT dht(DHT_PIN, DHT_TYPE);

// System state
float temperature = 0.0;
float humidity = 0.0;
float containerLevel = 0.0;
unsigned long lastSensorRead = 0;
unsigned long lastDataSend = 0;
const unsigned long SENSOR_READ_INTERVAL = 2000;  // 2 seconds
const unsigned long DATA_SEND_INTERVAL = 10000;   // 10 seconds

// Container specifications
const float CONTAINER_HEIGHT_CM = 30.0; // Adjust based on your container
const float EMPTY_DISTANCE_CM = 25.0;   // Distance when container is empty

void setup() {
  Serial.begin(115200);
  
  // Initialize hardware
  pinMode(STATUS_LED_RED, OUTPUT);
  pinMode(STATUS_LED_GREEN, OUTPUT);
  pinMode(STATUS_LED_BLUE, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(ULTRASONIC_TRIG, OUTPUT);
  pinMode(ULTRASONIC_ECHO, INPUT);
  
  // Initialize sensors
  dht.begin();
  
  // Connect to WiFi
  connectToWiFi();
  
  // Initial status indication
  setStatusLED(0, 255, 0); // Green - ready
  Serial.println("ESP8266 Sensor Controller Ready");
}

void loop() {
  unsigned long currentTime = millis();
  
  // Read sensors periodically
  if (currentTime - lastSensorRead >= SENSOR_READ_INTERVAL) {
    readSensors();
    updateStatusLED();
    lastSensorRead = currentTime;
  }
  
  // Send data to server periodically
  if (currentTime - lastDataSend >= DATA_SEND_INTERVAL) {
    sendSensorData();
    lastDataSend = currentTime;
  }
  
  // Check for environmental alerts
  checkEnvironmentalAlerts();
  
  delay(100);
}

void connectToWiFi() {
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    setStatusLED(255, 255, 0); // Yellow - connecting
  }
  
  Serial.println();
  Serial.print("Connected! IP address: ");
  Serial.println(WiFi.localIP());
  setStatusLED(0, 255, 0); // Green - connected
}

void readSensors() {
  // Read DHT22 sensor
  temperature = dht.readTemperature();
  humidity = dht.readHumidity();
  
  // Read ultrasonic sensor for container level
  containerLevel = readUltrasonicLevel();
  
  // Print sensor values
  Serial.print("Temperature: ");
  Serial.print(temperature);
  Serial.print("°C, Humidity: ");
  Serial.print(humidity);
  Serial.print("%, Level: ");
  Serial.print(containerLevel);
  Serial.println("%");
}

float readUltrasonicLevel() {
  // Trigger ultrasonic sensor
  digitalWrite(ULTRASONIC_TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(ULTRASONIC_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(ULTRASONIC_TRIG, LOW);
  
  // Read echo
  long duration = pulseIn(ULTRASONIC_ECHO, HIGH);
  float distance = (duration * 0.034) / 2; // Convert to cm
  
  // Convert distance to level percentage
  float level = ((EMPTY_DISTANCE_CM - distance) / EMPTY_DISTANCE_CM) * 100.0;
  return constrain(level, 0, 100);
}

void sendSensorData() {
  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();
    return;
  }
  
  WiFiClient client;
  HTTPClient http;
  
  String url = String(supabaseUrl) + "/rest/v1/environmental_data";
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + String(supabaseKey));
  http.addHeader("apikey", supabaseKey);
  
  // Create JSON payload
  StaticJsonDocument<200> doc;
  doc["temperature"] = temperature;
  doc["humidity"] = humidity;
  doc["container_level"] = containerLevel;
  doc["timestamp"] = getTimestamp();
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  int httpResponseCode = http.POST(jsonString);
  
  if (httpResponseCode > 0) {
    Serial.print("HTTP Response: ");
    Serial.println(httpResponseCode);
  } else {
    Serial.print("HTTP Error: ");
    Serial.println(httpResponseCode);
  }
  
  http.end();
}

void updateStatusLED() {
  // Set LED color based on system status
  if (WiFi.status() != WL_CONNECTED) {
    setStatusLED(255, 255, 0); // Yellow - no WiFi
  } else if (containerLevel < 10) {
    setStatusLED(255, 0, 0); // Red - low level
  } else if (temperature > 35 || humidity > 80) {
    setStatusLED(255, 165, 0); // Orange - environmental warning
  } else {
    setStatusLED(0, 255, 0); // Green - all good
  }
}

void setStatusLED(int red, int green, int blue) {
  analogWrite(STATUS_LED_RED, red);
  analogWrite(STATUS_LED_GREEN, green);
  analogWrite(STATUS_LED_BLUE, blue);
}

void checkEnvironmentalAlerts() {
  static unsigned long lastAlert = 0;
  unsigned long currentTime = millis();
  
  // Alert if temperature too high or humidity too high
  if ((temperature > 35 || humidity > 80) && 
      (currentTime - lastAlert > 30000)) { // Alert every 30 seconds
    
    soundAlert();
    lastAlert = currentTime;
    Serial.println("Environmental alert triggered!");
  }
}

void soundAlert() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(200);
    digitalWrite(BUZZER_PIN, LOW);
    delay(200);
  }
}

String getTimestamp() {
  // Simple timestamp - in production, sync with NTP
  return String(millis());
}