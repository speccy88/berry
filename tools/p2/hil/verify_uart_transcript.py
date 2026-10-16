#!/usr/bin/env python3
"""Check an offline UART transcript against its case fixture.

Derived from the recovered Berry/P2 interactive verifier (MIT). This parser
opens no device and cannot attest that a transcript came from physical hardware.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re

class Rejected(ValueError):
    pass

def require(ok, message):
    if not ok:
        raise Rejected(message)

def verify(spec, log):
    lines = log.splitlines()
    require(lines.count('UART_TRANSPORT_COMPLETE') == 1, 'transport incomplete or duplicated')
    require(next((line for line in reversed(lines) if line), '') ==
            'UART_TRANSPORT_COMPLETE', 'data after transport completion')
    require(not re.search(r'^Lua:|bounded prompt timeout|Error Loading', log, re.M), 'transport failed')
    frames, boot, current = [], bytearray(), None
    for line in log.splitlines():
        if line.startswith('UART_CASE '):
            current = dict(name=line[10:], tx=[], rx=bytearray())
            frames.append(current)
        elif line.startswith('UART_TX_HEX '):
            require(current is not None, 'TX outside a case')
            current['tx'].append(bytes.fromhex(line[12:]))
        elif line.startswith('UART_RX_HEX '):
            data = bytes.fromhex(line[12:])
            (boot if current is None else current['rx']).extend(data)
    expected_boot = spec.get('boot_contains', ['Berry 1.1.0', '[xmm profile]', 'berry> '])
    require(isinstance(expected_boot, list) and expected_boot and
            all(isinstance(text, str) and text for text in expected_boot),
            'boot_contains must be a nonempty list of nonempty strings')
    require(all(text.encode('utf-8') in boot for text in expected_boot),
            'missing expected boot bytes')
    require(len({case['name'] for case in spec['cases']}) == len(spec['cases']),
            'duplicate case name in fixture')
    require(len(frames) == len(spec['cases']), 'case count differs')
    normalized = []
    all_rx = bytearray(boot)
    for case, frame in zip(spec['cases'], frames):
        require(case['name'] == frame['name'], 'case order/name differs')
        require(frame['tx'] == [bytes.fromhex(case['tx_hex'])], 'TX differs from fixture')
        raw = bytes(frame['rx'])
        all_rx.extend(raw)
        text = raw.replace(b'\r\n', b'\n').replace(b'\r', b'').decode('utf-8', 'strict')
        normalized.append(dict(name=case['name'], rx=text))
        prompt = case['prompt']
        if prompt == 'either':
            require(text.endswith(('berry> ', '...> ')), case['name'] + ': missing prompt')
        elif prompt:
            require(text.rstrip().endswith(prompt.rstrip()), case['name'] + ': missing ending prompt')
        if case['line'] is not None:
            require(case['line'] in text.splitlines(), case['name'] + ': exact output missing')
            require(case['line'].encode() not in bytes.fromhex(case['tx_hex']),
                    case['name'] + ': output oracle also appears in input echo')
        if case['contains'] is not None:
            # Error labels and interrupt messages must start a received line.
            require(any(line.startswith(case['contains']) for line in text.splitlines()),
                    case['name'] + ': expected response missing')
        failures = re.findall(r'^(?:\w+_error|assert_failed|memory_error):[^\n]*', text, re.M)
        if failures:
            require(case['contains'] and all(f.startswith(case['contains']) for f in failures),
                    case['name'] + ': unexpected Berry exception ' + repr(failures))
    if spec['mode'] == 'full':
        require(any('interactive example passed' in x['rx'].splitlines() for x in normalized),
                'example completion missing')
        require(any('interactive help checks passed' in x['rx'].splitlines() for x in normalized),
                'help smoke completion missing')
    return bytes(all_rx), normalized

def negative_controls(spec, log):
    tests = {'no_uart': re.sub(r'^UART_RX_HEX .*\n?', '', log, flags=re.M),
             'incomplete': log.replace('UART_TRANSPORT_COMPLETE', 'NOT_COMPLETE'),
             'wrong_tx': log.replace('UART_TX_HEX ', 'UART_TX_HEX 00', 1),
             'wrong_case': log.replace('UART_CASE ', 'UART_CASE altered_', 1),
             'host_failure': log + '\nLua: forced failure\n'}
    rows = log.splitlines()
    # Preserve real framing while replacing received content with echoed TX only.
    last_tx = ''
    echo = []
    for line in rows:
        if line.startswith('UART_TX_HEX '): last_tx = line[12:]
        echo.append('UART_RX_HEX ' + last_tx if line.startswith('UART_RX_HEX ') else line)
    tests['echo_only'] = '\n'.join(echo)
    for needle, replacement, name in [(b'KeyboardInterrupt', b'NotAnInterrupt!!', 'lost_interrupt'),
                                      (b'\r\n42\r\n', b'\r\n41\r\n', 'wrong_arithmetic'),
                                      (spec['token'].encode(), b'wrong_nonce!', 'wrong_nonce')]:
        changed = []
        for line in rows:
            if line.startswith('UART_RX_HEX '):
                line = 'UART_RX_HEX ' + bytes.fromhex(line[12:]).replace(needle, replacement).hex()
            changed.append(line)
        candidate = '\n'.join(changed)
        if candidate != '\n'.join(rows): tests[name] = candidate
    checked = []
    for name, candidate in tests.items():
        try:
            verify(spec, candidate)
        except (Rejected, ValueError):
            checked.append(name)
        else:
            raise Rejected('negative control accepted: ' + name)
    require(len(checked) >= 6, 'insufficient negative controls')
    return checked

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('spec', type=Path)
    ap.add_argument('log', type=Path)
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    try:
        spec = json.loads(a.spec.read_text(encoding='utf-8'))
        log = a.log.read_text(encoding='utf-8')
        raw, frames = verify(spec, log)
        negatives = negative_controls(spec, log) if a.selftest else []
    except (OSError, ValueError, KeyError, TypeError) as error:
        ap.error(str(error))
    prefix = a.log.with_suffix('')
    prefix.with_suffix('.rx.bin').write_bytes(raw)
    prefix.with_suffix('.rx.txt').write_text(raw.decode('utf-8'), encoding='utf-8')
    result = dict(passed=True, scope='offline transcript consistency only; no hardware attestation',
                  case_count=len(frames), raw_bytes=len(raw), cases=frames,
                  negative_controls=negatives,
                  spec_sha256=hashlib.sha256(a.spec.read_bytes()).hexdigest(),
                  log_sha256=hashlib.sha256(a.log.read_bytes()).hexdigest(),
                  raw_sha256=hashlib.sha256(raw).hexdigest())
    target = prefix.with_suffix('.verified.json')
    target.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(dict(passed=True, cases=len(frames), negative_controls=negatives,
                         evidence=str(target))))

if __name__ == '__main__':
    main()
