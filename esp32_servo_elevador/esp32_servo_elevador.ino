// Calibración de servo para elevador - ESP32-S3 Mini
// Escribe un valor de 0 a 100 en el Monitor Serie (115200 baud, fin de línea "Nueva línea")
// y el servo se mueve a esa posición. Úsalo para anotar qué valor corresponde a cada altura.

#include <Arduino.h>

// ---------------- Configuración ----------------
const int      SERVO_PIN      = 4;      // GPIO de señal del servo
const uint32_t PWM_FREQ_HZ    = 50;     // Servos estándar: 50 Hz (periodo 20 ms)
const uint8_t  PWM_RES_BITS   = 14;     // 0..16383
const uint32_t PULSE_MIN_US   = 500;    // Pulso para 0   (ajusta según tu servo)
const uint32_t PULSE_MAX_US   = 2500;   // Pulso para 100 (ajusta según tu servo)
const float    VALOR_INICIAL  = 0.0;    // Posición al arrancar (0..100)

const uint32_t PERIOD_US = 1000000UL / PWM_FREQ_HZ;
const uint32_t DUTY_MAX  = (1UL << PWM_RES_BITS) - 1;

#if ESP_ARDUINO_VERSION_MAJOR < 3
const uint8_t PWM_CHANNEL = 0;
#endif

float valorActual = VALOR_INICIAL;

// ---------------- PWM ----------------
void pwmInit() {
#if ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcAttach(SERVO_PIN, PWM_FREQ_HZ, PWM_RES_BITS);
#else
  ledcSetup(PWM_CHANNEL, PWM_FREQ_HZ, PWM_RES_BITS);
  ledcAttachPin(SERVO_PIN, PWM_CHANNEL);
#endif
}

void pwmWrite(uint32_t duty) {
#if ESP_ARDUINO_VERSION_MAJOR >= 3
  ledcWrite(SERVO_PIN, duty);
#else
  ledcWrite(PWM_CHANNEL, duty);
#endif
}

// ---------------- Servo ----------------
uint32_t valorAPulso(float valor) {
  return PULSE_MIN_US + (uint32_t)((PULSE_MAX_US - PULSE_MIN_US) * valor / 100.0f + 0.5f);
}

uint32_t pulsoADuty(uint32_t pulsoUs) {
  return (uint32_t)((uint64_t)pulsoUs * DUTY_MAX / PERIOD_US);
}

void moverServo(float valor) {
  valor = constrain(valor, 0.0f, 100.0f);
  valorActual = valor;

  uint32_t pulso = valorAPulso(valor);
  uint32_t duty  = pulsoADuty(pulso);
  pwmWrite(duty);

  Serial.printf("Valor: %6.2f  |  Pulso: %4lu us  |  Duty real: %5.2f %%  |  Cuentas: %lu/%lu\n",
                valor, (unsigned long)pulso, pulso * 100.0f / PERIOD_US,
                (unsigned long)duty, (unsigned long)DUTY_MAX);
}

// ---------------- Consola ----------------
void mostrarAyuda() {
  Serial.println();
  Serial.println("=== Calibración servo elevador ===");
  Serial.println("  0..100  -> mover servo (se aceptan decimales, ej. 37.5)");
  Serial.println("  +  / -  -> subir / bajar 1");
  Serial.println("  ?       -> mostrar valor actual");
  Serial.println("  h       -> esta ayuda");
  Serial.printf ("Rango de pulso: %lu-%lu us a %lu Hz\n",
                 (unsigned long)PULSE_MIN_US, (unsigned long)PULSE_MAX_US, (unsigned long)PWM_FREQ_HZ);
  Serial.println();
}

bool esNumero(const String &s) {
  if (s.length() == 0) return false;
  bool punto = false, digito = false;
  for (size_t i = 0; i < s.length(); i++) {
    char c = s[i];
    if (isDigit(c)) digito = true;
    else if ((c == '.' || c == ',') && !punto) punto = true;
    else return false;
  }
  return digito;
}

void procesarComando(String cmd) {
  cmd.trim();
  if (cmd.length() == 0) return;

  if (cmd == "h" || cmd == "H") { mostrarAyuda(); return; }
  if (cmd == "?")               { moverServo(valorActual); return; }
  if (cmd == "+")               { moverServo(valorActual + 1); return; }
  if (cmd == "-")               { moverServo(valorActual - 1); return; }

  if (!esNumero(cmd)) {
    Serial.printf("Comando no válido: \"%s\" (escribe h para ayuda)\n", cmd.c_str());
    return;
  }

  cmd.replace(',', '.');
  float valor = cmd.toFloat();
  if (valor > 100.0f) {
    Serial.println("Fuera de rango: usa un valor entre 0 y 100");
    return;
  }
  moverServo(valor);
}

// ---------------- Arduino ----------------
void setup() {
  Serial.begin(115200);
  uint32_t t0 = millis();
  while (!Serial && millis() - t0 < 3000) delay(10);

  pwmInit();
  mostrarAyuda();
  moverServo(VALOR_INICIAL);
}

void loop() {
  if (Serial.available()) {
    String linea = Serial.readStringUntil('\n');
    procesarComando(linea);
  }
}
