#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <DHT.h> // Pustaka untuk DHT22
#include <PubSubClient.h>
#include <TimeLib.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <ModbusMaster.h>

LiquidCrystal_I2C lcd(0x27, 20, 4);

int SensorPin = 1; // Pin analog untuk sensor kelembaban tanah
int soilMoistureValue; // Menyimpan nilai analog dari sensor ke esp32
int soilmoisturepercent; // Nilai yang diperoleh dalam bentuk persen setelah di-mapping

#define RelayPin 21 // PIN Relay untuk mengontrol pompa
#define Relay2 47 // PIN Relay untuk mengontrol pompa
#define Relay3 14 // PIN Relay untuk mengontrol pompa
#define Relay4 38 // PIN Relay untuk mengontrol pompa

// Konfigurasi DHT22
#define DHTPIN 2  // Pin untuk sensor DHT22
#define DHTTYPE DHT22 // Definisikan tipe sensor DHT22
DHT dht(DHTPIN, DHTTYPE);

#define RX2 16  // RX dari RS485
#define TX2 15  // TX dari RS485
#define DERE 40  // DE & RE dihubungkan ke GPIO4

HardwareSerial mySerial(2);  // UART2 di ESP32
ModbusMaster node;
uint8_t sensorID = 1;  // Coba ubah ke 2 atau 3 jika error

// Wi-Fi credentials
const char* ssid = "Alvian Production @ office"; // replace with your Wi-Fi SSID
const char* password = "Banyuwangi1"; // replace with your Wi-Fi password

// Firebase Realtime Database
const char* firebaseHost = "https://sitanamalvian-default-rtdb.asia-southeast1.firebasedatabase.app/";
const char* firebaseAuth = "AIzaSyDSqrwCEWKE7wcNQ7Jc7Hi5Zi41OBv7KEY";

FirebaseData firebaseData;
FirebaseConfig firebaseConfig;
FirebaseAuth auth;

unsigned long lastFailedSend = 0; // Waktu terakhir gagal kirim data ke Firebase
const unsigned long reconnectInterval = 120000; // Interval untuk mencoba reconnect (2 menit)

const int timeZone = 7; // Time zone offset for GMT+7

WiFiUDP ntpUDP;
unsigned long lastHistorySend = 0;  // Menyimpan waktu terakhir history dikirim
const unsigned long historyInterval = 300000; // 5 menit dalam milidetik (300.000 ms)

void preTransmission() {
    digitalWrite(DERE, HIGH);  // Aktifkan TX Mode
    delay(2);
}

void postTransmission() {
    delay(2);
    digitalWrite(DERE, LOW);  // Aktifkan RX Mode
}

void setup() {
    Serial.begin(115200);
    mySerial.begin(4800, SERIAL_8N1, RX2, TX2);
    pinMode(RelayPin, OUTPUT);
    pinMode(Relay2, OUTPUT);
    pinMode(Relay3, OUTPUT);
    pinMode(Relay4, OUTPUT);
    
    pinMode(DERE, OUTPUT);
    digitalWrite(DERE, LOW);  // Default ke RX Mode
    
    node.begin(sensorID, mySerial);
    node.preTransmission(preTransmission);
    node.postTransmission(postTransmission);

    // Initialize the LCD
  lcd.init();
  lcd.backlight();

  // Initialize DHT sensor
  dht.begin();

  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(1000);
  }
  Serial.println();
  Serial.println("Connected to Wi-Fi");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
  // Jeda untuk mengurangi gangguan dari Wi-Fi
  delay(1000);

  // Initialize Firebase
  firebaseConfig.host = firebaseHost;
  firebaseConfig.signer.tokens.legacy_token = firebaseAuth;
  Firebase.begin(&firebaseConfig, &auth);
  Firebase.reconnectWiFi(true);

  // Synchronize time from NTP server
  configTime(timeZone * 3600, 0, "pool.ntp.org");
  if (!syncTime()) {
    Serial.println("Failed to synchronize time with NTP server");
  }
}

void loop() {
  // Update time
  time_t now = time(nullptr);
  struct tm *localTime = localtime(&now);
    
  // sensor npk
  uint8_t result = node.readHoldingRegisters(0x001E, 3);
  int nitrogen = 0, phosphorus = 0, potassium = 0;

  if (result == node.ku8MBSuccess) {
    nitrogen   = node.getResponseBuffer(0);
    phosphorus = node.getResponseBuffer(1);
    potassium  = node.getResponseBuffer(2);

  } else {
      Serial.print("Modbus Error: 0x");
      Serial.println(result, HEX);
  }

  // Membaca data dari sensor kelembaban tanah
  soilMoistureValue = analogRead(SensorPin);
  Serial.print("Nilai analog = ");
  Serial.println(soilMoistureValue);
  soilmoisturepercent = map(soilMoistureValue, 4095, 0, 0, 100);

  Serial.print("Presentase kelembaban tanah = ");
  Serial.print(soilmoisturepercent);
  Serial.println("% ");

  // Membaca suhu dan kelembaban udara dari sensor DHT22
  float temperature = dht.readTemperature(); // Membaca suhu (dalam Celsius)
  float humidity = dht.readHumidity(); // Membaca kelembaban udara

  // Membaca nilai mode dan manual control dari Firebase
  int mode = 1; // default ke mode otomatis
  int manualPumpControl = 0; // default ke pompa mati jika manual
  
  if (Firebase.getInt(firebaseData, "/plot1/mode")) {
    mode = firebaseData.intData();
  } else {
    Serial.println("Failed to get mode from Firebase");
  }

  if (Firebase.getInt(firebaseData, "/plot1/manualPumpControl")) {
    manualPumpControl = firebaseData.intData();
  } else {
    Serial.println("Failed to get manual control from Firebase");
  }

  if (soilmoisturepercent > 81 && soilmoisturepercent <= 100) {
    Serial.println("Tanah basah");
    lcd.setCursor(0, 0);
    lcd.print("S : ");
    lcd.print(soilmoisturepercent);
    lcd.print("%   | ");
    lcd.print("Basah");
  } else if (soilmoisturepercent > 60 && soilmoisturepercent <= 80) {
    Serial.println("Tanah kondisi normal");
    lcd.setCursor(0, 0);
    lcd.print("S : ");
    lcd.print(soilmoisturepercent);
    lcd.print("%   | ");
    lcd.print("Normal");
  } else if (soilmoisturepercent >= 0 && soilmoisturepercent <= 59) {
    Serial.println("Tanah Kering");
    lcd.setCursor(0, 0);
    lcd.print("S : ");
    lcd.print(soilmoisturepercent);
    lcd.print("%   | ");
    lcd.print("Kering");
  }

  int statusPompa; // variabel untuk menyimpan status pompa
  
  if (mode == 1) { // Mode otomatis
    // Kontrol pompa otomatis berdasarkan kelembaban tanah
    if (soilmoisturepercent > 81 && soilmoisturepercent <= 100) {
      digitalWrite(RelayPin, LOW); // matikan
      digitalWrite(Relay2, LOW);  // mati
      digitalWrite(Relay3, LOW);
      digitalWrite(Relay4, LOW);
      statusPompa = 0; // Pompa mati
      lcd.setCursor(0, 1);
      lcd.print("M : oto   | P : Of");
    } else if (soilmoisturepercent > 60 && soilmoisturepercent <= 80) {
      digitalWrite(RelayPin, LOW); // matikan
      digitalWrite(Relay2, LOW);  // mati
      digitalWrite(Relay3, LOW);
      digitalWrite(Relay4, LOW);
      statusPompa = 0; // Pompa mati
      lcd.setCursor(0, 1);
      lcd.print("M : oto   | P : Of");
    } else if (soilmoisturepercent >= 0 && soilmoisturepercent <= 59) {
      digitalWrite(RelayPin, HIGH); // aktif pompa
      digitalWrite(Relay2, HIGH);  // Aktif 
      digitalWrite(Relay3, HIGH);
      digitalWrite(Relay4, HIGH);
      statusPompa = 1; // Pompa nyala
      lcd.setCursor(0, 1);
      lcd.print("M : oto   | P : On");
    }
  } else { // Mode manual
    // Kontrol pompa manual berdasarkan manualPumpControl
    if (manualPumpControl == 1) {
      digitalWrite(RelayPin, HIGH); // aktif pompa
      digitalWrite(Relay2, HIGH);  // Aktif 
      digitalWrite(Relay3, HIGH);
      digitalWrite(Relay4, HIGH);
      statusPompa = 1; // Pompa nyala
      lcd.setCursor(0, 1);
      lcd.print("M : mnl   | P : On");
    } else {
      Serial.println("Mode manual: Pompa mati");
      digitalWrite(RelayPin, LOW); // matikan
      digitalWrite(Relay2, LOW);  // mati
      digitalWrite(Relay3, LOW);
      digitalWrite(Relay4, LOW);
      statusPompa = 0; // Pompa mati
      lcd.setCursor(0, 1);
      lcd.print("M : mnl   | P : Of");
    }
  }
  lcd.setCursor(0, 2);
  lcd.print("T : ");
  lcd.print(temperature, 1);
  lcd.print("C | ");
  lcd.print("H : ");
  lcd.print(humidity, 1);

  lcd.setCursor(0, 3);
  lcd.print("N:");
  lcd.printf("%02d ", nitrogen);
  lcd.print("P:");
  lcd.printf("%02d ", phosphorus);
  lcd.print("K:");
  lcd.printf("%02d", potassium);

  // Upload data ke Firebase
  String path = "/plot1";
  if (Firebase.setInt(firebaseData, path + "/soilMouisture", soilmoisturepercent) &&
      Firebase.setInt(firebaseData, path + "/status", statusPompa)&&
      Firebase.setFloat(firebaseData, path + "/temperature", temperature) && 
      Firebase.setFloat(firebaseData, path + "/airHumidity", humidity) &&
      Firebase.setInt(firebaseData, path + "/n", nitrogen) &&
      Firebase.setInt(firebaseData, path + "/p", phosphorus) &&
      Firebase.setInt(firebaseData, path + "/k", potassium)) {
    Serial.println("Data sent to Firebase successfully");
  } else {
    Serial.print("Failed to send data to Firebase: ");
    Serial.println(firebaseData.errorReason());

    if (lastFailedSend == 0) {
      lastFailedSend = millis();
    } else if (millis() - lastFailedSend >= reconnectInterval) {
      Serial.println("Menyambung ulang ke Wi-Fi...");
      WiFi.disconnect();
      WiFi.begin(ssid, password);
      while (WiFi.status() != WL_CONNECTED) {
        Serial.print(".");
        delay(1000);
      }
      Serial.println("Terhubung ulang ke Wi-Fi");

      // Konfigurasi ulang Firebase
      firebaseConfig.host = firebaseHost;
      firebaseConfig.signer.tokens.legacy_token = firebaseAuth;
      Firebase.begin(&firebaseConfig, &auth);

      lastFailedSend = millis(); // Reset waktu gagal kirim setelah reconnect
    }
  }
  if (millis() - lastHistorySend >= historyInterval) {
    lastHistorySend = millis();  // Perbarui waktu terakhir pengiriman history

    // Mendapatkan waktu saat ini
    time_t now = time(nullptr);
    struct tm *localTime = localtime(&now);
    char dateStr[11], timeStr[6];

    // Format tanggal "YYYY_MM_DD"
    sprintf(dateStr, "%04d_%02d_%02d", localTime->tm_year + 1900, localTime->tm_mon + 1, localTime->tm_mday);
    
    // Format waktu "HH:MM"
    sprintf(timeStr, "%02d:%02d", localTime->tm_hour, localTime->tm_min);

    // Path Firebase untuk menyimpan history
    String historyPath = "/plot1/zhistory/" + String(dateStr) + "/" + String(timeStr);

    // Upload history ke Firebase
    if (Firebase.setInt(firebaseData, historyPath + "/soilMouisture", soilmoisturepercent) &&
        Firebase.setInt(firebaseData, historyPath + "/status", statusPompa) &&
        Firebase.setFloat(firebaseData, historyPath + "/temperature", temperature) &&
        Firebase.setFloat(firebaseData, historyPath + "/airHumidity", humidity) && 
        Firebase.setInt(firebaseData, historyPath + "/n", nitrogen) &&
        Firebase.setInt(firebaseData, historyPath + "/p", phosphorus) &&
        Firebase.setInt(firebaseData, historyPath + "/k", potassium)) {
        Serial.println("History data sent successfully");
    } else {
        Serial.print("Failed to send history data: ");
        Serial.println(firebaseData.errorReason());
    }
  }
  delay(3000);
}

bool syncTime() {
  configTime(timeZone * 3600, 0, "pool.ntp.org");
  time_t now = time(nullptr);
  int retry = 0;
  const int retryCount = 10;
  while (now < 8 * 3600 * 2 && retry < retryCount) {
    delay(1000);
    now = time(nullptr);
    retry++;
  }
  if (retry == retryCount) {
    return false;
  }
  setTime(now);
  Serial.println("Time synchronized successfully");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Time Sukses");
  return true;
}
