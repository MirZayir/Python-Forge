import json
import os
import subprocess
import sys
import time
import unittest
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parent
MAIN = ROOT / "main.py"
PORT = 18765
URL = "http://127.0.0.1:{}/".format(PORT)
TOKEN = "test-worker-token"


def _clean_environment():
    environment = os.environ.copy()
    environment.pop("PYTHON_FORGE_TEST", None)
    environment["PYTHON_FORGE_PORT"] = str(PORT)
    environment["PYTHON_FORGE_AUTH_TOKEN"] = TOKEN
    return environment


class HttpAuthenticationTests(unittest.TestCase):
    process = None

    @classmethod
    def setUpClass(cls):
        cls.process = subprocess.Popen(
            [sys.executable, str(MAIN)],
            cwd=str(ROOT),
            env=_clean_environment(),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            try:
                request = Request(
                    URL,
                    headers={"X-Python-Forge-Token": TOKEN},
                )
                with urlopen(request, timeout=0.5) as response:
                    if response.status == 200:
                        return
            except (URLError, OSError):
                time.sleep(0.05)
        if cls.process.poll() is None:
            cls.process.terminate()
            try:
                cls.process.wait(timeout=1)
            except subprocess.TimeoutExpired:
                cls.process.kill()
                cls.process.wait(timeout=1)
        raise RuntimeError("HTTP service did not start within 5 seconds.")

    @classmethod
    def tearDownClass(cls):
        if cls.process is None:
            return
        cls.process.terminate()
        try:
            cls.process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            cls.process.kill()
            cls.process.wait(timeout=2)

    def test_valid_token_executes_code(self):
        body = json.dumps({"code": 'print("ok")'}).encode()
        request = Request(
            URL,
            data=body,
            headers={
                "Content-Type": "application/json",
                "X-Python-Forge-Token": TOKEN,
            },
        )
        with urlopen(request, timeout=2) as response:
            payload = json.loads(response.read())
        self.assertEqual(payload["output"], "ok")
        self.assertFalse(payload["has_error"])

    def test_wrong_token_is_rejected(self):
        body = json.dumps({"code": 'print("blocked")'}).encode()
        request = Request(
            URL,
            data=body,
            headers={
                "Content-Type": "application/json",
                "X-Python-Forge-Token": "wrong-token",
            },
        )
        try:
            with urlopen(request, timeout=2):
                self.fail("The HTTP service accepted an invalid token.")
        except HTTPError as error:
            try:
                self.assertEqual(error.code, 403)
            finally:
                error.close()

    def test_missing_token_fails_closed_before_server_start(self):
        environment = _clean_environment()
        environment.pop("PYTHON_FORGE_AUTH_TOKEN")
        result = subprocess.run(
            [sys.executable, str(MAIN)],
            cwd=str(ROOT),
            env=environment,
            capture_output=True,
            text=True,
            timeout=2,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("PYTHON_FORGE_AUTH_TOKEN is required", result.stderr)


if __name__ == "__main__":
    unittest.main()
