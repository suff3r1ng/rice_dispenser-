// ESP8266 Arduino Code for Smart Rice Dispenser - Display Controller
// esp3.cpp - OLED Display and User Interface

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Supabase configuration
const char* supabaseUrl = "YOUR_SUPABASE_URL";
const char* supabaseKey = "YOUR_SUPABASE_KEY";

// Display configuration
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET     -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Hardware pins (ESP8266 NodeMCU)
#define BUTTON_UP     D3  // GPIO0
#define BUTTON_DOWN   D4  // GPIO2
#define BUTTON_SELECT D0  // GPIO16
#define ENCODER_A     D5  // GPIO14
#define ENCODER_B     D6  // GPIO12
#define BACKLIGHT_PIN D7  // GPIO13

// System state
struct SystemData {
  float currentWeight;
  float targetWeight;
  float temperature;
  float humidity;
  float containerLevel;
  String dispenserStatus;
  bool isConnected;
};

SystemData systemData;
int currentMenu = 0;
int selectedAmount = 100; // grams
bool backlightOn = true;
unsigned long lastDataFetch = 0;
unsigned long lastDisplayUpdate = 0;
unsigned long lastButtonPress = 0;
const unsigned long DATA_FETCH_INTERVAL = 5000;   // 5 seconds
const unsigned long DISPLAY_UPDATE_INTERVAL = 500; // 0.5 seconds
const unsigned long BACKLIGHT_TIMEOUT = 30000;    // 30 seconds

// Menu system
enum MenuState {
  MENU_HOME,
  MENU_DISPENSE,
  MENU_STATUS,
  MENU_SETTINGS
};

MenuState currentMenuState = MENU_HOME;

void setup() {
  Serial.begin(115200);
  
  // Initialize hardware
  pinMode(BUTTON_UP, INPUT_PULLUP);
  pinMode(BUTTON_DOWN, INPUT_PULLUP);
  pinMode(BUTTON_SELECT, INPUT_PULLUP);
  pinMode(ENCODER_A, INPUT_PULLUP);
  pinMode(ENCODER_B, INPUT_PULLUP);
  pinMode(BACKLIGHT_PIN, OUTPUT);
  
  // Initialize display
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
    for (;;);
  }
  
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println(F("Smart Rice Dispenser"));
  display.println(F("Initializing..."));
  display.display();
  
  // Connect to WiFi
  connectToWiFi();
  
  // Initialize system data
  initializeSystemData();
  
  // Turn on backlight
  digitalWrite(BACKLIGHT_PIN, HIGH);
  
  Serial.println("ESP8266 Display Controller Ready");
}

void loop() {
  unsigned long currentTime = millis();
  
  // Handle button inputs
  handleButtons();
  
  // Fetch data from server periodically
  if (currentTime - lastDataFetch >= DATA_FETCH_INTERVAL) {
    fetchSystemData();
    lastDataFetch = currentTime;
  }
  
  // Update display periodically
  if (currentTime - lastDisplayUpdate >= DISPLAY_UPDATE_INTERVAL) {
    updateDisplay();
    lastDisplayUpdate = currentTime;
  }
  
  // Handle backlight timeout
  if (backlightOn && (currentTime - lastButtonPress > BACKLIGHT_TIMEOUT)) {
    digitalWrite(BACKLIGHT_PIN, LOW);
    backlightOn = false;
  }
  
  delay(50);
}

void connectToWiFi() {
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    
    display.clearDisplay();
    display.setCursor(0, 20);
    display.println(F("Connecting to WiFi..."));
    display.display();
  }
  
  Serial.println();
  Serial.print("Connected! IP address: ");
  Serial.println(WiFi.localIP());
  
  display.clearDisplay();
  display.setCursor(0, 20);
  display.println(F("WiFi Connected!"));
  display.display();
  delay(2000);
}

void initializeSystemData() {
  systemData.currentWeight = 0.0;
  systemData.targetWeight = 0.0;
  systemData.temperature = 0.0;
  systemData.humidity = 0.0;
  systemData.containerLevel = 0.0;
  systemData.dispenserStatus = "Ready";
  systemData.isConnected = false;
}

void handleButtons() {
  static bool buttonUpPressed = false;
  static bool buttonDownPressed = false;
  static bool buttonSelectPressed = false;
  
  bool upState = !digitalRead(BUTTON_UP);
  bool downState = !digitalRead(BUTTON_DOWN);
  bool selectState = !digitalRead(BUTTON_SELECT);
  
  // Button UP
  if (upState && !buttonUpPressed) {
    handleButtonUp();
    lastButtonPress = millis();
    if (!backlightOn) {
      digitalWrite(BACKLIGHT_PIN, HIGH);
      backlightOn = true;
    }
  }
  buttonUpPressed = upState;
  
  // Button DOWN
  if (downState && !buttonDownPressed) {
    handleButtonDown();
    lastButtonPress = millis();
    if (!backlightOn) {
      digitalWrite(BACKLIGHT_PIN, HIGH);
      backlightOn = true;
    }
  }
  buttonDownPressed = downState;
  
  // Button SELECT
  if (selectState && !buttonSelectPressed) {
    handleButtonSelect();
    lastButtonPress = millis();
    if (!backlightOn) {
      digitalWrite(BACKLIGHT_PIN, HIGH);
      backlightOn = true;
    }
  }
  buttonSelectPressed = selectState;
}

void handleButtonUp() {
  switch (currentMenuState) {
    case MENU_HOME:
      currentMenuState = MENU_SETTINGS;
      break;
    case MENU_DISPENSE:
      selectedAmount = min(selectedAmount + 50, 1000);
      break;
    case MENU_STATUS:
      currentMenuState = MENU_HOME;
      break;
    case MENU_SETTINGS:
      currentMenuState = MENU_STATUS;
      break;
  }
}

void handleButtonDown() {
  switch (currentMenuState) {
    case MENU_HOME:
      currentMenuState = MENU_DISPENSE;
      break;
    case MENU_DISPENSE:
      selectedAmount = max(selectedAmount - 50, 50);
      break;
    case MENU_STATUS:
      currentMenuState = MENU_SETTINGS;
      break;
    case MENU_SETTINGS:
      currentMenuState = MENU_HOME;
      break;
  }
}

void handleButtonSelect() {
  switch (currentMenuState) {
    case MENU_HOME:
      currentMenuState = MENU_DISPENSE;
      break;
    case MENU_DISPENSE:
      requestDispense(selectedAmount);
      break;
    case MENU_STATUS:
      // Refresh data
      fetchSystemData();
      break;
    case MENU_SETTINGS:
      // Toggle backlight or other settings
      break;
  }
}

void updateDisplay() {
  display.clearDisplay();
  
  switch (currentMenuState) {
    case MENU_HOME:
      drawHomeScreen();
      break;
    case MENU_DISPENSE:
      drawDispenseScreen();
      break;
    case MENU_STATUS:
      drawStatusScreen();
      break;
    case MENU_SETTINGS:
      drawSettingsScreen();
      break;
  }
  
  display.display();
}

void drawHomeScreen() {
  display.setTextSize(2);
  display.setCursor(0, 0);
  display.println(F("RICE"));
  display.println(F("DISPENSER"));
  
  display.setTextSize(1);
  display.setCursor(0, 40);
  display.print(F("Weight: "));
  display.print(systemData.currentWeight, 0);
  display.println(F("g"));
  
  display.setCursor(0, 50);
  display.print(F("Level: "));
  display.print(systemData.containerLevel, 0);
  display.println(F("%"));
  
  // Navigation hint
  display.setCursor(90, 56);
  display.println(F("MENU"));
}

void drawDispenseScreen() {
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println(F("DISPENSE RICE"));
  
  display.setTextSize(2);
  display.setCursor(0, 20);
  display.print(selectedAmount);
  display.println(F("g"));
  
  display.setTextSize(1);
  display.setCursor(0, 45);
  display.println(F("UP/DOWN: Adjust"));
  display.setCursor(0, 55);
  display.println(F("SELECT: Dispense"));
}

void drawStatusScreen() {
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println(F("SYSTEM STATUS"));
  
  display.setCursor(0, 15);
  display.print(F("Temp: "));
  display.print(systemData.temperature, 1);
  display.println(F("C"));
  
  display.setCursor(0, 25);
  display.print(F("Humidity: "));
  display.print(systemData.humidity, 1);
  display.println(F("%"));
  
  display.setCursor(0, 35);
  display.print(F("Status: "));
  display.println(systemData.dispenserStatus);
  
  display.setCursor(0, 45);
  display.print(F("WiFi: "));
  display.println(systemData.isConnected ? F("OK") : F("FAIL"));
}

void drawSettingsScreen() {
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println(F("SETTINGS"));
  
  display.setCursor(0, 15);
  display.println(F("Backlight: ON"));
  
  display.setCursor(0, 25);
  display.print(F("IP: "));
  display.println(WiFi.localIP());
  
  display.setCursor(0, 45);
  display.println(F("SELECT: Toggle"));
}

void fetchSystemData() {
  if (WiFi.status() != WL_CONNECTED) {
    systemData.isConnected = false;
    return;
  }
  
  WiFiClient client;
  HTTPClient http;
  
  // Fetch latest rice weight
  String url = String(supabaseUrl) + "/rest/v1/rice_weight?select=*&order=timestamp.desc&limit=1";
  http.begin(client, url);
  http.addHeader("Authorization", "Bearer " + String(supabaseKey));
  http.addHeader("apikey", supabaseKey);
  
  int httpResponseCode = http.GET();
  
  if (httpResponseCode == 200) {
    String response = http.getString();
    parseSystemData(response);
    systemData.isConnected = true;
  } else {
    systemData.isConnected = false;
  }
  
  http.end();
}

void parseSystemData(String jsonResponse) {
  StaticJsonDocument<512> doc;
  deserializeJson(doc, jsonResponse);
  
  if (doc.size() > 0) {
    JsonObject data = doc[0];
    systemData.currentWeight = data["weight_grams"];
    systemData.dispenserStatus = data["level_state"].as<String>();
  }
}

void requestDispense(int grams) {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }
  
  WiFiClient client;
  HTTPClient http;
  
  String url = String(supabaseUrl) + "/rest/v1/dispense_requests";
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + String(supabaseKey));
  http.addHeader("apikey", supabaseKey);
  
  StaticJsonDocument<200> doc;
  doc["requested_grams"] = grams;
  doc["requested_cups"] = grams / 200.0;
  doc["status"] = "pending";
  doc["dispensed_grams"] = 0;
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  int httpResponseCode = http.POST(jsonString);
  
  if (httpResponseCode > 0) {
    Serial.print("Dispense request sent: ");
    Serial.println(httpResponseCode);
    
    // Show confirmation on display
    display.clearDisplay();
    display.setTextSize(1);
    display.setCursor(0, 20);
    display.println(F("Dispense Request"));
    display.println(F("Sent!"));
    display.display();
    delay(2000);
  }
  
  http.end();
}