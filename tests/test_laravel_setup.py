"""Offline checks for preserving apps and publishing only successful installs."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'config/install-scripts/laravel.sh'


class LaravelSetupTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.destination = self.root / 'www'
        self.destination.mkdir()
        self.template = self.root / 'template'
        (self.template / 'vendor').mkdir(parents=True)
        (self.template / 'database').mkdir()
        (self.template / 'artisan').write_text('fixture')
        (self.template / 'vendor/autoload.php').write_text('fixture')
        (self.template / '.env.example').write_text('APP_URL=http://localhost\nAPP_KEY=\n')
        binaries = self.root / 'bin'
        binaries.mkdir()
        php = binaries / 'php85'
        php.write_text("#!/bin/sh\n"
                       'echo "$2" >> "$CALL_LOG"\n'
                       '[ "$2" != "${FAIL_COMMAND:-}" ] || exit 1\n'
                       'case "$2" in\n'
                       '  key:generate) echo "fixture-key" >> .env ;;\n'
                       '  migrate) echo "fixture-db" > database/database.sqlite ;;\n'
                       'esac\n')
        php.chmod(0o755)
        self.calls = self.root / 'calls'
        self.env = dict(os.environ, SANDBOXER_ROOT=str(self.destination),
                        LARAVEL_TEMPLATE=str(self.template), CALL_LOG=str(self.calls),
                        FAIL_COMMAND='', PATH=str(binaries) + os.pathsep + os.environ['PATH'])

    def run_setup(self):
        result = subprocess.run(['sh', str(SCRIPT)], env=self.env,
                                capture_output=True, text=True)
        self.assertFalse(list(self.destination.glob('.laravel-setup.*')))
        return result

    def test_success_and_repeat_preserves_key_database_and_edits(self):
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        app = self.destination / 'laravel'
        self.assertIn('APP_URL=http://laravel.localhost', (app / '.env').read_text())
        (app / '.env').write_text('developer-key')
        (app / 'database/database.sqlite').write_text('developer-data')
        (app / 'artisan').write_text('developer-edit')
        before = self.calls.read_text()
        self.assertEqual(self.run_setup().returncode, 0)
        self.assertEqual(self.calls.read_text(), before)
        self.assertEqual((app / '.env').read_text(), 'developer-key')
        self.assertEqual((app / 'database/database.sqlite').read_text(), 'developer-data')
        self.assertEqual((app / 'artisan').read_text(), 'developer-edit')

    def test_initialization_failure_leaves_no_app_and_allows_retry(self):
        for command in ['package:discover', 'key:generate', 'migrate']:
            with self.subTest(command=command):
                self.env['FAIL_COMMAND'] = command
                result = self.run_setup()
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse((self.destination / 'laravel').exists())
        self.env['FAIL_COMMAND'] = ''
        self.assertEqual(self.run_setup().returncode, 0)

    def test_missing_template_does_not_publish(self):
        (self.template / 'vendor/autoload.php').unlink()
        self.assertNotEqual(self.run_setup().returncode, 0)
        self.assertFalse((self.destination / 'laravel').exists())

    def test_existing_app_is_preserved_without_marker(self):
        app = self.destination / 'laravel'
        app.mkdir()
        (app / 'keep.txt').write_text('existing app')
        self.assertEqual(self.run_setup().returncode, 0)
        self.assertEqual((app / 'keep.txt').read_text(), 'existing app')
        self.assertFalse(self.calls.exists())

    def test_dangling_symlink_is_preserved(self):
        app = self.destination / 'laravel'
        app.symlink_to(self.root / 'missing')
        self.assertEqual(self.run_setup().returncode, 0)
        self.assertTrue(app.is_symlink())
        self.assertFalse(self.calls.exists())

    def test_phpmyadmin_marker_does_not_skip_laravel(self):
        (self.destination / 'setup-completed').touch()
        self.assertEqual(self.run_setup().returncode, 0)
        self.assertTrue((self.destination / 'laravel/artisan').is_file())


if __name__ == '__main__':
    unittest.main()
