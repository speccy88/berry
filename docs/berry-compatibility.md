# Berry Compatibility on P2

## Current coverage style

The P2 port keeps upstream Berry behavior where it can, then documents host-like features that cannot honestly work on bare metal.

Current smoke coverage includes core builtins and modules through
`tests/p2/smoke_compat.be` plus the serial `compat` runner's scripted
`input()` handshake, library smoke through `tests/p2/smoke_libraries.be`, and
SD filesystem smoke through `tests/p2/smoke_sd.be`.

## Covered examples

- Core builtins: `print`, `input`, `classname`, `classof`, `str`, `number`, `int`, `real`, `bool`, `type`, `size`, `super`, `assert`, `compile`, `module`, `issubclass`, `isinstance`, `call`, `list`, `map`, `range`, and `bytes`.
- SD-backed modules: `math`, `json`, `string`, `os`, `os.path`, `libstore`, `p2mem` and `task` have targeted P2 smoke coverage.
- Native/hardware modules: `p2`, `i2c`, `spi`, archived/opt-in `spin2`, and WiFi scaffolding are documented in the P2 docs and coverage matrix. The normal default P2 image does not provide `import spin2`.

## Host-like limitations

These features must be documented, skipped, or adapted rather than faked:

- `input()` remains an interactive serial operation for users, but the `compat`
  smoke harness covers the prompt/response path so it is not an untested stub.
- Host process, environment, and shell behaviors are not assumed on bare metal.
- Filesystem behavior maps to the mounted SD card, not to a host working directory.
- Network APIs are not present unless a validated coprocessor module is explicitly initialized.
- Debug output can perturb timing and memory, so trace-style features should default off.

## Compatibility rule

A stub is not compatibility. If a feature cannot work on bare metal, expose a clear error or document it as unsupported.
