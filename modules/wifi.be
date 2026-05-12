# WiFiNINA / AirLift SPI transport for Propeller 2 Berry.
#
# This first layer intentionally stays close to the firmware protocol: it can
# reset the coprocessor, send framed commands, and read simple responses such
# as firmware version and connection status.

import p2
import spi

var wifi = module("wifi")

wifi.START_CMD = 0xE0
wifi.END_CMD = 0xEE
wifi.ERR_CMD = 0xEF
wifi.REPLY_FLAG = 0x80
wifi.DUMMY = 0xFF

wifi.GET_CONN_STATUS_CMD = 0x20
wifi.GET_FW_VERSION_CMD = 0x37

wifi.STATUS = {
    0: "idle",
    1: "no_ssid_available",
    2: "scan_completed",
    3: "connected",
    4: "connect_failed",
    5: "connection_lost",
    6: "disconnected",
    7: "ap_listening",
    8: "ap_connected",
    9: "ap_failed",
    255: "no_shield"
}

wifi._cfg = {
    "sck": 16,
    "mosi": 17,
    "miso": 18,
    "cs": 19,
    "busy": 20,
    "reset": 21,
    "irq": 22,
    "khz": 1000,
    "mode": 0
}

wifi._initialized = false
wifi._last_response = nil

wifi._byte = def(v)
    return v & 0xFF
end

wifi._bytes = def(values)
    var b = bytes()
    for v : values
        b.add(wifi._byte(v))
    end
    return b.asstring()
end

wifi._rxbytes = def(raw)
    return bytes().fromstring(raw)
end

wifi._merge_config = def(cfg)
    var merged = {}
    for key : ["sck", "mosi", "miso", "cs", "busy", "reset", "irq", "khz", "mode"]
        merged[key] = wifi._cfg[key]
    end
    if cfg != nil
        for key : ["sck", "mosi", "miso", "cs", "busy", "reset", "irq", "khz", "mode"]
            if cfg.contains(key)
                merged[key] = cfg[key]
            end
        end
    end
    return merged
end

wifi._wait_busy = def(level, timeout_us)
    var elapsed = 0
    while p2.read(wifi._cfg["busy"]) != level
        if elapsed >= timeout_us
            raise "timeout_error", "WiFiNINA busy pin timeout"
        end
        p2.delay_us(100)
        elapsed += 100
    end
end

wifi._select = def()
    spi.select()
    # AirLift raises READY/BUSY after chip-select falls. The firmware's SPIS
    # layer drives the line high while a transaction can be clocked.
    wifi._wait_busy(1, 10000)
end

wifi._deselect = def()
    spi.deselect()
end

wifi._transfer = def(values)
    return wifi._rxbytes(spi.transfer(wifi._bytes(values)))
end

wifi._read_byte = def()
    return wifi._rxbytes(spi.transfer(wifi._bytes([wifi.DUMMY]))).get(0)
end

wifi._send_cmd = def(cmd, params)
    var frame = [wifi.START_CMD, cmd & ~wifi.REPLY_FLAG, params.size()]
    for param : params
        var i = 0
        var size = param.size()
        frame.push(size)
        while i < size
            frame.push(param[i])
            i += 1
        end
    end
    frame.push(wifi.END_CMD)
    wifi._select()
    wifi._transfer(frame)
    wifi._deselect()
end

wifi._wait_response = def(cmd, expected_params)
    var start, b, i, j, count, plen, params

    wifi._select()

    start = wifi._read_byte()
    i = 0
    while start != wifi.START_CMD
        if start == wifi.ERR_CMD
            wifi._deselect()
            raise "runtime_error", "WiFiNINA returned ERR_CMD"
        end
        i += 1
        if i >= 100
            wifi._deselect()
            raise "timeout_error", "WiFiNINA response start timeout"
        end
        p2.delay_us(10000)
        start = wifi._read_byte()
    end

    b = wifi._read_byte()
    if b != (cmd | wifi.REPLY_FLAG)
        wifi._deselect()
        raise "runtime_error", format("WiFiNINA reply command mismatch: got 0x%02X", b)
    end

    count = wifi._read_byte()
    if expected_params != nil && count != expected_params
        wifi._deselect()
        raise "runtime_error", format("WiFiNINA reply parameter mismatch: got %i", count)
    end

    params = []
    i = 0
    while i < count
        plen = wifi._read_byte()
        var param = bytes()
        j = 0
        while j < plen
            param.add(wifi._read_byte())
            j += 1
        end
        params.push(param)
        i += 1
    end

    b = wifi._read_byte()
    wifi._deselect()
    if b != wifi.END_CMD
        raise "runtime_error", format("WiFiNINA reply end mismatch: got 0x%02X", b)
    end

    wifi._last_response = params
    return params
end

wifi.request = def(cmd, params, expected_params)
    if !wifi._initialized
        raise "runtime_error", "wifi.init() must be called first"
    end
    if params == nil
        params = []
    end
    wifi._send_cmd(cmd, params)
    return wifi._wait_response(cmd, expected_params)
end

wifi.init = def(cfg)
    if type(cfg) == "module"
        # Berry script modules call a returned module's init hook during import.
        # Treat that import-time call as a no-op; real hardware configuration
        # happens only when user code passes the pin map.
        return wifi
    end

    wifi._cfg = wifi._merge_config(cfg)

    p2.pinmode(wifi._cfg["busy"], p2.INPUT)
    # On ESP32-C6 AirLift builds GPIO0 may still be wired to the host as IRQ.
    # Hold it high across reset so the coprocessor does not enter bootloader
    # strap mode by accident, then release it to input.
    p2.pinmode(wifi._cfg["irq"], p2.OUTPUT)
    p2.high(wifi._cfg["irq"])
    p2.pinmode(wifi._cfg["reset"], p2.OUTPUT)

    p2.high(wifi._cfg["reset"])
    p2.delay_us(10000)
    p2.low(wifi._cfg["reset"])
    p2.delay_us(10000)
    p2.high(wifi._cfg["reset"])
    p2.delay_us(750000)
    p2.pinmode(wifi._cfg["irq"], p2.INPUT)

    spi.init(
        wifi._cfg["sck"],
        wifi._cfg["mosi"],
        wifi._cfg["miso"],
        wifi._cfg["cs"],
        wifi._cfg["mode"],
        wifi._cfg["khz"]
    )

    wifi._initialized = true
    return wifi
end

wifi.firmware_version = def()
    var rsp = wifi.request(wifi.GET_FW_VERSION_CMD, [], 1)
    return rsp[0].asstring()
end

wifi.status_code = def()
    var rsp = wifi.request(wifi.GET_CONN_STATUS_CMD, [], 1)
    return rsp[0].get(0)
end

wifi.status = def()
    var code = wifi.status_code()
    if wifi.STATUS.contains(code)
        return wifi.STATUS[code]
    end
    return format("unknown(%i)", code)
end

wifi.last_response = def()
    return wifi._last_response
end

wifi.stop = def()
    spi.stop()
    wifi._initialized = false
end

return wifi
