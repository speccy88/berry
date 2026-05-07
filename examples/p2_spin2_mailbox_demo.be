import spin2

# Build with `make spin2`, then copy spin2/build/berry_mailbox_demo.bin
# to /spin2 on the P2 SD card.
handle = spin2.start("berry_mailbox_demo.bin")
print(spin2.info(handle))
print(spin2.call(handle, 1, 123))
spin2.stop(handle)
