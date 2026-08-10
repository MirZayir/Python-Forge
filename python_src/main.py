"""Embedded Python execution service for Python Forge.

Serious Python starts this program with ``PyImport_ImportModule("main")``, so
this module starts the HTTP server at import time. The service deliberately
serializes learner requests: learner code temporarily owns process-global
stdout/stderr, and concurrent execution would otherwise mix unrelated output.

This is a constrained execution environment, not a security sandbox. The
import allow-list, bounded input/output, and best-effort deadline protect the
app from common accidental failures; production threat models still require a
separate killable process or an external sandbox.
"""

import builtins
import json
import signal
import sys
import time
import traceback
from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, HTTPServer

HOST = "127.0.0.1"
PORT = 8765
MAX_REQUEST_BYTES = 128 * 1024
MAX_OUTPUT_CHARS = 20_000
MAX_EXECUTION_SECONDS = 5.0

# These modules are sufficient for the current curriculum while avoiding
# filesystem, process, network, and native-code access through normal imports.
_ALLOWED_IMPORT_ROOTS = frozenset(
    {
        "collections",
        "datetime",
        "decimal",
        "fractions",
        "functools",
        "itertools",
        "math",
        "random",
        "re",
        "statistics",
        "string",
    }
)
_BLOCKED_BUILTINS = frozenset(
    {
        "breakpoint",
        "compile",
        "eval",
        "exec",
        "help",
        "input",
        "open",
        "__import__",
    }
)


class ExecutionTimeout(TimeoutError):
    """Raised when the platform supports a synchronous execution deadline."""


class RequestTooLarge(ValueError):
    """Raised when a client sends more learner code than the service accepts."""


class _CappedTextWriter:
    """Text stream that bounds memory while preserving print() semantics."""

    encoding = "utf-8"

    def __init__(self, limit):
        self._limit = limit
        self._chunks = []
        self._length = 0
        self.truncated = False

    def write(self, value):
        text = str(value)
        remaining = self._limit - self._length
        if remaining > 0:
            self._chunks.append(text[:remaining])
            self._length += min(len(text), remaining)
        if len(text) > max(remaining, 0):
            self.truncated = True
        return len(text)

    def flush(self):
        return None

    def isatty(self):
        return False

    def getvalue(self):
        return "".join(self._chunks)


def _format_error(error):
    return "".join(traceback.format_exception_only(type(error), error)).strip()


def _safe_import(name, globals=None, locals=None, fromlist=(), level=0):
    if level != 0:
        raise ImportError("Relative imports are not available in missions.")
    root = name.partition(".")[0]
    if root not in _ALLOWED_IMPORT_ROOTS:
        raise ImportError("Import {!r} is not available in missions.".format(name))
    return builtins.__import__(name, globals, locals, fromlist, level)


_SAFE_BUILTINS = {
    name: value
    for name, value in vars(builtins).items()
    if name not in _BLOCKED_BUILTINS
}
_SAFE_BUILTINS["__import__"] = _safe_import


@contextmanager
def _execution_deadline():
    """Apply a deadline using signals when available and tracing otherwise."""
    deadline = time.monotonic() + MAX_EXECUTION_SECONDS

    def _raise_timeout():
        raise ExecutionTimeout(
            "Execution exceeded the {} second limit.".format(
                int(MAX_EXECUTION_SECONDS)
            )
        )

    def _trace_deadline(_frame, _event, _arg):
        if time.monotonic() >= deadline:
            _raise_timeout()
        return _trace_deadline

    # Android builds can lack SIGALRM, and the embedded interpreter may run
    # outside Python's main thread where signal handlers cannot be installed.
    # A line tracer still interrupts pure-Python loops on those platforms.
    can_use_signal = hasattr(signal, "SIGALRM") and hasattr(signal, "setitimer")
    signal_configured = False
    previous_handler = None
    previous_timer = (0, 0)

    if can_use_signal:
        try:
            previous_handler = signal.getsignal(signal.SIGALRM)
            previous_timer = signal.setitimer(signal.ITIMER_REAL, 0)

            def _raise_signal_timeout(_signum, _frame):
                _raise_timeout()

            signal.signal(signal.SIGALRM, _raise_signal_timeout)
            signal.setitimer(signal.ITIMER_REAL, MAX_EXECUTION_SECONDS)
            signal_configured = True
        except (AttributeError, OSError, RuntimeError, ValueError):
            # Fall through to tracing when the platform or interpreter thread
            # rejects signal configuration.
            try:
                signal.setitimer(signal.ITIMER_REAL, 0)
            except (AttributeError, OSError, RuntimeError, ValueError):
                pass
            if previous_handler is not None:
                try:
                    signal.signal(signal.SIGALRM, previous_handler)
                except (AttributeError, OSError, RuntimeError, ValueError):
                    pass

    previous_trace = sys.gettrace()
    # Keep tracing enabled even when signal configuration succeeds: embedded
    # Android interpreters may accept SIGALRM setup without delivering it to
    # the interpreter thread that is executing learner code.
    sys.settrace(_trace_deadline)

    try:
        yield
    finally:
        if signal_configured:
            signal.setitimer(signal.ITIMER_REAL, 0)
            signal.signal(signal.SIGALRM, previous_handler)
            if previous_timer[0] > 0:
                signal.setitimer(signal.ITIMER_REAL, previous_timer[0])
        sys.settrace(previous_trace)


def execute(code):
    """Run learner code and return bounded, structured execution metadata."""
    buffer = _CappedTextWriter(MAX_OUTPUT_CHARS)
    saved_stdout, saved_stderr = sys.stdout, sys.stderr
    sys.stdout = buffer
    sys.stderr = buffer

    has_error = False
    error_type = ""
    try:
        compiled = compile(code, "<mission>", "exec")
        namespace = {
            "__name__": "__main__",
            "__builtins__": _SAFE_BUILTINS,
        }
        with _execution_deadline():
            exec(compiled, namespace, namespace)
    except SystemExit:
        # Treat an explicit exit as a completed program, matching the previous
        # service behavior and preventing it from killing the embedded server.
        pass
    except BaseException as error:  # noqa: BLE001 - report every learner error
        has_error = True
        error_type = type(error).__name__
        buffer.write(_format_error(error))
    finally:
        sys.stdout = saved_stdout
        sys.stderr = saved_stderr

    output = buffer.getvalue()
    if buffer.truncated:
        output += "\n... output truncated ..."

    return {
        "output": output.strip(),
        "has_error": has_error,
        "error_type": error_type,
        "truncated": buffer.truncated,
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
        """Read Content-Length or chunked bodies without unbounded allocation."""
        encoding = (self.headers.get("Transfer-Encoding") or "").lower()
        if "chunked" in encoding:
            chunks = []
            total = 0
            while True:
                line = self.rfile.readline().strip()
                if not line:
                    raise ValueError("Malformed chunked request.")
                try:
                    size = int(line.split(b";", 1)[0], 16)
                except ValueError as error:
                    raise ValueError("Malformed chunk size.") from error
                if size == 0:
                    self.rfile.readline()
                    break
                total += size
                if total > MAX_REQUEST_BYTES:
                    raise RequestTooLarge(
                        "Learner code exceeds the {} byte limit.".format(
                            MAX_REQUEST_BYTES
                        )
                    )
                chunks.append(self.rfile.read(size))
                self.rfile.readline()
            return b"".join(chunks)

        try:
            length = int(self.headers.get("Content-Length") or 0)
        except ValueError as error:
            raise ValueError("Invalid Content-Length.") from error
        if length < 0 or length > MAX_REQUEST_BYTES:
            raise RequestTooLarge(
                "Learner code exceeds the {} byte limit.".format(MAX_REQUEST_BYTES)
            )
        return self.rfile.read(length) if length > 0 else b""

    def do_POST(self):
        try:
            raw = self._read_body() or b"{}"
            payload = json.loads(raw.decode("utf-8") or "{}")
            if not isinstance(payload, dict):
                raise ValueError("Request JSON must be an object.")
            code = payload.get("code", "")
            if not isinstance(code, str):
                raise ValueError("Request field 'code' must be a string.")
            self._send_json(200, execute(code))
        except RequestTooLarge as error:
            self.close_connection = True
            self._send_json(
                413,
                {
                    "output": str(error),
                    "has_error": True,
                    "error_type": type(error).__name__,
                    "truncated": False,
                },
            )
        except (UnicodeDecodeError, ValueError, json.JSONDecodeError) as error:
            self._send_json(
                400,
                {
                    "output": "Invalid execution request: {}".format(error),
                    "has_error": True,
                    "error_type": type(error).__name__,
                    "truncated": False,
                },
            )
        except Exception as error:  # noqa: BLE001 - keep the service alive
            self._send_json(
                500,
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


class ExecutionServer(HTTPServer):
    """Single-request server to isolate process-global output capture."""

    allow_reuse_address = True


def serve():
    ExecutionServer((HOST, PORT), ExecutionHandler).serve_forever()


# Serious Python imports this module instead of running it as __main__.
# Keeping this call at module scope is required for the embedded runtime.
if __name__ == "__main__" or "PYTHON_FORGE_TEST" not in __import__("os").environ:
    serve()
