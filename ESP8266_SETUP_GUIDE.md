# ESP8266 Setup Guide for Smart Rice Dispenser

## Hardware Requirements

### ESP8266 Controllers (3 units)
- **ESP8266 NodeMCU v1.0** (recommended) or ESP8266 Wemos D1 Mini
- Each ESP8266 handles different aspects of the system

### Controller 1 (esp1.cpp) - Main Controller
**Components:**
- HX711 Load Cell Amplifier
- 5kg Load Cell (or appropriate for rice container)
- Servo Motor (SG90 or similar)
- LED (status indicator)
- Push button (manual operation)

**Connections:**
```
ESP8266 NodeMCU → Component
D4 (GPIO2)      → HX711 DOUT
D5 (GPIO14)     → HX711 SCK
D6 (GPIO12)     → Servo Signal
D7 (GPIO13)     → LED (with 220Ω resistor)
D3 (GPIO0)      → Push Button (with pull-up)
3V3             → HX711 VCC, Servo VCC
GND             → Common Ground
```

### Controller 2 (esp2.cpp) - Sensor Controller
**Components:**
- DHT22 Temperature/Humidity Sensor
- HC-SR04 Ultrasonic Sensor
- RGB LED (common cathode)
- Piezo Buzzer

**Connections:**
```
ESP8266 NodeMCU → Component
D2 (GPIO4)      → DHT22 Data
D8 (GPIO15)     → HC-SR04 Trig
D0 (GPIO16)     → HC-SR04 Echo
D1 (GPIO5)      → RGB LED Red
D7 (GPIO13)     → RGB LED Green
D6 (GPIO12)     → RGB LED Blue
D5 (GPIO14)     → Buzzer Positive
3V3             → DHT22 VCC, HC-SR04 VCC
GND             → Common Ground
```

### Controller 3 (esp3.cpp) - Display Controller
**Components:**
- SSD1306 OLED Display (128x64, I2C)
- 3x Push Buttons (Up, Down, Select)
- Rotary Encoder (optional)
- Backlight LED

**Connections:**
```
ESP8266 NodeMCU → Component
D1 (GPIO5)      → OLED SDA
D2 (GPIO4)      → OLED SCL
D3 (GPIO0)      → Button Up
D4 (GPIO2)      → Button Down
D0 (GPIO16)     → Button Select
D5 (GPIO14)     → Encoder A (optional)
D6 (GPIO12)     → Encoder B (optional)
D7 (GPIO13)     → Backlight LED
3V3             → OLED VCC
GND             → Common Ground
```

## Software Setup

### Arduino IDE Configuration

1. **Install ESP8266 Board Package:**
   - File → Preferences
   - Add to Additional Board Manager URLs:
     ```
     https://arduino.esp8266.com/stable/package_esp8266com_index.json
     ```
   - Tools → Board → Board Manager
   - Search "ESP8266" and install

2. **Select Board:**
   - Tools → Board → ESP8266 Boards → NodeMCU 1.0 (ESP-12E Module)

3. **Board Settings:**
   ```
   Upload Speed: 115200
   CPU Frequency: 80 MHz
   Flash Size: 4MB (FS:2MB OTA:~1019KB)
   Debug Port: Disabled
   Debug Level: None
   lwIP Variant: v2 Lower Memory
   VTables: Flash
   Exceptions: Legacy (new can return nullptr)
   Erase Flash: Only Sketch
   SSL Support: All SSL ciphers (most compatible)
   ```

### Required Libraries

Install these libraries via Arduino IDE Library Manager:

```
1. ESP8266WiFi (included with ESP8266 core)
2. ESP8266HTTPClient (included with ESP8266 core)
3. ArduinoJson by Benoit Blanchon (v6.21.3 or later)
4. HX711 Library by Rob Tillaart
5. Servo (included with Arduino IDE)
6. DHT sensor library by Adafruit
7. Adafruit Unified Sensor
8. Adafruit SSD1306
9. Adafruit GFX Library
```

### WiFi and Supabase Configuration

1. **Update WiFi credentials in all three files:**
   ```cpp
   const char* ssid = "Your_WiFi_Name";
   const char* password = "Your_WiFi_Password";
   ```

2. **Update Supabase configuration:**
   ```cpp
   const char* supabaseUrl = "https://your-project.supabase.co";
   const char* supabaseKey = "your-anon-key";
   ```

## Deployment Steps

### 1. Upload Code to Each ESP8266

**For Controller 1 (Main):**
```bash
# Connect ESP8266 #1 to computer
# Select correct COM port in Arduino IDE
# Upload esp1.cpp
```

**For Controller 2 (Sensors):**
```bash
# Connect ESP8266 #2 to computer
# Upload esp2.cpp
```

**For Controller 3 (Display):**
```bash
# Connect ESP8266 #3 to computer
# Upload esp3.cpp
```

### 2. Hardware Assembly

1. **Load Cell Setup:**
   - Mount load cell under rice container
   - Connect to HX711 amplifier
   - Calibrate using known weights

2. **Servo Motor:**
   - Mount to control rice dispensing mechanism
   - Test range of motion (0-180 degrees)

3. **Sensor Placement:**
   - DHT22: Protected from moisture but able to measure ambient conditions
   - Ultrasonic: Positioned to measure rice level in container

4. **Display Mount:**
   - OLED display in user-accessible location
   - Buttons for easy operation

### 3. System Testing

**Individual Controller Tests:**
```cpp
// Upload test sketches to verify each controller independently
// Check serial monitor for debug output
// Verify all sensors reading correctly
```

**Integration Testing:**
```cpp
// All controllers should connect to same WiFi
// Verify data flows to Supabase database
// Test Flutter app receives real-time updates
```

## Troubleshooting

### Common Issues:

1. **WiFi Connection Problems:**
   - Check credentials
   - Verify network is 2.4GHz (ESP8266 doesn't support 5GHz)
   - Check signal strength

2. **HX711 Load Cell Issues:**
   - Verify wiring connections
   - Check calibration factor
   - Ensure stable mounting

3. **OLED Display Not Working:**
   - Check I2C address (usually 0x3C)
   - Verify SDA/SCL connections
   - Test with simple display sketch

4. **Supabase Connection Issues:**
   - Verify URL and API key
   - Check database table structure
   - Test with demo mode first

### Debug Commands:

```cpp
// Add to setup() function for debugging
Serial.begin(115200);
Serial.println("Starting ESP8266...");
WiFi.begin(ssid, password);
while (WiFi.status() != WL_CONNECTED) {
  delay(1000);
  Serial.println("Connecting to WiFi...");
}
Serial.print("Connected! IP: ");
Serial.println(WiFi.localIP());
```

## Power Considerations

- **Power Supply:** 5V 2A recommended for stable operation
- **Current Draw:** ~200-300mA per ESP8266 under normal operation
- **Power-Saving:** Consider deep sleep modes for battery operation

## Security Notes

- Change default WiFi credentials
- Use environment variables for sensitive data in production
- Enable HTTPS for Supabase connections
- Consider WPA3 security for WiFi network

---

This setup provides a complete IoT solution with redundancy and modular design. Each ESP8266 can operate independently, making debugging and maintenance easier.
