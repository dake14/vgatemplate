# ─────────────────────────────  Imports  ─────────────────────────────
from machine import Pin, PWM


# ─────────────────────────────  Config  ──────────────────────────────
PWM_FREQ_HZ = 50
PULSE_MIN_US = 500
PULSE_MAX_US = 2500
DUTY_U16_MAX = 65535


# ─────────────────────────────  Servo  ───────────────────────────────
class Servo:
    def __init__(self, pin_num, freq=PWM_FREQ_HZ, pulse_min_us=PULSE_MIN_US, pulse_max_us=PULSE_MAX_US):
        self.freq = freq
        self.period_us = 1_000_000 // freq
        self.pulse_min_us = pulse_min_us
        self.pulse_max_us = pulse_max_us
        self.value = 0.0
        self.pwm = PWM(Pin(pin_num), freq=freq)

    def value_to_pulse_us(self, value):
        span = self.pulse_max_us - self.pulse_min_us
        return self.pulse_min_us + round(span * value / 100)

    def pulse_to_duty_u16(self, pulse_us):
        return round(pulse_us * DUTY_U16_MAX / self.period_us)

    def move(self, value):
        value = min(max(value, 0.0), 100.0)
        pulse_us = self.value_to_pulse_us(value)
        duty_u16 = self.pulse_to_duty_u16(pulse_us)
        self.pwm.duty_u16(duty_u16)
        self.value = value
        return pulse_us, duty_u16

    def real_duty_percent(self, pulse_us):
        return pulse_us * 100 / self.period_us

    def release(self):
        self.pwm.deinit()
