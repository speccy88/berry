import p2

var pin = 56

p2.smartpin_clear(pin)
p2.smartpin_write_mode(pin, 0)
p2.smartpin_write_x(pin, 0)
p2.smartpin_write_y(pin, 0)
p2.smartpin_ack(pin)

print(p2.smartpin_query(pin))
print(p2.smartpin_read(pin))

p2.smartpin_start(pin, 0, 0, 0)
p2.smartpin_clear(pin)

