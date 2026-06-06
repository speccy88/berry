print("P2_SMOKE_BEGIN all")

run_file("/tests/p2/smoke_core.be")
run_file("/tests/p2/smoke_modules.be")
run_file("/tests/p2/smoke_libraries.be")
run_file("/tests/p2/smoke_sd.be")
run_file("/tests/p2/smoke_rtos.be")

print("P2_SMOKE_PASS all")
