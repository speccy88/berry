#!/usr/bin/env python3
"""Check effective native registration after preprocessing real P2 configuration."""
from pathlib import Path
import re
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
EXTENDED = {'global', 'sys', 'debug', 'gc', 'strict', 'time'}


def registered(profile, extra=()):
    compiler = shutil.which('cc') or shutil.which('gcc')
    if not compiler:
        raise RuntimeError('A C preprocessor is required')
    command = [compiler, '-E', '-P', '-x', 'c',
               '-I' + str(ROOT / 'port/p2/include'), '-I' + str(ROOT / 'src'),
               '-DBE_P2_PROFILE=' + str(profile), *extra,
               str(ROOT / 'port/p2/overrides/be_modtab_p2.c')]
    result = subprocess.run(command, check=True, capture_output=True, text=True)
    table = re.search(r'be_module_table\s*\[\s*\]\s*=\s*\{(.*?)\};',
                      result.stdout, re.DOTALL)
    if not table:
        raise RuntimeError('Native module table was not emitted')
    modules = set(re.findall(r'&\s*be_native_module_(\w+)', table.group(1)))
    if not {'task', 'undefined'} <= modules:
        raise RuntimeError('Native module parser did not recognize invariant entries')
    return modules


class ModuleConfigurationTests(unittest.TestCase):
    def test_xmm_includes_core_extended_libraries(self):
        modules = registered(4)
        self.assertTrue(EXTENDED <= modules,
                        'Missing native libraries: ' + ', '.join(sorted(EXTENDED - modules)))
        self.assertIn('introspect', modules)

    def test_minimal_profile_remains_small(self):
        self.assertFalse(EXTENDED & registered(1))

    def test_non_xmm_default_is_unchanged(self):
        self.assertFalse(EXTENDED & registered(2))

    def test_explicit_lean_override_is_respected(self):
        self.assertFalse(EXTENDED & registered(4, ['-DBE_P2_ENABLE_EXTENDED_MODULES=0']))


if __name__ == '__main__':
    unittest.main(verbosity=2)
