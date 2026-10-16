# Berry/P2 recovery from the 2026-10-04 backup

This directory preserves **55 exact file variants across 24 paths**, deduplicated
from 107 occurrences in 31 recovered source snapshots. They are derived from
this Berry project and retain its [MIT license](../../LICENSE). The original
backup and private supporting material remain local; this directory contains
source patches and sanitized provenance only.

## Accepted base and active integration

The archived main checkout already matched public `fix/p2-stability` at
`b702a03787620aa461718b426e484294d7f33d0b` (2026-09-20 23:39:18 UTC).
The recovery branch starts there, retaining the 16 stabilization commits beyond
`master`. It does not replace the interpreter with an older diagnostic entry
point or weaken the final ownership, cancellation or allocation protections.

The coherent addition integrated into active tooling is
[`verify_uart_transcript.py`](../../tools/p2/hil/verify_uart_transcript.py),
adapted from the recovered interactive-product verifier. It checks existing
case/TX/RX records offline, rejects echo-only output and inconsistent framing,
and supports explicit boot markers for different profiles. Completion markers
must be exact, unique, and terminal. Its receipt describes **transcript
consistency**, not hardware authenticity. Its origin hash is recorded in
`integrated-tool-provenance.json`.

No C runtime change is selected from the 55 variants. Recovered differences
are earlier experiments or alternatives to the final implementation, rather
than an additive patch series. Unit tests for the integrated tool use clearly
labeled synthetic input and do not open a device.

## Experimental archive and decisions

Every patch is relative to the pinned base above and reconstructs one original
file byte for byte. **Apply one variant only in a disposable checkout** after
reviewing its dependencies; do not apply this directory as a patch series.
The patch ID, original file SHA256, archive SHA256, source snapshot names and
original timestamps are in [`manifest.json`](manifest.json). A readable list of
all variants is in [`VARIANTS.md`](VARIANTS.md).

| Variants | Decision and reason |
| --- | --- |
| V01 | Historical clock wording makes broader integer-width assumptions than the corrected public document. Preserve for history. |
| V02-V05 | Earlier configuration, partition declaration and library-instrumentation variants. Keep the final public configuration. |
| V06-V18 | Constructor, admission, storage and source-worker probes mix diagnostics with older implementations; some remove later help or safety code. Preserve as alternatives. |
| V19-V20 | Earlier scheduler storage precedes the final VM-owned state isolation. Do not reintroduce shared state. |
| V21-V22 | Earlier polling/interrupt/Hub access paths predate final fixes. Preserve for comparison. |
| V23-V29 | Older exit handling or diagnostic programs replace the normal interactive entry point. Do not activate in the product. |
| V30-V32 | Earlier heap probes remove later fail-closed arena admission checks. Preserve only. |
| V33-V39 | SDK lock experiments, worker-stop instrumentation, earlier partition/special-storage/VM APIs. Require separate design and target review. |
| V40-V50 | Earlier native tests with fewer final ownership, constructor or failure checks, plus debug-only tracing. Keep current tests active. |
| V51 | Would accept ambiguous `lsof` failures as a free port. Explicitly rejected for active integration. |
| V52-V54 | Earlier runner/provenance coverage; would remove maintained checks or evidence handling. Preserve only. |
| V55 | Would remove the regression that rejects ambiguous port detection. Explicitly rejected for active integration. |

## Validation and limits

Run archive reconstruction and the offline parser tests from the repository root:

```sh
python tools/verify_recovery_variants.py
python -m unittest discover -s tools/tests -p test_uart_transcript.py
python -O -m unittest discover -s tools/tests -p test_uart_transcript.py
```

`verify_recovery_variants.py` uses an isolated temporary Git index, reconstructs
each file and compares its SHA256 to the recovered original. It parses recovered
Python variants without importing or running them. It does not change the real
index or worktree. This establishes lossless preservation, not runtime validity.

See [`VALIDATION.md`](VALIDATION.md) for the commands and actual results from the
Windows recovery session. No Catalina target build, native C runtime test or
physical Propeller verification is claimed for this recovery. The experiments
are **unvalidated for execution**. The active offline parser is **unit tested**.

## Excluded material

The local raw recovery, archives, binaries, generated headers, caches,
toolchains, flash backups, UART captures, historical receipts, personal notes,
conversation/task plans, authorization scripts and credentials are not included.
They are unnecessary to reconstruct these variants and may contain private or
environment-specific data. `/recovery/` is ignored to reduce accidental staging.
No new authority is inferred from old instructions found in the backup.
