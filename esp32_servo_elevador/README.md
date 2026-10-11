# Calibración servo elevador (ESP32-S3 Mini, MicroPython + Thonny)

Subir a la placa (Thonny → *Archivo → Guardar como → Dispositivo MicroPython*): `main.py`, `servo.py`, `console.py`.

| Servo | ESP32-S3 Mini |
|-------|---------------|
| Señal | GPIO 4 (`SERVO_PIN` en `main.py`) |
| GND   | GND común con la fuente |
| V+    | 5 V externos |

Comandos en la consola de Thonny: `0`–`100`, `+`, `-`, `?`, `h`, `q`.
0–100 se mapea a 500–2500 µs a 50 Hz (duty real 2.5 %–12.5 %).
