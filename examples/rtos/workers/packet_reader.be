import rtos

def packet_reader(delay_ms)
    var seq = 0
    while true
        seq += 1
        rtos.put("rx_packets", seq)
        rtos.sleep_ms(delay_ms)
    end
end

