# ─────────────────────────────  Config  ──────────────────────────────
STEP = 1.0
HELP_TEXT = """
=== Calibracion servo elevador ===
  0..100  -> mover servo (acepta decimales, ej. 37.5)
  + / -   -> subir / bajar 1
  ?       -> mostrar valor actual
  h       -> ayuda
  q       -> salir y soltar el servo
"""


# ─────────────────────────────  Salida  ──────────────────────────────
def print_help(servo):
    print(HELP_TEXT)
    print("Rango de pulso: {}-{} us a {} Hz\n".format(servo.pulse_min_us, servo.pulse_max_us, servo.freq))


def print_status(servo, pulse_us, duty_u16):
    print("Valor: {:6.2f} | Pulso: {:4d} us | Duty real: {:5.2f} % | duty_u16: {}".format(
        servo.value, pulse_us, servo.real_duty_percent(pulse_us), duty_u16))


# ─────────────────────────────  Parseo  ──────────────────────────────
def parse_value(text):
    try:
        return float(text.replace(",", "."))
    except ValueError:
        return None


def move_and_report(servo, value):
    pulse_us, duty_u16 = servo.move(value)
    print_status(servo, pulse_us, duty_u16)


def handle_command(servo, command):
    command = command.strip().lower()
    if not command:
        return True
    if command == "q":
        return False
    if command == "h":
        print_help(servo)
    elif command == "?":
        move_and_report(servo, servo.value)
    elif command == "+":
        move_and_report(servo, servo.value + STEP)
    elif command == "-":
        move_and_report(servo, servo.value - STEP)
    else:
        handle_value(servo, command)
    return True


def handle_value(servo, command):
    value = parse_value(command)
    if value is None:
        print("Comando no valido: '{}' (escribe h para ayuda)".format(command))
    elif not 0 <= value <= 100:
        print("Fuera de rango: usa un valor entre 0 y 100")
    else:
        move_and_report(servo, value)


# ─────────────────────────────  Bucle  ───────────────────────────────
def run_console(servo, initial_value):
    print_help(servo)
    move_and_report(servo, initial_value)
    while handle_command(servo, input("> ")):
        pass
