import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('linker', Path(__file__).with_name('link-agent-skills.py'))
linker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(linker)

class LinkTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name) / 'home'
        self.source = Path(self.tmp.name) / 'source'
        for name in linker.SKILLS:
            path = self.source / 'skills' / name
            path.mkdir(parents=True)
            (path / 'SKILL.md').write_text('synthetic fixture')
        self.mock = patch.object(linker.subprocess, 'check_output', side_effect=[linker.PIN + '\n', '']).start()
        self.addCleanup(patch.stopall)

    def test_preview_does_not_mutate(self):
        self.assertEqual(len(linker.plan(self.source, self.home)), 4)
        self.assertFalse(self.home.exists())

    def test_existing_directory_refused(self):
        (self.home / '.agents/skills/rex').mkdir(parents=True)
        with self.assertRaisesRegex(ValueError, 'Existing skill'):
            linker.plan(self.source, self.home)

    def test_codex_duplicate_refused(self):
        dest = self.home / '.codex/skills/oura-boros'
        dest.parent.mkdir(parents=True)
        dest.symlink_to(self.source / 'skills/oura-boros')
        with self.assertRaisesRegex(ValueError, 'Existing skill'):
            linker.plan(self.source, self.home)

    def test_dangling_link_refused(self):
        dest = self.home / '.agents/skills/rex'
        dest.parent.mkdir(parents=True)
        dest.symlink_to('/nonexistent-test-target')
        with self.assertRaisesRegex(ValueError, 'Existing skill'):
            linker.plan(self.source, self.home)

    def test_correct_links_idempotent(self):
        for name in linker.SKILLS:
            dest = self.home / '.agents/skills' / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.symlink_to(self.source / 'skills' / name)
        self.assertEqual(linker.plan(self.source, self.home), [])

    def test_wrong_pin_refused(self):
        self.mock.side_effect = ['wrong\n']
        with self.assertRaisesRegex(ValueError, 'reviewed commit'):
            linker.plan(self.source, self.home)

    def test_dirty_checkout_refused(self):
        self.mock.side_effect = [linker.PIN, '?? secret.json']
        with self.assertRaisesRegex(ValueError, 'clean'):
            linker.plan(self.source, self.home)

    def test_apply_and_repeat_in_temporary_home(self):
        with patch.object(linker.Path, 'home', return_value=self.home), patch('sys.argv', ['link-agent-skills.py', '--source', str(self.source), '--apply']):
            linker.main()
        for name in linker.SKILLS:
            self.assertEqual((self.home / '.agents/skills' / name).resolve(), (self.source / 'skills' / name).resolve())
        self.mock.side_effect = [linker.PIN, '']
        self.assertEqual(linker.plan(self.source, self.home), [])

    def test_missing_skill_refused(self):
        (self.source / 'skills/rex/SKILL.md').unlink()
        with self.assertRaisesRegex(ValueError, 'Missing skill'):
            linker.plan(self.source, self.home)

if __name__ == '__main__':
    unittest.main()
