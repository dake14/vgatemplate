# Calibración servo elevador (ESP32-S3 Mini)

Sketch de Arduino para mapear qué valor (0–100) corresponde a cada altura del elevador.

## Conexión
| Servo        | ESP32-S3 Mini |
|--------------|---------------|
| Señal        | GPIO 4 (`SERVO_PIN`) |
| GND          | GND (común con la fuente del servo) |
| V+ (5 V)     | Fuente externa de 5 V recomendada |

## Arduino IDE
- Placa: *ESP32S3 Dev Module* (o la de tu mini, ej. *LOLIN S3 Mini*)
- **USB CDC On Boot: Enabled** (para ver la consola por el USB nativo)
- Monitor Serie a **115200** baud, fin de línea **Nueva línea**

## Uso
- `0`…`100` → mueve el servo (acepta decimales: `42.5`)
- `+` / `-` → ajuste fino de ±1
- `?` → muestra el valor actual
- `h` → ayuda

El valor 0–100 se reparte entre `PULSE_MIN_US` (500 µs) y `PULSE_MAX_US` (2500 µs) a 50 Hz,
es decir, un duty real de 2.5 % a 12.5 %. Cada movimiento imprime el pulso y el duty real.
