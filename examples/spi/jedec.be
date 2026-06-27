import spi

var clk = 10
var mosi = 11
var miso = 12
var cs = 13
var mode = 0
var khz = 1000

print("spi jedec pins:", clk, mosi, miso, cs, "mode", mode, "khz", khz)
spi.init(clk, mosi, miso, cs, mode, khz)

spi.select()
var id = spi.transfer("\x9F\x00\x00\x00")
spi.deselect()
print("jedec response length:", size(id))
print("jedec response raw:", id)
spi.stop()
print("spi jedec done")
