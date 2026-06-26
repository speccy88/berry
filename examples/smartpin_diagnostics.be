import p2smart

def print_pair_summary(result)
    print("pair", result["out_pin"], result["in_pin"], "ok", result["ok"], "checks", result["ok_count"], "/", result["count"], "failed", result["failed_count"])
    print(" gpio", result["gpio"]["ok"], "high", result["high_counter"]["counter"]["delta"], "pulse", result["pulse_counter"]["counter"]["delta"], "transition", result["transition_counter"]["counter"]["delta"])
    print(" async", result["async_serial"]["ok"], "drain", result["async_serial_drain"]["matched"], "drain_count", result["async_serial_drain"]["drained"]["count"])
end

print("Smartpin diagnostics default jumpers")

print_pair_summary(p2smart.jumper_pair_probe(0, 1))
print_pair_summary(p2smart.jumper_pair_probe(2, 3))
print_pair_summary(p2smart.jumper_pair_probe(4, 5))
print_pair_summary(p2smart.jumper_pair_probe(6, 7))

print("smartpin diagnostics done")
