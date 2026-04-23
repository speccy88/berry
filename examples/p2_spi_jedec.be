import spi

spi.init(10, 11, 12, 13, 0, 1000)
spi.select()
id = spi.transfer("\x9F\x00\x00\x00")
spi.deselect()
print(id)
