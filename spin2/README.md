# Berry Spin2 Binary Area

Place Propeller 2 `.spin2` sources here and build them with:

```sh
make spin2 TOOLCHAIN=catalina
```

The generated binaries are written to uppercase 8.3 names in
`spin2/build/*.BIN`; `spin2/build/MANIFEST.TXT` maps each source file to its SD
filename. FlexSpin `.p2asm` listings are kept separately in
`spin2/build/p2asm`.

## Example Suite

- `s2_01con.spin2` through `s2_27dit.spin2`: Spin2 language feature examples from the v54 documentation, limited to the subset FlexSpin 7.6.6 can compile. The high-level FlexSpin binaries are compile-coverage artifacts; Berry rejects them at runtime because they are not relocatable from the heap loader. The raw PASM `s2_27dit.spin2` binary remains a standalone start/stop test.
- `mb_01alu.spin2` through `mb_20pat.spin2`: Berry-callable PASM2 mailbox binaries. Start them with `spin2.start()` and call method `1`.
- `p2instmx.spin2`: compile-only PASM2 instruction matrix for broad mnemonic coverage.
- `common/berry_mbox_service.spin2h`: shared PASM2 mailbox service used by the callable examples.

Full coverage notes and validation commands live in
[`docs/SPIN2_MODULE_TESTS.md`](../docs/SPIN2_MODULE_TESTS.md).
Hardware binary results live in
[`SPIN2_BINARY_TEST_REPORT.md`](SPIN2_BINARY_TEST_REPORT.md).

## Copy To The P2 SD Card

For a mounted SD card on the host:

```sh
mkdir -p /Volumes/<sdcard>/spin2
cp spin2/build/MB_01ALU.BIN /Volumes/<sdcard>/spin2/MB_01ALU.BIN
```

For direct transfer through the Propeller, build and run the temporary RAM SD
loader:

```sh
make spin2-sd-put TOOLCHAIN=catalina PORT=/dev/cu.usbserial-XXXX \
  SPIN2_SD_FILE=spin2/build/MB_01ALU.BIN

make spin2-sd-sync TOOLCHAIN=catalina PORT=/dev/cu.usbserial-XXXX
```

`spin2-sd-put` transfers one binary. `spin2-sd-sync` runs `make spin2`, loads the
temporary Catalina SD receiver to RAM, transfers every `spin2/build/*.BIN` to
`/spin2`, and writes `/spin2/INDEX.TXT` with the source-to-SD name mapping.

## Berry Smoke Tests

```berry
import spin2

print(spin2.list())
handle = spin2.start("MB_01ALU.BIN")
print(spin2.info(handle))
print(spin2.call(handle, 1, 10, 4, 0))
spin2.stop(handle)
```

The broader Berry-side smoke script can be run from the repo examples folder:

```sh
berry examples/p2_spin2_mailbox_suite.be
berry examples/p2_spin2_standalone_suite.be
```

or paste/run the file contents from the examples at the P2 Berry prompt.

## v1 Mailbox Convention

`spin2.call(handle, method_id, args...)` is intentionally small for the first
port. It supports integer arguments only and expects compatible binaries to use
the Hub-RAM mailbox passed in `PTRA`.

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
13 method_addr reserved for future dispatch helpers
```

Compatible binaries put a method table at the start of the binary:

```text
long method_count
long method_0_entry
long method_1_entry
...
```

Berry starts the PASM service after the table, so callable PASM binaries in this
tree assemble their actual service code at `ORG 0` and treat the table as Berry
metadata rather than executable cog code.

High-level FlexSpin images do not have the mailbox table, and their `.BIN`
payloads contain absolute Hub-address references. Berry loads Spin2 payloads
from heap memory, so those images are not relocatable. The loader rejects the
bundled high-level `S2_*.BIN` examples before file load and detects the normal
FlexSpin high-level boot layout for other binaries, raising `value_error`
rather than starting a cog that can hang the board. Raw standalone PASM images
that do not use that boot layout start with `PTRA == nil`;
`spin2.info(handle)["abi"]` returns
`standalone` for those images and `mailbox` for Berry-callable binaries.
