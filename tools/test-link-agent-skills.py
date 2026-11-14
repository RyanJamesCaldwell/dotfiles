import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('linker', Path(__file__).with_name('link-agent-skills.py'))
linker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(linker)

class LinkTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name) / 'home'
        self.source = Path(self.tmp.name) / 'source'
        for name in linker.AVAILABLE_SKILLS:
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

    def test_new_subset_ignores_unselected_collisions(self):
        old = self.home / '.agents/skills/rex'
        old.mkdir(parents=True)
        (old / 'keep.txt').write_text('user data')
        links = linker.plan(self.source, self.home, linker.PSTACK_SKILLS)
        self.assertEqual([dest.name for dest, _ in links], list(linker.PSTACK_SKILLS))
        self.assertEqual((old / 'keep.txt').read_text(), 'user data')
        self.assertFalse((self.home / '.agents/skills/arena').exists())

    def test_selected_collision_prevents_all_links(self):
        (self.home / '.agents/skills/architect').mkdir(parents=True)
        with self.assertRaisesRegex(ValueError, 'Existing skill'):
            linker.plan(self.source, self.home, linker.PSTACK_SKILLS)
        self.assertFalse((self.home / '.agents/skills/arena').exists())

    def test_unselected_missing_skill_ignored(self):
        (self.source / 'skills/rex/SKILL.md').unlink()
        links = linker.plan(self.source, self.home, ['bro'])
        self.assertEqual([dest.name for dest, _ in links], ['bro'])

    def test_invalid_selection_refused_before_git(self):
        for selection in ([], ['bro', 'bro'], ['../rex'], ['unknown']):
            with self.subTest(selection=selection), self.assertRaises(ValueError):
                linker.plan(self.source, self.home, selection)
        self.mock.assert_not_called()

    def test_subset_apply_and_repeat_preserves_unrelated_data(self):
        old = self.home / '.codex/skills/rex'
        old.mkdir(parents=True)
        (old / 'keep.txt').write_text('user data')
        with patch.object(linker.Path, 'home', return_value=self.home), patch('sys.argv', [
                'link-agent-skills.py', '--source', str(self.source), '--apply',
                '--skills', *linker.PSTACK_SKILLS]):
            linker.main()
        for name in linker.PSTACK_SKILLS:
            self.assertEqual((self.home / '.agents/skills' / name).resolve(),
                             (self.source / 'skills' / name).resolve())
        self.mock.side_effect = [linker.PIN, '']
        self.assertEqual(linker.plan(self.source, self.home, linker.PSTACK_SKILLS), [])
        self.assertEqual((old / 'keep.txt').read_text(), 'user data')

    def test_subset_still_requires_pin_and_clean_checkout(self):
        for responses, error in ((['wrong'], 'reviewed commit'),
                                 ([linker.PIN, '!! private.txt'], 'clean')):
            self.mock.side_effect = responses
            with self.subTest(error=error), self.assertRaisesRegex(ValueError, error):
                linker.plan(self.source, self.home, linker.PSTACK_SKILLS)

class RealCheckoutTests(unittest.TestCase):
    def test_real_git_subset_install_and_ignored_dirt(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / 'source'
            home = Path(tmp) / 'home'
            source.mkdir()
            for name in linker.AVAILABLE_SKILLS:
                folder = source / 'skills' / name
                folder.mkdir(parents=True)
                (folder / 'SKILL.md').write_text('synthetic fixture\n')
            (source / '.gitignore').write_text('private.txt\n')
            subprocess.run(['git', 'init', '--quiet', str(source)], check=True)
            subprocess.run(['git', '-C', str(source), 'add', '.'], check=True)
            subprocess.run(['git', '-C', str(source), '-c', 'user.name=Skill test',
                            '-c', 'user.email=test@example.invalid', 'commit', '--quiet',
                            '-m', 'Synthetic skills'], check=True)
            pin = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
            old = home / '.agents/skills/rex'
            old.mkdir(parents=True)
            (old / 'keep.txt').write_text('user data')
            with patch.object(linker, 'PIN', pin):
                links = linker.plan(source, home, linker.PSTACK_SKILLS)
                self.assertEqual(len(links), 7)
                for dest, target in links:
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    dest.symlink_to(target)
                self.assertEqual(linker.plan(source, home, linker.PSTACK_SKILLS), [])
                (source / 'private.txt').write_text('synthetic private file')
                with self.assertRaisesRegex(ValueError, 'clean'):
                    linker.plan(source, home, linker.PSTACK_SKILLS)
                (source / 'private.txt').unlink()
                (source / 'skills/bro/SKILL.md').write_text('changed\n')
                with self.assertRaisesRegex(ValueError, 'clean'):
                    linker.plan(source, home, linker.PSTACK_SKILLS)
            with patch.object(linker, 'PIN', '0' * 40):
                with self.assertRaisesRegex(ValueError, 'reviewed commit'):
                    linker.plan(source, home, linker.PSTACK_SKILLS)
            self.assertEqual((old / 'keep.txt').read_text(), 'user data')


if __name__ == '__main__':
    unittest.main()
