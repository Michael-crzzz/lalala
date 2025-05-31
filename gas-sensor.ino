#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <HardwareSerial.h>
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>

// --- WiFi ---
#define WIFI_SSID     "Chuacakes"
#define WIFI_PASSWORD "YcfhX5Bm"

// --- Firebase ---
#define FIREBASE_HOST "https://gas-sensor-befe7-default-rtdb.firebaseio.com/"
#define FIREBASE_PATH "/gas_sensor/latest_reading"
#define FIREBASE_AUTH ""

// --- Pins ---
#define MQ2_PIN        34
#define RED_LED        25
#define GREEN_LED      26
#define BUZZER1_PIN    13
#define BUZZER2_PIN    14

// --- TFT Config ---
#define TFT_CS   5
#define TFT_RST  4
#define TFT_DC   2
Adafruit_ILI9341 tft = Adafruit_ILI9341(TFT_CS, TFT_DC, TFT_RST);

// --- GSM Serial2 ---
HardwareSerial sim900(2);  // RX=16, TX=17

bool gasNormal = true;

void waitForResponse();

void setup() {
  Serial.begin(115200);
  sim900.begin(9600, SERIAL_8N1, 16, 17);  // GSM RX/TX

  pinMode(MQ2_PIN, INPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  pinMode(BUZZER1_PIN, OUTPUT);
  pinMode(BUZZER2_PIN, OUTPUT);

  initTFT();
  initWiFi();
  initGSM();

  displayText("Gas Sensor System", 10, ILI9341_WHITE, 2, true);
  displayText("Initializing...", 50, ILI9341_YELLOW, 2, true);
  delay(2000);
}

void loop() {
  int gasValue = analogRead(MQ2_PIN);
  Serial.print("Gas Value: ");
  Serial.println(gasValue);

  sendToFirebase(gasValue);
  updateTFT(gasValue);

  if (gasValue >= 1000 && gasNormal) {
    triggerAlert("ALERT! HIGH GAS LEVEL", 3);
    sendSMS("+639641799863", "ALERT: Dangerous gas levels detected.");
    gasNormal = false;
  } else if (gasValue < 1000 && !gasNormal) {
    resetAlert("Gas Level Normal", 2);
    gasNormal = true;
  }

  delay(3000);
}

void initWiFi() {
  displayText("Connecting to WiFi...", 100, ILI9341_WHITE, 2, true);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected.");
  displayText("WiFi Connected!", 100, ILI9341_GREEN, 2, true);
}

void initTFT() {
  tft.begin();
  tft.setRotation(1);
  tft.fillScreen(ILI9341_BLACK);
}

void waitForResponse() {
  unsigned long timeout = millis() + 5000;
  while (millis() < timeout) {
    while (sim900.available()) {
      Serial.write(sim900.read());
    }
  }
}


void initGSM() {
  Serial.println("Initializing GSM...");
  delay(3000);
  sim900.println("AT"); waitForResponse();
  sim900.println("AT+CMGF=1"); waitForResponse();
  sim900.println("AT+CSCS=\"GSM\""); waitForResponse();
}

void sendSMS(String number, String text) {
  Serial.println("Sending SMS...");
  sim900.print("AT+CMGS=\""); sim900.print(number); sim900.println("\"");
  delay(1000);
  sim900.print(text);
  sim900.write(26);  // Ctrl+Z
  waitForResponse();
}

void sendToFirebase(int gasValue) {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure client;
    client.setInsecure();  // ⚠️ Insecure TLS

    HTTPClient https;
    String url = String(FIREBASE_HOST) + FIREBASE_PATH + ".json";
    if (strlen(FIREBASE_AUTH) > 0) {
      url += "?auth=" + String(FIREBASE_AUTH);
    }

    if (https.begin(client, url)) {
      https.addHeader("Content-Type", "application/json");
      String payload = "{\"value\":" + String(gasValue) + ",\"timestamp\":" + String(millis() / 1000) + "}";

      int code = https.PUT(payload);
      if (code > 0) {
        Serial.print("Firebase sent. Code: ");
        Serial.println(code);
      } else {
        Serial.print("Firebase error: ");
        Serial.println(https.errorToString(code));
      }

      https.end();
    }
  } else {
    Serial.println("WiFi not connected.");
  }
}

void updateTFT(int value) {
  tft.fillRect(0, 0, 320, 100, ILI9341_BLACK); // Clear display area
  displayText("Gas Value", 10, ILI9341_WHITE, 2, false);
  displayText(String(value), 50, ILI9341_CYAN, 4, true);  // Bigger value text
}

void triggerAlert(String message, int textSize) {
  digitalWrite(RED_LED, HIGH);
  digitalWrite(GREEN_LED, LOW);
  digitalWrite(BUZZER1_PIN, HIGH);
  digitalWrite(BUZZER2_PIN, HIGH);
  tft.fillRect(0, 100, 320, 60, ILI9341_RED);
  displayText(message, 110, ILI9341_WHITE, textSize, true);
}

void resetAlert(String message, int textSize) {
  digitalWrite(RED_LED, LOW);
  digitalWrite(GREEN_LED, HIGH);
  digitalWrite(BUZZER1_PIN, LOW);
  digitalWrite(BUZZER2_PIN, LOW);
  tft.fillRect(0, 100, 320, 60, ILI9341_BLACK);
  displayText(message, 110, ILI9341_GREEN, textSize, true);
}

// Updated displayText with size and background clear option
void displayText(String text, int y, uint16_t color, int size, bool clearLine) {
  tft.setTextSize(size);
  tft.setTextColor(color);

  int16_t x1, y1;
  uint16_t w, h;
  tft.getTextBounds(text, 0, y, &x1, &y1, &w, &h);

  int x = (tft.width() - w) / 2;

  if (clearLine) {
    tft.fillRect(0, y, 320, h + 4, ILI9341_BLACK);  // Clear background
  }

  tft.setCursor(x, y);
  tft.print(text);
}
