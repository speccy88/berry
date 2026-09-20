#!/usr/bin/env python3
"""Execute the production REPL; host fixtures are not physical UART evidence."""
import argparse
import hashlib
import json
import os
import re
from pathlib import Path

import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cc', default='gcc')
    parser.add_argument('--sanitize', action='store_true')
    parser.add_argument('--case', choices=('host', 'p2', 'help', 'serial', 'main-exit', 'all'), default='all')
    args = parser.parse_args()
    (ROOT / 'build').mkdir(exist_ok=True)
    out = Path(tempfile.mkdtemp(prefix='repl-', dir=ROOT / 'build'))
    out.chmod(0o755)  # readable by the external CI artifact collector
    snap = out / 'snapshot'
    hashes, commands = {}, []
    for directory in ('src', 'default', 'tools/coc'):
        for path in sorted((ROOT / directory).rglob('*')):
            if path.is_file() and (path.suffix in ('.c', '.h', '.py') or path.name == 'coc'):
                rel = path.relative_to(ROOT)
                data = path.read_bytes()
                hashes[str(rel)] = hashlib.sha256(data).hexdigest()
                dest = snap / rel
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(data)
    for name in ('tests/native/test_repl.c', 'tests/native/test_p2_repl.c',
                 'tests/native/test_p2_main_exit.c', 'port/p2/runtime/main_p2.c',
                 'port/p2/runtime/berry_port.c', 'port/p2/runtime/p2_vm_state.c',
                 'port/p2/include/p2_vm_state.h', 'port/p2/include/p2_clock.h',
                 'tests/native/test_p2_help.c', 'port/p2/overrides/be_p2lib_p2.c',
                 'port/p2/include/p2_cog_registry.h', 'tools/test_repl.py',
                 'tests/native/test_p2_serial.c', 'port/p2/runtime/p2_smartserial.c'):
        data = (ROOT / name).read_bytes()
        hashes[name] = hashlib.sha256(data).hexdigest()
        (snap / Path(name).name).write_bytes(data)
    source = (snap / 'berry_port.c').read_text()
    start, end = 'static int p2_exit_requested;', 'void *be_fopen('
    if source.count(start) != 1 or source.count(end) != 1:
        raise RuntimeError('production editor slice boundaries changed')
    begin = source.index(start)
    (snap / 'p2_editor.inc').write_text(
        '#line %d "port/p2/runtime/berry_port.c"\n' % (source[:begin].count('\n') + 1)
        + source[begin:source.index(end)])
    main_source = (snap / 'main_p2.c').read_text()
    main_start = '#ifndef BE_P2_RUN_SD_MAIN\n'
    if main_source.count(main_start) != 1:
        raise RuntimeError('production P2 main slice boundary changed')
    begin = main_source.index(main_start)
    (snap / 'p2_main.inc').write_text(
        '#line %d "port/p2/runtime/main_p2.c"\n' % (main_source[:begin].count('\n') + 1)
        + main_source[begin:])
    # Keep real host filesystem callbacks; only console is supplied by the
    # production P2 editor/serial slice in the native byte-input fixture.
    (snap / 'host_port.c').write_text(
        '#define be_writebuffer host_writebuffer\n#define be_readstring host_readstring\n'
        '#include "default/be_port.c"\n')
    source = (snap / 'be_p2lib_p2.c').read_text()
    # Exact production function bodies, metadata only; no runtime replacements.
    parts = [source[source.index('enum {\n    P2_CLOSURE_COG_MAX'):
                    source.index('static void p2_module_set_func')]]
    for name in ('p2_map_set_int', 'p2_map_set_bool', 'p2_map_set_string',
                 'm_p2_closure_cog_capabilities', 'p2_help_names', 'm_p2_help'):
        matches = list(re.finditer(r'^static (?:void|int) ' + name + r'\([^\n]+\)\n\{\n.*?^\}',
                                  source, re.M | re.S))
        if len(matches) != 1:
            raise RuntimeError('ambiguous production helper: ' + name)
        parts.append(matches[0].group())
    (snap / 'p2_help.inc').write_text('\n\n'.join(parts) + '\n')
    (snap / 'hmi.h').write_text('int k_wait(void); int k_get(void); int k_ready(void);\n')
    serial_source = (snap / 'p2_smartserial.c').read_text()
    # Retain all production function bodies. Omit only FlexC's unused
    # binary-literal pin constants (not valid host C99).
    serial_start = serial_source.index('void p2_smartserial_init(')
    (snap / 'p2_smartserial.inc').write_text(serial_source[serial_start:])
    (snap / 'generate').mkdir()
    env = dict(os.environ, ASAN_OPTIONS='detect_leaks=1:halt_on_error=1',
               UBSAN_OPTIONS='halt_on_error=1:print_stacktrace=1')

    def run(name, argv, timeout=180):
        argv = list(map(str, argv))
        with (out / (name + '.log')).open('w') as log:
            try:
                rc = subprocess.run(argv, cwd=snap, env=env, stdout=log,
                                    stderr=subprocess.STDOUT, timeout=timeout).returncode
            except subprocess.TimeoutExpired:
                rc = 124
        commands.append(dict(name=name, argv=argv, returncode=rc))
        if rc:
            raise RuntimeError(f'{name}: exit {rc}; {out / (name + ".log")}')

    error = None
    try:
        run('generate', [sys.executable, snap / 'tools/coc/coc', '-o', snap / 'generate',
                         snap / 'src', snap / 'default', '-c', snap / 'default/berry_conf.h'])
        flags = ['-std=c99', '-O1', '-g', '-Wall', '-Wextra', '-fno-pie', '-no-pie',
                 '-I' + str(snap / 'src'), '-I' + str(snap / 'default')]
        if args.sanitize:
            flags += ['-fsanitize=address,undefined', '-fno-sanitize-recover=all', '-fno-omit-frame-pointer']
        for case in ('host', 'p2', 'help', 'serial', 'main-exit') if args.case == 'all' else (args.case,):
            if case == 'main-exit':
                run('compile-main-exit', [args.cc, *flags, '-I' + str(snap),
                    snap / 'test_p2_main_exit.c', '-o', out / 'test-main-exit'])
                run('main-exit', [out / 'test-main-exit'], 15)
                continue
            if case == 'serial':
                run('compile-serial', [args.cc, *flags, '-I' + str(snap),
                    snap / 'test_p2_serial.c', '-o', out / 'test-serial'])
                run('serial', [out / 'test-serial'], 15)
                continue
            extra = ['-I' + str(snap)]
            if case == 'p2':
                extra += ['-DBE_P2_ENABLE_MAIN_INTERRUPT=1', snap / 'p2_vm_state.c']
            port = snap / ('host_port.c' if case == 'p2' else 'default/be_port.c')
            test = snap / {'host': 'test_repl.c', 'p2': 'test_p2_repl.c',
                           'help': 'test_p2_help.c'}[case]
            run('compile-' + case, [args.cc, *flags, *extra,
                *sorted((snap / 'src').glob('*.c')), port, snap / 'default/be_modtab.c',
                test, '-lm', '-ldl', '-o', out / ('test-' + case)])
            run(case, [out / ('test-' + case)], 15)
        if any(hashlib.sha256((ROOT / p).read_bytes()).hexdigest() != h for p, h in hashes.items()):
            raise RuntimeError('source drift during test')
    except (OSError, RuntimeError) as exc:
        error = str(exc)
    receipt = dict(passed=error is None, scope=__doc__, source_sha256=hashes,
                   commands=commands, error=error)
    (out / 'results.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(dict(passed=error is None, error=error, evidence=str(out / 'results.json'))))
    return 0 if error is None else 1


if __name__ == '__main__':
    raise SystemExit(main())
