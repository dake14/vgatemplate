# ─────────────────────────────  Imports  ─────────────────────────────
from servo import Servo
from console import run_console


# ─────────────────────────────  Config  ──────────────────────────────
SERVO_PIN = 4
INITIAL_VALUE = 0.0


# ─────────────────────────────  Entry  ───────────────────────────────
def main():
    servo = Servo(SERVO_PIN)
    try:
        run_console(servo, INITIAL_VALUE)
    except KeyboardInterrupt:
        pass
    finally:
        servo.release()
        print("Servo liberado")


main()
