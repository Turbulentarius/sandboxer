"""Offline setup checks: python3 -m unittest discover -s tests -v."""
import hashlib
import os
import re
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile

SCRIPT = Path(__file__).resolve().parents[1] / 'config/install-scripts/phpmyadmin.sh'


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.destination = self.root / 'sandbox'
        self.destination.mkdir()
        self.config = self.root / 'config.inc.php'
        self.config.write_text('<?php // fixture\n')
        self.archive = self.root / 'fixture.zip'
        with zipfile.ZipFile(self.archive, 'w') as archive:
            archive.writestr('phpMyAdmin-5.2.3-all-languages/index.php', '<?php\n')
        self.script = self.root / 'phpmyadmin.sh'
        self.prepare_script()
        binaries = self.root / 'bin'
        binaries.mkdir()
        wget = binaries / 'wget'
        wget.write_text('#!/bin/sh\n[ "${FAIL_DOWNLOAD:-0}" = 0 ] || exit 8\n'
                        'cp "$FIXTURE_ARCHIVE" "$2"\n')
        wget.chmod(0o755)
        self.env = dict(os.environ, SANDBOXER_ROOT=str(self.destination),
                        PHPMYADMIN_CONFIG=str(self.config),
                        FIXTURE_ARCHIVE=str(self.archive), FAIL_DOWNLOAD='0',
                        PATH=str(binaries) + os.pathsep + os.environ['PATH'])

    def prepare_script(self):
        # The tiny fixture has its own checksum. Change only the pinned hash in
        # a temporary script copy, leaving real checksum verification active.
        digest = hashlib.sha256(self.archive.read_bytes()).hexdigest()
        source, count = re.subn(r'^archive_sha256=[0-9a-f]{64}$',
                               'archive_sha256=' + digest,
                               SCRIPT.read_text(), flags=re.MULTILINE)
        self.assertEqual(count, 1)
        self.script.write_text(source)

    def run_setup(self):
        result = subprocess.run(['sh', str(self.script)], env=self.env,
                                capture_output=True, text=True)
        self.assertFalse(list(self.destination.glob('.phpmyadmin-setup.*')))
        return result

    def assert_failed(self):
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((self.destination / 'setup-completed').exists())
        self.assertNotIn('Setup complete.', result.stdout)

    def test_success_and_repeat_skip(self):
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.destination / 'setup-completed').is_file())
        installed = self.destination / 'phpmyadmin/config.inc.php'
        self.assertEqual(installed.read_bytes(), self.config.read_bytes())
        self.env['FAIL_DOWNLOAD'] = '1'
        self.assertEqual(self.run_setup().returncode, 0)

    def test_failed_download_then_retry(self):
        self.env['FAIL_DOWNLOAD'] = '1'
        self.assert_failed()
        self.assertFalse((self.destination / 'phpmyadmin').exists())
        self.env['FAIL_DOWNLOAD'] = '0'
        self.assertEqual(self.run_setup().returncode, 0)

    def test_invalid_archive(self):
        self.archive.write_text('not a zip archive')
        self.prepare_script()  # Pass checksum verification to exercise unzip failure.
        self.assert_failed()
        self.assertFalse((self.destination / 'phpmyadmin').exists())

    def test_checksum_mismatch(self):
        # Alter the downloaded bytes after pinning the fixture's checksum.
        with self.archive.open('ab') as archive:
            archive.write(b'changed download')
        self.assert_failed()
        self.assertFalse((self.destination / 'phpmyadmin').exists())

    def test_missing_configuration(self):
        self.config.unlink()
        self.assert_failed()

    def test_configuration_copy_failure(self):
        cp = self.root / 'bin/cp'
        cp.write_text('#!/bin/sh\nexit 1\n')
        cp.chmod(0o755)
        # Let the download fixture succeed so the installation copy fails.
        wget = self.root / 'bin/wget'
        wget.write_text('#!/bin/sh\ncat "$FIXTURE_ARCHIVE" > "$2"\n')
        self.assert_failed()
        self.assertFalse((self.destination / 'phpmyadmin').exists())
        self.assertTrue(self.config.exists())

    def test_existing_installation_is_preserved(self):
        installed = self.destination / 'phpmyadmin'
        installed.mkdir()
        existing = installed / 'keep.txt'
        existing.write_text('existing data')
        self.assert_failed()
        self.assertEqual(existing.read_text(), 'existing data')


if __name__ == '__main__':
    unittest.main()
