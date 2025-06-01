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
#define FIREBASE_AUTH "o7dlAGo8VCykBrxapemvpg4yKjJr2qzkpHrl6VGZ"

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
  sim900.begin(9600, SERIAL_8N1, 16, 17);

  pinMode(MQ2_PIN, INPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  pinMode(BUZZER1_PIN, OUTPUT);
  pinMode(BUZZER2_PIN, OUTPUT);

  initTFT();
  initWiFi();      // <--- Make sure WiFi is connected first!
  initGSM();

  // Now do NTP sync
  configTime(28800, 0, "time.google.com");
  Serial.print("Waiting for NTP time sync");
  time_t now = time(nullptr);
  while (now < 8 * 3600 * 2) {
    delay(500);
    Serial.print(".");
    now = time(nullptr);
  }
  Serial.println("\nTime synchronized!");

  displayText("Gas Sensor System", 10, ILI9341_WHITE, 2, true);
  displayText("Initializing...", 50, ILI9341_YELLOW, 2, true);
  delay(2000);
}

void loop() {
  int gasValue = analogRead(MQ2_PIN);
  Serial.print("Gas Value: ");
  Serial.println(gasValue);

  sendToFirebase(gasValue);
  updateDailyGasStats(gasValue); // <-- Update daily stats for graph
  sendToSensorData(gasValue);
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

// --- Update gas_stats/daily for graph ---
void updateDailyGasStats(int gasValue) {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure client;
    client.setInsecure();

    // 1. Read current daily array
    HTTPClient httpsGet;
    String getUrl = String(FIREBASE_HOST) + "/gas_stats/daily.json";
    if (strlen(FIREBASE_AUTH) > 0) {
      getUrl += "?auth=" + String(FIREBASE_AUTH);
    }
    String dailyArray = "[]";
    if (httpsGet.begin(client, getUrl)) {
      int httpCode = httpsGet.GET();
      if (httpCode == HTTP_CODE_OK) {
        dailyArray = httpsGet.getString();
      }
      httpsGet.end();
    }

    // 2. Parse and update the array
    int daily[7] = {0,0,0,0,0,0,0};
    int idx = 0;
    int last = 0;
    dailyArray.replace("[", "");
    dailyArray.replace("]", "");
    for (int i = 0; i < 7; i++) {
      idx = dailyArray.indexOf(",", last);
      String val = (idx == -1) ? dailyArray.substring(last) : dailyArray.substring(last, idx);
      daily[i] = val.toInt();
      if (idx == -1) break;
      last = idx + 1;
    }

    // 3. Get weekday (0=Sunday, 1=Monday, ..., 6=Saturday)
    time_t now = time(nullptr);
    struct tm* timeinfo = localtime(&now);
    int weekday = timeinfo->tm_wday; // 0=Sunday

    // If you want 0=Monday, 6=Sunday (like Flutter), shift index:
    int index = (weekday == 0) ? 6 : weekday - 1;

    daily[index] = gasValue;

    // 4. Build new JSON array
    String newArray = "[";
    for (int i = 0; i < 7; i++) {
      newArray += String(daily[i]);
      if (i < 6) newArray += ",";
    }
    newArray += "]";

    // 5. Write back to Firebase
    HTTPClient httpsPut;
    String putUrl = String(FIREBASE_HOST) + "/gas_stats/daily.json";
    if (strlen(FIREBASE_AUTH) > 0) {
      putUrl += "?auth=" + String(FIREBASE_AUTH);
    }
    if (httpsPut.begin(client, putUrl)) {
      httpsPut.addHeader("Content-Type", "application/json");
      int code = httpsPut.PUT(newArray);
      Serial.print("Updated gas_stats/daily. Code: ");
      Serial.println(code);
      httpsPut.end();
    }
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

void sendToSensorData(int gasValue) {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure client;
    client.setInsecure();

    time_t now = time(nullptr);
    struct tm* timeinfo = localtime(&now);

    char dateStr[11];   // "YYYY-MM-DD"
    strftime(dateStr, sizeof(dateStr), "%Y-%m-%d", timeinfo);

    char timeStr[9];    // "HH:MM:SS"
    strftime(timeStr, sizeof(timeStr), "%H:%M:%S", timeinfo);

    String url = String(FIREBASE_HOST) + "/sensor_data/" + dateStr + ".json";
    if (strlen(FIREBASE_AUTH) > 0) {
      url += "?auth=" + String(FIREBASE_AUTH);
    }

    HTTPClient https;
    if (https.begin(client, url)) {
      https.addHeader("Content-Type", "application/json");

      String payload = "{";
      payload += "\"timestamp\":\"" + String(timeStr) + "\",";
      payload += "\"value\":" + String(gasValue);
      payload += "}";

      int code = https.POST(payload);
      if (code > 0) {
        Serial.print("sensor_data updated. Code: ");
        Serial.println(code);
      } else {
        Serial.print("sensor_data error: ");
        Serial.println(https.errorToString(code));
      }

      https.end();
    }
  }
}
