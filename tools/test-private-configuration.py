"""Exercise apply with a synthetic local external; never fetch private data."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
TARGET = '.local/share/agent-skills'
HOOKS = ('run_before_80-private-source-check.py.tmpl',
         'run_after_90-private-source.py.tmpl')


class ApplyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source = self.root / 'source'
        self.home = self.root / 'home with spaces'
        self.remote = self.root / 'synthetic-source'
        self.source.mkdir()
        self.home.mkdir()
        self.remote.mkdir()
        (self.root / 'config.yaml').write_text('data:\n  profile: personal\n')
        self.env = dict(os.environ, CI='', GIT_ALLOW_PROTOCOL='file', GIT_TERMINAL_PROMPT='0')
        self.git(self.remote, 'init', '--quiet', '--initial-branch=main')
        (self.remote / 'tools').mkdir()
        (self.remote / 'tools/chezmoi-sync.py').write_text(
            'import argparse\nfrom pathlib import Path\n'
            'p=argparse.ArgumentParser(); p.add_argument("--destination"); a=p.parse_args()\n'
            'payload=Path(__file__).resolve().parents[1]/"payload.txt"\n'
            '(Path(a.destination)/"local-state.txt").write_text(payload.read_text())\n')
        self.update_remote('one')
        rendered = self.render((ROOT / '.chezmoiexternal.toml').read_text())
        entry = tomllib.loads(rendered)[TARGET]
        expected_url = entry['url']
        parsed = urlparse(expected_url)
        ssh_url = f'git@{parsed.netloc}:{parsed.path.lstrip("/")}'
        local_url = self.remote.as_uri()
        for hook in HOOKS:
            text = (ROOT / hook).read_text().replace(expected_url, local_url).replace(ssh_url, local_url)
            (self.source / hook).write_text(text)
        fixture = '{{ if not (env "CI") }}\n'
        fixture += f'[{json.dumps(TARGET)}]\n  type = "git-repo"\n'
        fixture += '  url = ' + json.dumps(local_url) + '\n'
        fixture += '  refreshPeriod = ' + json.dumps(entry['refreshPeriod']) + '\n'
        for operation in ('clone', 'pull'):
            fixture += f'[{json.dumps(TARGET)}.{operation}]\n'
            fixture += '  args = ' + json.dumps(entry[operation]['args']) + '\n'
        fixture += '{{ end }}\n'
        (self.source / '.chezmoiexternal.toml').write_text(fixture)

    def git(self, root, *args):
        return subprocess.check_output(['git', '-C', str(root), *args], text=True, stderr=subprocess.DEVNULL).strip()

    def update_remote(self, value):
        (self.remote / 'payload.txt').write_text(value)
        self.git(self.remote, 'add', '.')
        self.git(self.remote, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                 'commit', '--quiet', '-m', 'Synthetic fixture')

    def command(self, *args):
        return ['chezmoi', '--no-tty', '--source', str(self.source), '--destination', str(self.home),
                '--cache', str(self.root / 'cache'), '--persistent-state', str(self.root / 'state.db'),
                '--config', str(self.root / 'config.yaml'), *args]

    def render(self, text, ci=''):
        result = subprocess.run(self.command('execute-template'), input=text, text=True,
                                capture_output=True, env=dict(self.env, CI=ci))
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def apply(self, *args, success=True, ci=''):
        result = subprocess.run(self.command('apply', *args), text=True, capture_output=True,
                                env=dict(self.env, CI=ci))
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def test_normal_apply_clones_updates_and_repeats(self):
        self.apply()
        marker = self.home / 'local-state.txt'
        self.assertEqual(marker.read_text(), 'one')
        self.update_remote('two')
        self.apply()
        self.assertEqual(marker.read_text(), 'two')
        self.apply()
        self.assertEqual(marker.read_text(), 'two')

    def test_ci_omits_private_source_and_hooks(self):
        data = tomllib.loads(self.render((ROOT / '.chezmoiexternal.toml').read_text(), ci='1'))
        self.assertNotIn(TARGET, data)
        for hook in HOOKS:
            self.assertEqual(self.render((ROOT / hook).read_text(), ci='1').strip(), '')
        self.apply(ci='1')
        self.assertFalse((self.home / TARGET).exists())
        self.assertFalse((self.home / 'local-state.txt').exists())

    def test_literal_shell_metacharacters_in_destination(self):
        self.home = self.root / "home$synthetic_unset_variable 'quoted'"
        self.home.mkdir()
        self.apply()
        self.assertEqual((self.home / 'local-state.txt').read_text(), 'one')
        self.apply()
        self.assertEqual((self.home / 'local-state.txt').read_text(), 'one')

    def test_dry_run_does_not_execute_setup(self):
        self.apply('--dry-run')
        self.assertFalse((self.home / 'local-state.txt').exists())

    def test_dirty_source_is_preserved_before_update(self):
        self.apply()
        checkout = self.home / TARGET
        revision = self.git(checkout, 'rev-parse', 'HEAD')
        (checkout / 'local-user-data').write_text('keep')
        self.update_remote('two')
        self.apply(success=False)
        self.assertEqual((checkout / 'local-user-data').read_text(), 'keep')
        self.assertEqual(self.git(checkout, 'rev-parse', 'HEAD'), revision)
        self.assertEqual((self.home / 'local-state.txt').read_text(), 'one')

    def test_foreign_directory_is_preserved(self):
        checkout = self.home / TARGET
        checkout.mkdir(parents=True)
        (checkout / 'keep').write_text('user data')
        self.apply(success=False)
        self.assertEqual((checkout / 'keep').read_text(), 'user data')
        self.assertFalse((self.home / 'local-state.txt').exists())

    def test_foreign_repository_is_preserved(self):
        checkout = self.home / TARGET
        checkout.mkdir(parents=True)
        self.git(checkout, 'init', '--quiet')
        self.git(checkout, 'remote', 'add', 'origin', (self.root / 'different-source').as_uri())
        (checkout / 'keep').write_text('user data')
        self.apply(success=False)
        self.assertEqual((checkout / 'keep').read_text(), 'user data')

    def test_detached_checkout_fast_forwards(self):
        self.apply()
        checkout = self.home / TARGET
        self.git(checkout, 'checkout', '--quiet', '--detach')
        self.update_remote('two')
        self.apply()
        self.assertEqual((self.home / 'local-state.txt').read_text(), 'two')

    def test_unpublished_commit_is_preserved_without_running_setup(self):
        self.apply()
        checkout = self.home / TARGET
        (checkout / 'local-commit').write_text('user data')
        self.git(checkout, 'add', '.')
        self.git(checkout, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                 'commit', '--quiet', '-m', 'Local user change')
        revision = self.git(checkout, 'rev-parse', 'HEAD')
        self.apply(success=False)
        self.assertEqual(self.git(checkout, 'rev-parse', 'HEAD'), revision)
        self.assertEqual((checkout / 'local-commit').read_text(), 'user data')

    def test_symlink_source_is_refused(self):
        actual = self.root / 'existing-data'
        actual.mkdir()
        (actual / 'keep').write_text('user data')
        checkout = self.home / TARGET
        checkout.parent.mkdir(parents=True)
        checkout.symlink_to(actual, target_is_directory=True)
        self.apply(success=False)
        self.assertEqual((actual / 'keep').read_text(), 'user data')


if __name__ == '__main__':
    unittest.main()
