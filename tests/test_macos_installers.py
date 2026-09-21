"""Offline installer regression tests, including macOS's /bin/bash 3.2."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="skill installer ")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.repo = self.base / "repo"
        shutil.copytree(ROOT, self.repo, ignore=shutil.ignore_patterns(".git", "__pycache__"))
        self.home = self.base / "home"
        self.home.mkdir()
        self.bin = self.base / "bin"
        self.bin.mkdir()
        # A controlled PATH prevents discovering real agents or accessing the network.
        for command in ("bash", "dirname", "awk", "mktemp", "grep", "mkdir",
                        "ln", "rm", "find", "sort", "cp", "shasum", "rmdir"):
            source = Path("/bin") / command
            if not source.exists():
                source = Path("/usr/bin") / command
            (self.bin / command).symlink_to(source)
        self.stub("git", "exit 77")
        self.stub("readlink", "exit 78")
        self.env = {k: v for k, v in os.environ.items()
                    if k not in ("MY_SKILLS_INSTALL_STATE", "MY_SKILLS_INSTALL_STACK",
                                 "BASH_ENV", "CODEX_HOME")}
        self.env.update(HOME=str(self.home), PATH=str(self.bin),
                        CODEX_HOME=str(self.home / ".codex"))

    def stub(self, command, body="exit 0"):
        path = self.bin / command
        path.write_text("#!/bin/bash\n" + body + "\n")
        path.chmod(0o755)

    def run_script(self, path, *args, success=True):
        result = subprocess.run([str(self.repo / path), *args], cwd=self.base,
                                env=self.env, text=True, capture_output=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout + result.stderr

    def snapshot(self, skill):
        return {str(p.relative_to(self.repo / skill)): p.read_bytes()
                for p in (self.repo / skill).rglob("*") if p.is_file()}

    def assert_link(self, agent, skill):
        link = self.home / agent / "skills" / skill
        self.assertTrue(link.is_symlink())
        self.assertEqual(os.readlink(link), str(self.repo / skill))
        self.assertTrue((link / "SKILL.md").is_file())

    def test_local_install_twice_and_inventory(self):
        for agent in ("codex", "claude"):
            self.stub(agent)
        before = self.snapshot("git-commit")
        for _ in range(2):
            self.run_script("git-commit/install.sh")
            for agent in (".agents", ".claude"):
                self.assert_link(agent, "git-commit")
        self.assertEqual(before, self.snapshot("git-commit"))
        output = self.run_script("ls-skill.sh")
        self.assertIn("git-commit", output)
        self.assertIn("Codex, Claude Code", output)

    def test_absent_agents(self):
        output = self.run_script("git-commit/install.sh")
        self.assertIn("installed=0 skipped=2", output)
        self.assertIn("No installed skills", self.run_script("ls-skill.sh"))
        self.assertFalse((self.home / ".agents").exists())

    def test_remote_dependency_and_local_flag_forwarding(self):
        self.stub("codex")
        # Make a disposable local -> remote -> remote dependency chain.
        installer = self.repo / "git-commit/install.sh"
        installer.write_text(installer.read_text().replace(
            "DEPENDENCIES=()", 'DEPENDENCIES=("grill-me")'))
        before = {s: self.snapshot(s) for s in ("git-commit", "grill-me", "grilling")}
        for _ in range(2):
            output = self.run_script("git-commit/install.sh", "--skip-update")
            self.assertLess(output.index("skill=grilling"), output.index("skill=grill-me"))
            self.assertLess(output.index("skill=grill-me"), output.index("skill=git-commit"))
            for skill in before:
                self.assert_link(".agents", skill)
                self.assertEqual(before[skill], self.snapshot(skill))
        self.run_script("ls-skill.sh")

    def test_remote_fetch_failure_preserves_snapshot_and_link(self):
        self.stub("codex")
        self.run_script("grilling/install.sh", "--skip-update")
        before = self.snapshot("grilling")
        self.run_script("grilling/install.sh", success=False)
        self.assertEqual(before, self.snapshot("grilling"))
        self.assert_link(".agents", "grilling")

    def test_remote_update_with_empty_root_paths(self):
        self.stub("codex")
        upstream = self.base / "upstream"
        upstream.mkdir()
        shutil.copytree(self.repo / "grilling", upstream / "payload")
        self.env["TEST_UPSTREAM"] = str(upstream)
        self.stub("git", '''if [[ $1 == clone ]]; then
  for destination in "$@"; do :; done
  cp -R "$TEST_UPSTREAM" "$destination"
else
  printf 'fixture-revision\\n'
fi''')
        installer = self.repo / "grilling/install.sh"
        installer.write_text(installer.read_text().replace(
            'REMOTE_PATH="skills/productivity/grilling"', 'REMOTE_PATH="payload"'
        ).replace('REMOTE_ROOT_PATHS=("LICENSE")', 'REMOTE_ROOT_PATHS=()'))
        for _ in range(2):
            self.assertIn("revision=fixture-revision", self.run_script("grilling/install.sh"))
            self.assert_link(".agents", "grilling")

    def test_conflicts_and_relative_links(self):
        self.stub("codex")
        self.stub("claude")
        for skill in ("git-commit", "grilling"):
            args = () if skill == "git-commit" else ("--skip-update",)
            parent = self.home / ".agents/skills"
            parent.mkdir(parents=True, exist_ok=True)
            link = parent / skill
            for kind in ("file", "directory", "foreign_link", "broken_link"):
                with self.subTest(skill=skill, kind=kind):
                    if kind == "file":
                        link.write_text("keep me")
                    elif kind == "directory":
                        link.mkdir()
                    else:
                        link.symlink_to(self.home if kind == "foreign_link" else self.home / "missing")
                    self.assertIn("Conflict", self.run_script(f"{skill}/install.sh", *args, success=False))
                    self.assert_link(".claude", skill)
                    if kind == "file":
                        self.assertEqual(link.read_text(), "keep me")
                    elif kind.endswith("link"):
                        self.assertEqual(os.readlink(link), str(self.home if kind == "foreign_link" else self.home / "missing"))
                    if kind == "directory":
                        link.rmdir()
                    else:
                        link.unlink()
            link.symlink_to(os.path.relpath(self.repo / skill, parent))
            self.assertIn("already points", self.run_script(f"{skill}/install.sh", *args))


if __name__ == "__main__":
    unittest.main()
