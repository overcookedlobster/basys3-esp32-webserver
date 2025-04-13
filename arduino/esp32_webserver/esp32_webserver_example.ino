// REMOVE THE _EXAMPLE, so the filename should be esp32_webserver.ino, following the arduino convention
#include <WiFi.h>
#include <WebServer.h>

// Wi-Fi credentials
const char* ssid = "YOUR_WIFI_NETWORK";
const char* password = "YOUR_WIFI_PASSWORD";

// Web server port
WebServer server(8000);

// UART pins for communication with FPGA
#define RX_PIN 16  // Connect to FPGA TX
#define TX_PIN 17  // Connect to FPGA RX (futureproofing yo)

// Global variables to store button and switch states
byte buttons = 0;
byte switches_low = 0;
byte switches_high = 0;

// Function to handle root path
void handleRoot() {
  String html = "<!DOCTYPE html>\n";
  html += "<html>\n";
  html += "<head>\n";
  html += "  <title>FPGA Button and Switch Status</title>\n";
  html += "  <meta name='viewport' content='width=device-width, initial-scale=1'>\n";
  html += "  <style>\n";
  html += "    body { font-family: Arial, sans-serif; margin: 20px; }\n";
  html += "    h1 { color: #2c3e50; }\n";
  html += "    .container { display: flex; flex-wrap: wrap; }\n";
  html += "    .section { margin-right: 40px; margin-bottom: 20px; }\n";
  html += "    .state { display: inline-block; width: 80px; text-align: center; padding: 10px; margin: 5px; }\n";
  html += "    .pressed { background-color: #27ae60; color: white; }\n";
  html += "    .released { background-color: #e74c3c; color: white; }\n";
  html += "    .on { background-color: #2980b9; color: white; }\n";
  html += "    .off { background-color: #7f8c8d; color: white; }\n";
  html += "  </style>\n";
  html += "  <script>\n";
  html += "    setInterval(function() { location.reload(); }, 1000);\n";
  html += "  </script>\n";
  html += "</head>\n";
  html += "<body>\n";
  html += "  <h1>FPGA Button Status</h1>\n";

  // Button section
  html += "  <div class='section'>\n";
  html += "    <h2>Buttons</h2>\n";
  html += "    <div class='container'>\n";
  html += "      <div class='state " + String((buttons & 0x01) ? "pressed" : "released") + "'>Center: " + String((buttons & 0x01) ? "Pressed" : "Released") + "</div>\n";
  html += "      <div class='state " + String((buttons & 0x02) ? "pressed" : "released") + "'>Up: " + String((buttons & 0x02) ? "Pressed" : "Released") + "</div>\n";
  html += "      <div class='state " + String((buttons & 0x04) ? "pressed" : "released") + "'>Left: " + String((buttons & 0x04) ? "Pressed" : "Released") + "</div>\n";
  html += "      <div class='state " + String((buttons & 0x08) ? "pressed" : "released") + "'>Right: " + String((buttons & 0x08) ? "Pressed" : "Released") + "</div>\n";
  html += "      <div class='state " + String((buttons & 0x10) ? "pressed" : "released") + "'>Down: " + String((buttons & 0x10) ? "Pressed" : "Released") + "</div>\n";
  html += "    </div>\n";
  html += "  </div>\n";

  html += "    </div>\n";
  html += "  </div>\n";

  html += "</body>\n";
  html += "</html>\n";

  server.send(200, "text/html", html);
}

void setup() {
  // Start serial communication for debugging
  Serial.begin(115200);
  Serial.println("Booting ESP32...");

  // Configure UART for FPGA communication
  Serial1.begin(115200, SERIAL_8N1, RX_PIN, TX_PIN);

  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.print("Connected to WiFi. IP address: ");
  Serial.println(WiFi.localIP());

  // Set up web server handlers
  server.on("/", handleRoot);
  server.begin();
  Serial.print("Web server started on port 8000. Visit http://");
  Serial.print(WiFi.localIP());
  Serial.println(":8000 to view the FPGA status.");
}

void loop() {
  // Handle incoming web clients
  server.handleClient();

  // Read data from FPGA via UART
  if (Serial1.available() >= 3) {
    buttons = Serial1.read();
    switches_low = Serial1.read();
    switches_high = Serial1.read();

    // Print received data for debugging
    Serial.print("Received from FPGA - Buttons: 0x");
    Serial.print(buttons, HEX);
  }
  // Add this in the loop() function of the ESP32 code
  static unsigned long lastDebugTime = 0;
  if (millis() - lastDebugTime > 5000) { // Every 5 seconds
    lastDebugTime = millis();
    Serial.println("ESP32 Debug:");
    Serial.print("UART RX Pin: ");
    Serial.println(RX_PIN);
    Serial.print("Data received: Buttons=0x");
    Serial.print(buttons, HEX);
  }
  // Small delay to prevent tight looping
  delay(10);
}
