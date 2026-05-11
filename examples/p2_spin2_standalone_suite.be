import spin2

# Build with `make spin2`, then transfer the build folder to the SD card with:
#   make spin2-sd-sync TOOLCHAIN=catalina PORT=/dev/cu.usbserial-XXXX
#
# High-level FlexSpin images are not relocatable when Berry loads them from the
# heap, so the loader must reject them safely instead of starting a cog that can
# hang the board. Raw standalone PASM images may still start with PTRA == nil.

guarded = [
    "S2_01CON.BIN",
    "S2_02ENU.BIN",
    "S2_03STR.BIN",
    "S2_04VAR.BIN",
    "S2_05BIT.BIN",
    "S2_06EXP.BIN",
    "S2_07FLO.BIN",
    "S2_08CAS.BIN",
    "S2_09LOO.BIN",
    "S2_10MET.BIN",
    "S2_11MUL.BIN",
    "S2_12SEN.BIN",
    "S2_13REC.BIN",
    "S2_14OBJ.BIN",
    "S2_15STR.BIN",
    "S2_16NES.BIN",
    "S2_17FLD.BIN",
    "S2_18MEM.BIN",
    "S2_19FPM.BIN",
    "S2_20TAS.BIN",
    "S2_21PRE.BIN",
    "S2_22DBG.BIN",
    "S2_23PIN.BIN",
    "S2_24CLK.BIN",
    "S2_25PAS.BIN",
    "S2_26DAT.BIN",
    "S2_CHLD.BIN",
]

print(spin2.list())

for file : guarded
    try
        handle = spin2.start(file)
        print(file, "unexpected-start")
        spin2.stop(handle)
        raise "internal_error", "expected high-level FlexSpin image rejection"
    except .. as e, m
        if e == "value_error"
            print(file, "safe-reject", m)
        else
            raise e, m
        end
    end
end

for file : [ "S2_27DIT.BIN" ]
    handle = spin2.start(file)
    info = spin2.info(handle)
    print(file, info["abi"], info["methods"])
    spin2.stop(handle)
end
