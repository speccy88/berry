import p2compat

var video = p2compat.find("video_output")
var demo = p2compat.find("vga_demo")

print("VGA/video status:", video["status"])
print("VGA/video:", video["summary"])
print("VGA demo:", demo["summary"])
print("vga_test_pattern example is intentionally unsupported on this build")
print("vga test pattern done")
