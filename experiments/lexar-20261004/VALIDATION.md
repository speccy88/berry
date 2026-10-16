# Recovery validation

Executed on Windows, 2026-10-16. All commands below exited 0.

| Check | Actual result |
| --- | --- |
| `python tools/verify_recovery_variants.py` | 55 patches reconstruct exact recovered SHA256; Python variants parsed only |
| `python -B -m unittest discover -s tools/tests -p test_uart_transcript.py -v` | 17 unit tests passed |
| `python -B -O -m unittest discover -s tools/tests -p test_uart_transcript.py -v` | 17 unit tests passed |
| `python -B -m unittest tools.tests.test_build_p2.CommandTests tools.tests.test_build_p2.BuildTests.test_required_arguments tools.tests.test_build_p2.BuildTests.test_unsupported_host_is_failure -v` | 3 unit tests passed |

The parser tests use synthetic unit inputs. The three pre-existing build-wrapper
tests cover subprocess exit/stderr handling, argument validation and rejecting
an unsupported host. They do not compile Berry or invoke Catalina.

Publication review: all new archive/tool files scanned for token/key patterns,
credential assignments, authorization headers, email addresses and personal host
paths, with no matches. The archived and current Berry MIT LICENSE hashes match.
No external SDK/library source, private log, conversation, task plan, credential
helper or binary is included. This review is scoped to the explicit staged files.

**Not run:** native C tests, Catalina target build, board/UART execution, flash.
The 55 alternatives are preserved byte for byte but remain unvalidated for runtime use.
