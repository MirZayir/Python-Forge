import os
import unittest

os.environ["PYTHON_FORGE_TEST"] = "1"

from main import MAX_OUTPUT_CHARS, execute


class ExecutionServiceTests(unittest.TestCase):
    def test_successful_output_is_structured(self):
        result = execute('print("ok")')
        self.assertEqual(result["output"], "ok")
        self.assertFalse(result["has_error"])
        self.assertEqual(result["error_type"], "")
        self.assertFalse(result["truncated"])

    def test_runtime_errors_are_reported_without_escaping(self):
        result = execute("raise ValueError('bad input')")
        self.assertTrue(result["has_error"])
        self.assertEqual(result["error_type"], "ValueError")
        self.assertIn("bad input", result["output"])

    def test_dangerous_imports_are_rejected(self):
        result = execute("import os")
        self.assertTrue(result["has_error"])
        self.assertEqual(result["error_type"], "ImportError")

    def test_output_is_bounded(self):
        result = execute('print("x" * 25000)')
        self.assertTrue(result["truncated"])
        self.assertLessEqual(
            len(result["output"]), MAX_OUTPUT_CHARS + len("\n... output truncated ...")
        )

    def test_pure_python_timeout_is_structured(self):
        result = execute("while True: pass")
        self.assertTrue(result["has_error"])
        self.assertEqual(result["error_type"], "ExecutionTimeout")
        self.assertIn("second limit", result["output"])


if __name__ == "__main__":
    unittest.main()
