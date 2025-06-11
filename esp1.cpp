// ESP8266 Arduino Code for Smart Rice Dispenser - Main Controller
// esp1.cpp - Load Cell and Motor Control

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClient.h>
#include <ArduinoJson.h>
#include <HX711.h>
#include <Servo.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Supabase configuration
const char* supabaseUrl = "YOUR_SUPABASE_URL";
const char* supabaseKey = "YOUR_SUPABASE_KEY";

// Hardware pins (ESP8266 NodeMCU)
#define LOADCELL_DOUT_PIN  D4  // GPIO2
#define LOADCELL_SCK_PIN   D5  // GPIO14
#define SERVO_PIN          D6  // GPIO12
#define LED_PIN           D7  // GPIO13
#define BUTTON_PIN        D3  // GPIO0

// Hardware objects
HX711 scale;
Servo dispenserServo;

// Calibration values
const float CALIBRATION_FACTOR = -7050.0; // Adjust based on your load cell
const float RICE_DENSITY_FACTOR = 0.8; // Approximate grams per mL for rice

// System state
float currentWeight = 0.0;
float targetWeight = 0.0;
bool isDispensing = false;
unsigned long lastWeightRead = 0;
unsigned long lastDataSend = 0;
const unsigned long WEIGHT_READ_INTERVAL = 1000; // 1 second
const unsigned long DATA_SEND_INTERVAL = 5000;   // 5 seconds

void setup() {
  Serial.begin(115200);
  
  // Initialize hardware
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  
  // Initialize load cell
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(CALIBRATION_FACTOR);
  scale.tare(); // Reset to zero
  
  // Initialize servo
  dispenserServo.attach(SERVO_PIN);
  dispenserServo.write(0); // Closed position
  
  // Connect to WiFi
  connectToWiFi();
  
  Serial.println("Smart Rice Dispenser initialized!");
  digitalWrite(LED_PIN, HIGH); // Ready indicator
}

void loop() {
  unsigned long currentTime = millis();
  
  // Read weight sensor
  if (currentTime - lastWeightRead >= WEIGHT_READ_INTERVAL) {
    readWeight();
    lastWeightRead = currentTime;
  }
  
  // Send data to Supabase
  if (currentTime - lastDataSend >= DATA_SEND_INTERVAL) {
    sendWeightData();
    lastDataSend = currentTime;
  }
  
  // Check for manual dispense button
  if (digitalRead(BUTTON_PIN) == LOW && !isDispensing) {
    // Manual dispense 50g
    startDispensing(50.0);
  }
  
  // Handle dispensing process
  if (isDispensing) {
    handleDispensing();
  }
  
  delay(100);
}

void connectToWiFi() {
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println();
  Serial.print("Connected! IP address: ");
  Serial.println(WiFi.localIP());
}

void readWeight() {
  if (scale.is_ready()) {
    currentWeight = scale.get_units(5); // Average of 5 readings
    if (currentWeight < 0) currentWeight = 0; // Prevent negative weights
    
    Serial.print("Current weight: ");
    Serial.print(currentWeight);
    Serial.println(" g");
  }
}

void sendWeightData() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(String(supabaseUrl) + "/rest/v1/rice_weights");
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", supabaseKey);
    http.addHeader("Authorization", "Bearer " + String(supabaseKey));
    
    // Create JSON payload
    DynamicJsonDocument doc(1024);
    doc["weight"] = currentWeight;
    doc["timestamp"] = getCurrentTimestamp();
    doc["device_id"] = "ESP32_001";
    
    String payload;
    serializeJson(doc, payload);
    
    int httpResponseCode = http.POST(payload);
    
    if (httpResponseCode > 0) {
      String response = http.getString();
      Serial.println("Data sent successfully");
    } else {
      Serial.print("Error sending data: ");
      Serial.println(httpResponseCode);
    }
    
    http.end();
  }
}

void startDispensing(float weight) {
  targetWeight = weight;
  isDispensing = true;
  
  Serial.print("Starting dispensing: ");
  Serial.print(targetWeight);
  Serial.println(" g");
  
  // Open dispenser
  dispenserServo.write(90); // Open position
  
  // Log dispensing start
  logDispenseEvent("start", targetWeight);
}

void handleDispensing() {
  float dispensedWeight = getDispensedWeight();
  
  if (dispensedWeight >= targetWeight) {
    // Target reached, stop dispensing
    dispenserServo.write(0); // Close position
    isDispensing = false;
    
    Serial.print("Dispensing complete: ");
    Serial.print(dispensedWeight);
    Serial.println(" g");
    
    // Log dispensing completion
    logDispenseEvent("complete", dispensedWeight);
    
    // Flash LED to indicate completion
    for (int i = 0; i < 3; i++) {
      digitalWrite(LED_PIN, LOW);
      delay(200);
      digitalWrite(LED_PIN, HIGH);
      delay(200);
    }
  }
}

float getDispensedWeight() {
  // This would be calculated based on the weight difference
  // from when dispensing started
  static float initialWeight = 0;
  if (isDispensing && initialWeight == 0) {
    initialWeight = currentWeight;
  }
  
  if (!isDispensing) {
    initialWeight = 0;
    return 0;
  }
  
  return initialWeight - currentWeight;
}

void logDispenseEvent(String action, float weight) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(String(supabaseUrl) + "/rest/v1/dispense_history");
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", supabaseKey);
    http.addHeader("Authorization", "Bearer " + String(supabaseKey));
    
    DynamicJsonDocument doc(1024);
    doc["action"] = action;
    doc["weight"] = weight;
    doc["timestamp"] = getCurrentTimestamp();
    doc["device_id"] = "ESP32_001";
    
    String payload;
    serializeJson(doc, payload);
    
    http.POST(payload);
    http.end();
  }
}

String getCurrentTimestamp() {
  // In a real implementation, you would use an NTP client
  // to get the actual current time
  return String(millis());
}

// Web server handlers for remote control
void handleRemoteDispense() {
  // This would handle remote dispensing requests from the Flutter app
  // Implementation would depend on your communication protocol
}