"""Embedded Python execution service for Python Forge.

Serious Python starts this program with ``PyImport_ImportModule("main")``, so the
module name is ``main`` and never ``__main__``. The server is therefore started
at import time; guarding it behind ``if __name__ == "__main__"`` would silently
do nothing and leave the app without an execution engine.
"""

import io
import json
import sys
import traceback
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOST = "127.0.0.1"
PORT = 8765
MAX_OUTPUT_CHARS = 20000


def _format_error(error):
    return "".join(
        traceback.format_exception_only(type(error), error)
    ).strip()


def execute(code):
    """Runs learner code and captures stdout/stderr with a structured result."""
    buffer = io.StringIO()
    saved_stdout, saved_stderr = sys.stdout, sys.stderr
    sys.stdout = buffer
    sys.stderr = buffer

    has_error = False
    error_type = ""

    try:
        compiled = compile(code, "<mission>", "exec")
        exec(compiled, {"__name__": "__main__"})
    except SystemExit:
        pass
    except BaseException as error:  # noqa: BLE001 - report every failure
        has_error = True
        error_type = type(error).__name__
        buffer.write(_format_error(error))
    finally:
        sys.stdout = saved_stdout
        sys.stderr = saved_stderr

    output = buffer.getvalue()
    truncated = len(output) > MAX_OUTPUT_CHARS
    if truncated:
        output = output[:MAX_OUTPUT_CHARS] + "\n... output truncated ..."

    return {
        "output": output.strip(),
        "has_error": has_error,
        "error_type": error_type,
        "truncated": truncated,
    }


class ExecutionHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send_json(self, status, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self):
        """Reads the request body for both Content-Length and chunked bodies."""
        encoding = (self.headers.get("Transfer-Encoding") or "").lower()
        if "chunked" in encoding:
            chunks = []
            while True:
                line = self.rfile.readline().strip()
                if not line:
                    break
                try:
                    size = int(line.split(b";")[0], 16)
                except ValueError:
                    break
                if size == 0:
                    self.rfile.readline()
                    break
                chunks.append(self.rfile.read(size))
                self.rfile.readline()
            return b"".join(chunks)

        length = int(self.headers.get("Content-Length") or 0)
        return self.rfile.read(length) if length > 0 else b""

    def do_POST(self):
        try:
            raw = self._read_body() or b"{}"
            payload = json.loads(raw.decode("utf-8") or "{}")
            code = payload.get("code", "")
            if not isinstance(code, str):
                code = ""
            self._send_json(200, execute(code))
        except Exception as error:  # noqa: BLE001
            self._send_json(
                200,
                {
                    "output": "Internal execution error: {}".format(error),
                    "has_error": True,
                    "error_type": type(error).__name__,
                    "truncated": False,
                },
            )

    def do_GET(self):
        self._send_json(200, {"output": "", "has_error": False, "ready": True})

    def log_message(self, fmt, *args):
        return


class ExecutionServer(ThreadingHTTPServer):
    allow_reuse_address = True
    daemon_threads = True


def serve():
    ExecutionServer((HOST, PORT), ExecutionHandler).serve_forever()


serve()
