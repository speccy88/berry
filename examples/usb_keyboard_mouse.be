import p2compat

var hid = p2compat.find("usb_hid")
var demo = p2compat.find("usb_demo")

print("USB HID status:", hid["status"])
print("USB HID:", hid["summary"])
print("USB demo:", demo["summary"])
print("usb_keyboard_mouse example is intentionally unsupported on this build")
print("usb keyboard mouse done")
