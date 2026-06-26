print("P2_SMOKE_BEGIN smartpins_async_rx")

import p2smart

var values = [0x00, 0x55, 0xa5, 0xff]
var pairs = [
    [0, 1],
    [2, 3],
    [4, 5],
    [6, 7]
]

for pair : pairs
    var a = pair[0]
    var b = pair[1]
    print("P2_SMOKE_PAIR " + str(a) + "_" + str(b))

    for value : values
        print("P2_SMOKE_ASYNC_RX start " + str(a) + "_" + str(b) + " " + str(value))
        var ab = p2smart.async_serial_pair(a, b, 115200, 8, nil, nil)
        ab.start()
        p2smart.waitus(1000)
        ab.send(value)
        if value == 0
            var zero = ab.read_result_after(2000)
            print("P2_SMOKE_ASYNC_RX result " + str(a) + "_" + str(b) + " " + str(zero["ready"]) + " " + str(zero["value"]) + " " + str(zero["raw"]) + " " + str(zero["event"]))
            assert(zero["ready"])
            assert(zero["value"] == value)
        else
            p2smart.waitus(2000)
            assert(ab.available() != 0)
            var result = ab.read_result()
            assert(result["ready"])
            assert(result["value"] == value)
            assert(ab.read_byte() == value)
        end
        print("P2_SMOKE_ASYNC_RX read " + str(a) + "_" + str(b) + " " + str(value))
        ab.clear()
        p2smart.waitus(1000)

        print("P2_SMOKE_ASYNC_RX start " + str(b) + "_" + str(a) + " " + str(value))
        var ba = p2smart.async_serial_pair(b, a, 115200, 8, nil, nil)
        ba.start()
        p2smart.waitus(1000)
        ba.send(value)
        if value == 0
            var zero = ba.read_result_after(2000)
            print("P2_SMOKE_ASYNC_RX result " + str(b) + "_" + str(a) + " " + str(zero["ready"]) + " " + str(zero["value"]) + " " + str(zero["raw"]) + " " + str(zero["event"]))
            assert(zero["ready"])
            assert(zero["value"] == value)
        else
            p2smart.waitus(2000)
            assert(ba.available() != 0)
            var result = ba.read_result()
            assert(result["ready"])
            assert(result["value"] == value)
            assert(ba.read_byte() == value)
        end
        print("P2_SMOKE_ASYNC_RX read " + str(b) + "_" + str(a) + " " + str(value))
        ba.clear()
        p2smart.waitus(1000)
    end

    if a == 0
        print("P2_SMOKE_ASYNC_RX exchange " + str(a) + "_" + str(b))
        var abx = p2smart.async_serial_pair(a, b, 115200, 8, nil, nil)
        abx.start()
        p2smart.waitus(1000)
        assert(abx.exchange_bytes_after(values, 2000) == values)
        abx.clear()
        p2smart.waitus(1000)

        print("P2_SMOKE_ASYNC_RX exchange " + str(b) + "_" + str(a))
        var bax = p2smart.async_serial_pair(b, a, 115200, 8, nil, nil)
        bax.start()
        p2smart.waitus(1000)
        var results = bax.exchange_results_after(values, 2000)
        assert(results.size() == values.size())
        var idx = 0
        while idx < values.size()
            assert(results[idx]["ready"])
            assert(results[idx]["value"] == values[idx])
            idx += 1
        end
        bax.clear()
        p2smart.waitus(1000)

        print("P2_SMOKE_ASYNC_RX drain " + str(a) + "_" + str(b))
        var drain = p2smart.async_serial_drain_probe(a, b, 0x33, 2000, 115200, 8, 4)
        assert(drain["ok"])
        assert(drain["matched"])
        assert(drain["drained"]["count"] == 1)
        assert(drain["drained"]["acked"] == 1)
        assert(drain["drained"]["values"] == [0x33])
        assert(drain["drained"]["results"][0]["ready"])
        assert(drain["drained"]["results"][0]["value"] == 0x33)
        assert(drain["drained"]["stopped_reason"] == "not_ready")
        assert(!drain["serial"]["started"])
        p2smart.waitus(1000)
    end
end

print("P2_SMOKE_PASS smartpins_async_rx")
