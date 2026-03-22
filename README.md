# 🛠️ Tuff-Project: Pico-PowerShell HID Toolkit

A specialized HID (Human Interface Device) payload delivery system using a **Raspberry Pi Pico** and **CircuitPython**. This project demonstrates how a hardware-based attack can automate system diagnostics, network auditing, and data recovery via PowerShell.

> **⚠️ DISCLAIMER:** This project is for educational purposes and authorized security auditing only. Unauthorized access to computer systems is illegal. The author is not responsible for any misuse of this toolkit.

---

## 🚀 Features
* **One-Shot Execution:** Built-in logic to ensure the payload runs exactly once per plug-in.
* **AMSI Bypass:** Implementation of memory-patching techniques to bypass modern script scanning.
* **Obfuscated Delivery:** Uses string concatenation and backticks to evade static signature detection.
* **Automated Exfiltration:** Packages local system data and WiFi profiles into a secure ZIP and uploads via API.
* **Ghost Cleanup:** Automatically wipes the Windows `Run` history (MRU) and temporary workspace after execution.

---

## 📂 Project Structure
* `code.py`: The CircuitPython script for the Raspberry Pi Pico.
* `data_stealer.ps1`: The PowerShell payload hosted remotely for staged delivery.

---

## 🛠️ Setup & Usage

### 1. Prepare the Pico
1.  Install **CircuitPython** on your Raspberry Pi Pico.
2.  Copy the `adafruit_hid` library folder into the `lib` directory of your Pico.
3.  Upload the provided `code.py` to the root directory.

### 2. Configure the Payload
1.  Update the `url` variable in `code.py` to point to your **RAW** GitHub link for `data_stealer.ps1`.
2.  Set your custom `ntfy` topic in the PowerShell script to receive real-time alerts.

### 3. Execution
1.  Plug the Pico into the target machine.
2.  Wait for the **20-second safety delay** (allows for emergency disconnection).
3.  The Pico will simulate a keyboard to trigger the `Run` box and execute the staged payload.
4.  Once the LED on the Pico turns **ON**, the process is complete.

---

## 🛡️ Defenses Demonstrated
This project is designed to test and demonstrate:
* **HID Restricted Access:** The importance of locking workstations.
* **PowerShell Execution Policies:** Why `Bypass` should be monitored.
* **Endpoint Detection (EDR):** Testing how security suites react to memory-only script execution.

---
**Author:** Luke ([69420-ctrl](https://github.com/69420-ctrl))
