import importlib.machinery
import importlib.util
from pathlib import Path
import plistlib
import os
import signal
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader("multichatgpt", str(ROOT / "bin/multichatgpt"))
spec = importlib.util.spec_from_loader(loader.name, loader)
cli = importlib.util.module_from_spec(spec)
loader.exec_module(cli)


class Clones(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="multichatgpt test ' ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "ChatGPT Renamed.app"
        macos = self.source / "Contents/MacOS"
        macos.mkdir(parents=True)
        with (self.source / "Contents/Info.plist").open("wb") as stream:
            plistlib.dump({"CFBundleIdentifier": cli.BUNDLE_ID, "CFBundleExecutable": "fake-chatgpt",
                          "CFBundlePackageType": "APPL", "CFBundleShortVersionString": "1.2.3",
                          "CFBundleURLTypes": [{"CFBundleURLSchemes": ["codex"]}]}, stream)
        fake = macos / "fake-chatgpt"
        fake.write_text('#!/bin/sh\nprintf "%s\\n" "$CODEX_HOME" "$@"\n')
        fake.chmod(0o755)
        self.apps = self.root / "Applications"
        self.data = self.root / "Profiles"

    def create(self):
        subprocess.run([str(ROOT / "bin/multichatgpt"), "clone", "chatgpt", "--app", str(self.source),
                        "--applications-dir", str(self.apps), "--data-dir", str(self.data)], check=True,
                       capture_output=True, text=True)

    def test_two_clones_have_independent_runtime_profiles(self):
        self.create()
        self.create()
        entries = list(cli.records(self.data))
        self.assertEqual(len(entries), 2)
        self.assertNotEqual(entries[0]["id"], entries[1]["id"])
        # The running app must belong to the named clone, even if the source moves.
        self.source.rename(self.root / "Moved Source.app")
        identifiers = []
        processes = []
        for entry in entries:
            self.assertRegex(entry["name"], r"^[A-Za-z]+$")
            app = Path(entry["app"])
            identifiers.append(cli.read_plist(app)["CFBundleIdentifier"])
            info = cli.read_plist(app)
            self.assertEqual(info["CFBundleDisplayName"], f"ChatGPT {entry['name']}")
            self.assertEqual(info["CFBundleShortVersionString"], "1.2.3")
            self.assertNotIn("CFBundleURLTypes", info)
            self.assertTrue((app / "Contents/MacOS/fake-chatgpt").is_file())
            processes.append(subprocess.Popen([str(app / "Contents/MacOS/profile-launcher")]))
        for process in processes:
            self.assertEqual(process.wait(timeout=10), 0)
        self.assertEqual(len(set(identifiers)), 2)
        for entry in entries:
            profile = Path(entry["profile"])
            self.assertEqual((profile / "launcher.log").read_text().splitlines(),
                             [str(profile / "codex"), f"--user-data-dir={profile / 'browser'}"])
            self.assertEqual((profile.stat().st_mode & 0o777), 0o700)
            self.assertEqual(list((profile / "codex").iterdir()), [])
        # Reopening a clone must reuse its profile, not allocate a new one.
        subprocess.run([str(Path(entries[0]["app"]) / "Contents/MacOS/profile-launcher")], check=True)
        self.assertEqual(len(list(cli.records(self.data))), 2)

    def test_wrong_app_rejected_without_creating_profile(self):
        with (self.source / "Contents/Info.plist").open("wb") as stream:
            plistlib.dump({"CFBundleIdentifier": "unrelated.app"}, stream)
        with self.assertRaises(ValueError):
            cli.find_app(str(self.source))
        self.assertFalse(self.data.exists())

    def test_name_exhaustion_adds_suffix(self):
        self.apps.mkdir()
        self.data.mkdir()
        for name in cli.NAMES:
            (self.apps / f"ChatGPT {name}.app").mkdir()
        name, slug = cli.choose_name(self.apps, self.data)
        self.assertTrue(name.endswith(" 2"))
        self.assertTrue(slug.endswith("-2"))

    def test_missing_app_produces_nonzero_exit(self):
        result = subprocess.run([str(ROOT / "bin/multichatgpt"), "clone", "chatgpt", "--app", str(self.root / "missing.app")],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn("not found", result.stderr)

    def test_refresh_keeps_profile_and_updates_local_executable(self):
        self.create()
        entry = list(cli.records(self.data))[0]
        profile = Path(entry["profile"])
        marker = profile / "codex/keep.txt"
        marker.write_text("existing profile data")
        fake = self.source / "Contents/MacOS/fake-chatgpt"
        fake.write_text('#!/bin/sh\nprintf "%s\\n" "$CODEX_HOME" "$@" "refreshed"\n')
        subprocess.run([str(ROOT / "bin/multichatgpt"), "refresh", entry["name"],
                        "--app", str(self.source), "--data-dir", str(self.data)],
                       check=True, capture_output=True, text=True)
        self.assertEqual(marker.read_text(), "existing profile data")
        after = list(cli.records(self.data))[0]
        self.assertEqual(after["profile"], entry["profile"])
        self.assertEqual(after["app"], entry["app"])
        subprocess.run([str(Path(entry["app"]) / "Contents/MacOS/profile-launcher")], check=True)
        self.assertEqual((profile / "launcher.log").read_text().splitlines()[-1], "refreshed")

    def test_refresh_refuses_running_clone(self):
        fake = self.source / "Contents/MacOS/fake-chatgpt"
        fake.write_text('#!/bin/sh\nsleep 15\n')
        self.create()
        entry = list(cli.records(self.data))[0]
        process = subprocess.Popen([str(Path(entry["app"]) / "Contents/MacOS/profile-launcher")],
                                   start_new_session=True)
        try:
            result = subprocess.run([str(ROOT / "bin/multichatgpt"), "refresh", entry["name"],
                                     "--app", str(self.source), "--data-dir", str(self.data)],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertIn("Quit this clone", result.stderr)
        finally:
            os.killpg(process.pid, signal.SIGTERM)
            process.wait(timeout=5)


if __name__ == "__main__":
    unittest.main()
