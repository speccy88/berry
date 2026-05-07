# Berry Spin2 Binary Area

Place Propeller 2 `.spin2` sources here and build them with:

```sh
make spin2
```

The generated binaries are written to `spin2/build/*.bin`. Copy the binaries to the P2 SD card under `/spin2` so Berry can find them with `spin2.list()`.

Berry-side smoke test for the bundled mailbox demo:

```berry
import spin2

print(spin2.list())
handle = spin2.start("berry_mailbox_demo.bin")
print(spin2.info(handle))
print(spin2.call(handle, 1, 123))
spin2.stop(handle)
```

## v1 Mailbox Convention

`spin2.call(handle, method_id, args...)` is intentionally small for the first port. It supports integer arguments only and expects compatible binaries to use the Hub-RAM mailbox passed in `PTRA`.

Mailbox longs:

```text
0  state       0 idle, 1 request, 2 running, 3 done, 4 error, 5 stop
1  method_id
2  argc
3  argv[0]
...
10 argv[7]
11 result
12 par         optional user parameter from spin2.start(file, par)
13 method_addr resolved method address from the binary call table
```

Compatible binaries should put a call table at the start of the binary:

```text
long method_count
long method_0_offset_or_address
long method_1_offset_or_address
...
```

For raw PASM examples, FlexSpin labels are usually long offsets, so Berry accepts both long offsets and byte offsets when resolving `method_addr`.
