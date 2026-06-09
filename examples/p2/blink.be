import p2

p2.pinmode(56, p2.OUTPUT)

while true
    p2.high(56)
    p2.waitms(250)
    p2.low(56)
    p2.waitms(250)
end
