import spin2

# Build with `make spin2`, then copy spin2/build/berry_mailbox_demo.bin
# to /spin2/MBOXDEMO.BIN on the P2 SD card. The current Catalina DOSFS
# path exposes 8.3 filenames, so long names appear as aliases like
# BERRY_~2.BIN.
print(spin2.list())
handle = spin2.start("MBOXDEMO.BIN")
print(spin2.info(handle))
print(spin2.call(handle, 1, 123))
spin2.stop(handle)
