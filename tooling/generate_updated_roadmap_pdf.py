"""Generate the evidence-based Python Forge roadmap update as a PDF.

This generator intentionally uses only the Python standard library so the
roadmap artifact can be regenerated in CI without adding a PDF dependency.
"""

from __future__ import annotations

import textwrap
from pathlib import Path
from typing import Iterable

PAGE_WIDTH = 595.28
PAGE_HEIGHT = 841.89
LEFT = 48.0
RIGHT = 48.0
TOP = 58.0
BOTTOM = 48.0
CONTENT_WIDTH = PAGE_WIDTH - LEFT - RIGHT
OUTPUT_NAME = "Python_Forge_Comprehensive_Review_and_Roadmap_Updated.pdf"

STATUS_COLORS = {
    "IMPLEMENTED": (0.08, 0.42, 0.24),
    "PARTIAL": (0.70, 0.38, 0.04),
    "PLANNED": (0.08, 0.30, 0.62),
    "BLOCKED": (0.68, 0.10, 0.10),
    "EVIDENCE GAP": (0.35, 0.22, 0.52),
}


def pdf_escape(value: str) -> str:
    """Escape an ASCII string for a PDF literal string."""
    value = value.encode("ascii", "replace").decode("ascii")
    return value.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def wrap_lines(text: str, size: float, indent: int = 0) -> list[str]:
    """Wrap text using a conservative Helvetica width estimate."""
    available = max(24, int((CONTENT_WIDTH - indent) / (size * 0.52)))
    result: list[str] = []
    for paragraph in text.split("\n"):
        if not paragraph.strip():
            result.append("")
            continue
        result.extend(
            textwrap.wrap(
                paragraph,
                width=available,
                break_long_words=False,
                break_on_hyphens=False,
            )
            or [""]
        )
    return result


class Document:
    def __init__(self) -> None:
        self.pages: list[list[str]] = []
        self.commands: list[str] = []
        self.page_number = 0
        self.y = PAGE_HEIGHT - TOP
        self.new_page()

    def new_page(self) -> None:
        if self.commands:
            self.finish_page()
        self.page_number += 1
        self.commands = []
        self.y = PAGE_HEIGHT - TOP

    def finish_page(self) -> None:
        self.commands.append(
            f"0.75 0.75 0.75 RG 0.5 w {LEFT:.2f} 38 m {PAGE_WIDTH - RIGHT:.2f} 38 l S"
        )
        self.draw_text(
            "PYTHON FORGE | UPDATED REVIEW AND ROADMAP v1.1",
            LEFT,
            PAGE_HEIGHT - 30,
            7.0,
            "F2",
            (0.25, 0.25, 0.25),
        )
        self.draw_text(
            f"Evidence-based update | Original PDF preserved | Page {self.page_number}",
            LEFT,
            25,
            7.0,
            "F1",
            (0.35, 0.35, 0.35),
        )
        self.pages.append(self.commands)

    def ensure(self, height: float) -> None:
        if self.y - height < BOTTOM:
            self.new_page()

    def draw_text(
        self,
        text: str,
        x: float,
        y: float,
        size: float,
        font: str = "F1",
        color: tuple[float, float, float] = (0.08, 0.08, 0.08),
    ) -> None:
        r, g, b = color
        self.commands.append(
            f"BT /{font} {size:.2f} Tf {r:.3f} {g:.3f} {b:.3f} rg "
            f"{x:.2f} {y:.2f} Td ({pdf_escape(text)}) Tj ET"
        )

    def add_line(
        self,
        text: str,
        size: float = 9.4,
        font: str = "F1",
        color: tuple[float, float, float] = (0.08, 0.08, 0.08),
        indent: float = 0,
        leading: float | None = None,
    ) -> None:
        leading = leading or size * 1.35
        self.ensure(leading)
        self.draw_text(text, LEFT + indent, self.y, size, font, color)
        self.y -= leading

    def add_paragraph(
        self,
        text: str,
        size: float = 9.4,
        font: str = "F1",
        color: tuple[float, float, float] = (0.08, 0.08, 0.08),
        indent: float = 0,
        after: float = 5,
    ) -> None:
        lines = wrap_lines(text, size, int(indent))
        leading = size * 1.38
        self.ensure(len(lines) * leading + after)
        for line in lines:
            self.add_line(line, size, font, color, indent, leading)
        self.y -= after

    def add_title(self, title: str, subtitle: str | None = None) -> None:
        self.ensure(90)
        self.add_line(title, 25, "F2", (0.04, 0.04, 0.04), leading=32)
        if subtitle:
            self.add_line(subtitle, 12, "F1", (0.20, 0.20, 0.20), leading=18)
        self.y -= 8

    def add_heading(self, title: str, level: int = 1) -> None:
        if level == 1:
            size, leading, color, before = 15, 21, (0.04, 0.18, 0.35), 10
        elif level == 2:
            size, leading, color, before = 11.5, 16, (0.08, 0.30, 0.48), 7
        else:
            size, leading, color, before = 10, 14, (0.12, 0.12, 0.12), 5
        self.y -= before
        self.ensure(leading + 5)
        self.add_line(title, size, "F2", color, leading=leading)
        self.commands.append(
            f"0.82 0.84 0.88 RG 0.6 w {LEFT:.2f} {self.y + 4:.2f} "
            f"m {PAGE_WIDTH - RIGHT:.2f} {self.y + 4:.2f} l S"
        )
        self.y -= 5

    def add_bullet(self, text: str, after: float = 3) -> None:
        size = 9.2
        lines = wrap_lines(text, size, 16)
        leading = 12.6
        self.ensure(len(lines) * leading + after)
        for index, line in enumerate(lines):
            prefix = "- " if index == 0 else "  "
            self.add_line(prefix + line, size, "F1", indent=8, leading=leading)
        self.y -= after

    def add_numbered(self, number: int, title: str, body: str) -> None:
        size = 9.2
        first = f"{number}. {title}: {body}"
        lines = wrap_lines(first, size, 16)
        leading = 12.6
        self.ensure(len(lines) * leading + 3)
        for index, line in enumerate(lines):
            prefix = "" if index == 0 else "   "
            self.add_line(prefix + line, size, "F1", indent=8, leading=leading)
        self.y -= 3

    def add_status(self, status: str, title: str, body: str) -> None:
        color = STATUS_COLORS[status]
        self.y -= 2
        self.add_line(f"[{status}] {title}", 10.0, "F2", color, leading=13.5)
        self.add_paragraph(body, 8.9, "F1", (0.12, 0.12, 0.12), indent=13, after=4)

    def add_code(self, command: str) -> None:
        size = 8.1
        lines = wrap_lines(command, size, 14)
        leading = 10.8
        self.ensure(len(lines) * leading + 3)
        for line in lines:
            self.add_line(line, size, "F3", (0.12, 0.12, 0.12), indent=10, leading=leading)
        self.y -= 3

    def add_callout(self, label: str, text: str, color: tuple[float, float, float]) -> None:
        lines = wrap_lines(text, 9.1, 18)
        height = (len(lines) + 1) * 12.5 + 14
        self.ensure(height)
        top = self.y + 3
        bottom = self.y - height + 5
        r, g, b = color
        self.commands.append(
            f"{r:.3f} {g:.3f} {b:.3f} rg {LEFT:.2f} {bottom:.2f} "
            f"{CONTENT_WIDTH:.2f} {height - 6:.2f} re f"
        )
        self.add_line(label, 9.5, "F2", (0.05, 0.05, 0.05), indent=10, leading=13)
        self.add_paragraph(text, 9.1, "F1", (0.10, 0.10, 0.10), indent=10, after=2)
        self.y = min(self.y, bottom - 4)

    def page_break(self) -> None:
        self.new_page()

    def finish(self) -> None:
        if self.commands:
            self.finish_page()


def add_document_content(doc: Document) -> None:
    doc.add_title(
        "PYTHON FORGE",
        "Updated Comprehensive Review and Roadmap - Revision 1.1",
    )
    doc.add_paragraph(
        "Generated: 10 August 2026 | Scope: current workspace evidence and the next development backlog",
        9.5,
        "F2",
        (0.12, 0.30, 0.45),
    )
    doc.add_paragraph(
        "This document updates Python_Forge_Comprehensive_Review_and_Roadmap.pdf. It marks work that is implemented and validated, separates partial or blocked work from future work, and records the development phases recommended from this point forward.",
        10.2,
        after=8,
    )
    doc.add_callout(
        "SOURCE LIMITATION",
        "The original PDF is preserved unchanged at the repository root. Its readable metadata identifies the title Python Forge - Comprehensive Review & Bounded Roadmap and a 9 August 2026 creation date, but its body is stored in compressed streams that were not reliably extractable. This revision therefore uses repository source, tests, build output, and device evidence rather than claiming a line-by-line reproduction of unreadable original sections.",
        (0.91, 0.94, 0.98),
    )
    doc.add_heading("1. Executive status", 1)
    doc.add_paragraph(
        "The main application-quality recommendations have been implemented and validated locally. Android now runs the embedded interpreter in a killable application-owned worker process, but the runtime remains constrained execution rather than a complete security sandbox because resource isolation and non-Android worker backends are still incomplete. Public release is also blocked until a production-signed artifact is built and verified.",
        10,
    )
    doc.add_status(
        "IMPLEMENTED",
        "Core product hardening",
        "Runtime request limits, best-effort execution deadlines, Android process-worker supervision, authenticated loopback transport, deterministic archive and manifest verification, curriculum contracts, guarded navigation, progression reconciliation, achievement persistence, semantic controls, and responsive layout protections are present in the workspace.",
    )
    doc.add_status(
        "PARTIAL",
        "Release and evidence gates",
        "The expanded CI workflow now covers Python compilation/tests, Dart formatting/analyze/tests, web and debug APK builds, and uploaded artifact checksums. Hosted CI provenance, integration/device artifacts, signing verification, and full roadmap traceability remain incomplete.",
    )
    doc.add_status(
        "PARTIAL",
        "Android process worker",
        "Android now launches Serious Python in an application-owned :python_worker process and requests termination of that process after a request failure or timeout, reporting whether the stop was confirmed. Desktop, iOS, and web still use or require constrained fallbacks, and OS-level resource limits plus full cross-platform coverage remain incomplete.",
    )
    doc.add_status(
        "BLOCKED",
        "Production signing and distribution",
        "Production signing secrets and a keystore are not available, so a signed release AAB, certificate verification, and Play internal-track evidence cannot yet be produced.",
    )
    doc.add_heading("Status legend", 2)
    doc.add_paragraph(
        "[IMPLEMENTED] Completed in source and supported by validation evidence. [PARTIAL] Some implementation exists, but an acceptance gate or evidence is still missing. [PLANNED] New work proposed in this revision. [BLOCKED] Cannot be completed with the current architecture or unavailable credentials. [EVIDENCE GAP] Work may exist, but provenance or verification is not recorded.",
        9.2,
    )

    doc.page_break()
    doc.add_heading("2. Implemented changes to date", 1)
    doc.add_paragraph(
        "The following items are marked implemented because they are visible in the current codebase and were covered by the latest local validation pass.",
        9.5,
    )
    doc.add_heading("2.1 Runtime and execution constraints", 2)
    doc.add_status(
        "IMPLEMENTED",
        "Constrained execution policy",
        "python_src/main.py applies a 5-second best-effort deadline using tracing on all platforms and signals where available. It caps requests at 128 KiB, caps output at 20,000 characters, serializes HTTP execution, requires a per-launch authentication token outside explicit tests, blocks common unsafe imports/builtins, and keeps SystemExit from terminating the service.",
    )
    doc.add_status(
        "IMPLEMENTED",
        "Dart bridge timeout and recovery",
        "lib/core/engine/python_runner.dart performs readiness polling, verifies the packaged runtime hash, sends authenticated bounded JSON requests, and applies an 8-second request guard. On Android a timeout requests termination of the separate worker process and reports whether it was confirmed; local device validation covered successful output and a successful execution after worker startup.",
    )
    doc.add_status(
        "PARTIAL",
        "Security isolation",
        "Android now has a real process kill boundary, but the complete product remains constrained execution rather than a security sandbox: native resource limits, filesystem/network isolation, and desktop and iOS worker backends remain incomplete. Web builds explicitly report execution as unsupported until a Web Worker/WASM backend exists.",
    )
    doc.add_heading("2.2 Runtime archive and build packaging", 2)
    doc.add_status(
        "IMPLEMENTED",
        "Reproducible runtime archive and manifest",
        "tooling/package_python_runtime.py verifies that app/app.zip contains the expected main.py payload, matches python_src/main.py byte-for-byte, and matches the generated app/runtime_manifest.json. The latest verified source SHA-256 is c8e20dc3682da9b4ca2899f87b77dc4028fb1728fafdcac894893f631671f7b8 and archive SHA-256 is b7152dddf56c4944e180f83c83b5aff753fc167d9258917a419d47dd8da47fa5; the app verifies the archive hash before startup.",
    )
    doc.add_status(
        "IMPLEMENTED",
        "Native-symbol release packaging",
        "useLegacyPackaging remains enabled for the embedded Python payload, and keepDebugSymbols excludes the ZIP-formatted libpythonbundle.so from ELF stripping while preserving Flutter debug-symbol metadata for real native objects.",
    )
    doc.add_heading("2.3 Curriculum, progression, and navigation", 2)
    doc.add_status(
        "IMPLEMENTED",
        "Curriculum contracts",
        "CurriculumRepository validates stable curriculum metadata, unique positive module order, required module and mission fields, exact-match validation, answer contracts, MCQ options, prerequisite references, and acyclic prerequisite graphs before caching the asset.",
    )
    doc.add_status(
        "IMPLEMENTED",
        "Progress reconciliation",
        "LearningProgressService and ProgressManager sanitize stale completion IDs, migrate safe legacy keys, derive unlocks, XP, level, completion percentage, resume position, and module progress from one active curriculum.",
    )
    doc.add_status(
        "IMPLEMENTED",
        "Achievements and safe mission entry",
        "Achievement definitions are catalog-backed and reconciled on dashboard load. MissionEntryScreen resolves route data against the active curriculum and permits only known unlocked or completed missions; invalid and locked entries never open an editor.",
    )
    doc.add_heading("2.4 Accessibility and responsive interface", 2)
    doc.add_status(
        "IMPLEMENTED",
        "Semantic controls",
        "Custom settings, reset, Quick Console, streak, profile, and execution controls expose labels, hints, and button semantics instead of relying only on visual GestureDetector or InkWell presentation.",
    )
    doc.add_status(
        "IMPLEMENTED",
        "Narrow screens and large text",
        "The dashboard uses compact FORGE branding below 420 px, ellipsis for the app-bar title, a wrapping overall-progress header, and widget coverage for a 360x800 surface and 2.0 text scaling.",
    )
    doc.add_heading("2.5 Local quality gates", 2)
    doc.add_status(
        "IMPLEMENTED",
        "Automated test coverage",
        "The current suite covers answer validation, curriculum contracts including prerequisite cycles and canonical IDs, progress/unlock derivation, route protection, mission rendering, settings, streaks, achievements, cold start, responsive layout, and text scaling. Direct Python tests cover runtime output, errors, blocked imports, output truncation, pure-Python timeout handling, valid authentication, rejected tokens, and fail-closed startup.",
    )

    doc.page_break()
    doc.add_heading("3. Validation evidence snapshot", 1)
    doc.add_paragraph(
        "The following results are the latest recorded local validation evidence for the current workspace. They are not a substitute for a hosted CI run or a signed distribution test.",
        9.5,
    )
    evidence = [
        ("Dart analyzer", "flutter analyze --no-pub", "PASS - no issues found"),
        ("Flutter tests", "flutter test --no-pub", "PASS - 33 tests"),
        ("Python tests", "python -m unittest discover -s python_src -p test_*.py", "PASS - 8 tests"),
        ("Runtime archive and manifest", "python tooling/package_python_runtime.py --check", "PASS - source and archive hashes match"),
        ("Whitespace", "git diff --check", "PASS"),
        ("Debug APK", "flutter build apk --debug --no-pub", "PASS"),
        ("Web build", "flutter build web --no-pub", "PASS compile-only; execution explicitly unsupported until a web backend exists"),
        ("Android worker startup", "Local adb install/relaunch/Quick Console execution on serial 98e86dfe", "PASS manual smoke; separate com.example.python_forge:python_worker process observed and code executed; timeout/restart recovery remains unautomated"),
        ("Release signing guard", "verifyPythonForgeReleaseSigning", "PASS when evaluated; unsigned release builds fail closed without configured secrets"),
        ("Crash check", "Local app-scoped logcat for com.example.python_forge", "No FATAL EXCEPTION or AndroidRuntime crash during the worker smoke test"),
    ]
    for name, command, result in evidence:
        doc.add_status("IMPLEMENTED", name, f"Command: {command}. Result: {result}.")
    doc.add_callout(
        "RELEASE CAVEAT",
        "A production AAB is intentionally not generated without signing properties and a keystore: the Gradle release guard fails closed instead of permitting an unsigned artifact. The debug APK and Android worker smoke test pass locally. Serious Python's libpythonbundle.so is a ZIP payload with a .so filename; keepDebugSymbols excludes it from ELF stripping while legacy packaging preserves runtime loading.",
        (0.98, 0.94, 0.86),
    )

    doc.page_break()
    doc.add_heading("4. Remaining gaps and new work", 1)
    doc.add_paragraph(
        "These items should be treated as the active backlog. They are intentionally not marked complete by the current evidence.",
        9.5,
    )
    doc.add_status(
        "PARTIAL",
        "Killable execution worker",
        "Android now has a real application-owned worker process, authenticated loopback IPC, timeout-driven stop with native confirmation when available, and next-run process-state reconciliation. It still needs adversarial native-blocking/restart tests, OS-level CPU/memory/filesystem/network controls, and equivalent desktop and iOS backends before the product can claim a secure sandbox; web execution is explicitly unsupported.",
    )
    doc.add_status(
        "PARTIAL",
        "Real integration and device qualification",
        "Add integration_test coverage for asset loading, first execution, success/error/timeout UI, persistence after relaunch, locked routes, keyboard behavior, and next-mission navigation. Run it across target Android API levels, ARM64, emulator, low-memory, offline, and process-restart scenarios.",
    )
    doc.add_status(
        "BLOCKED",
        "Production signing and distribution",
        "Provide the four PYTHON_FORGE_UPLOAD_* secrets through a private Gradle or CI secret store, fail closed when absent, verify the signing certificate and AAB hash, and use a Play internal-testing track before public release.",
    )
    doc.add_status(
        "PARTIAL",
        "CI quality and artifact provenance",
        "The checked-in workflow now runs archive/manifest verification, Python compilation/tests, pinned Flutter/Python setup, Dart formatting/analyze/tests, web and debug APK builds, and uploads checksums plus validation artifacts. It still needs hosted evidence, integration/device tests, and a signed-release job.",
    )
    doc.add_status(
        "PARTIAL",
        "Curriculum graph correctness",
        "Prerequisite cycle detection and contract coverage are implemented. A machine-readable curriculum manifest with stable version/content hash, migration policy, and complete all-mission contract evidence remain planned; MCQ and fill-in missions must remain non-executing and failed execution must never award completion.",
    )
    doc.add_status(
        "PARTIAL",
        "Documentation and version alignment",
        "Align README, pubspec, Android versionName, and release naming. Add dedicated tests for claims such as quote normalization and document the distinction between constrained execution and a secure sandbox.",
    )
    doc.add_status(
        "EVIDENCE GAP",
        "Roadmap traceability",
        "Recover or text-extract the original PDF source if possible, preserve its SHA-256, and add an evidence index mapping each roadmap requirement to source symbols, tests, CI jobs, artifacts, and build identity.",
    )

    doc.page_break()
    doc.add_heading("5. Development phases", 1)
    doc.add_paragraph(
        "The phases below are intentionally short summaries. Each phase has a practical outcome and an exit condition so roadmap status can be updated from evidence instead of intention.",
        9.5,
    )
    phases = [
        ("Phase 0 - Evidence baseline and traceability", "PARTIAL", "Recover the original roadmap text or record its extraction limitation, preserve source and artifact hashes, add docs/review-source.md and an evidence-index file, and embed revision/source identity in future PDF generation. Exit when every roadmap item has a status and an evidence reference."),
        ("Phase 1 - Execution hardening", "PARTIAL", "Android now has an application-owned killable worker, authenticated IPC, archive verification, timeout cleanup, and worker startup recovery. Add adversarial native-blocking/restart tests, OS resource controls, and platform-specific desktop, iOS, and web backends. Exit when each supported platform proves that a stuck program cannot hold the host app."),
        ("Phase 2 - Curriculum and validation correctness", "PARTIAL", "Prerequisite DAG cycle detection and contract tests are implemented. Add curriculum manifest/version/hash/migration rules, all-mission contract evidence, and explicit starter-code and quote-normalization behavior. Exit when content changes fail fast with actionable validation errors."),
        ("Phase 3 - Integration and device qualification", "PARTIAL", "Add integration tests for the real Flutter-to-runtime path, persistence, navigation, timeout recovery, keyboard, accessibility, and relaunch. Run on the target device/API/ABI matrix and publish logs and screenshots. Exit when the matrix is repeatable and artifact-linked."),
        ("Phase 4 - Release and signing", "PARTIAL", "Configure secret-backed signing, fail closed without secrets, build and verify a signed AAB, retain mapping files and checksums, and complete Play internal testing. Exit when certificate identity and artifact provenance are recorded."),
        ("Phase 5 - CI and evidence automation", "PARTIAL", "Pin Flutter/Python/action versions, run Python plus Dart plus integration suites, build artifacts, upload reports/checksums, and fail on stale runtime archives or missing roadmap metadata. Exit when a pull request receives the same gates as a local release candidate."),
        ("Phase 6 - Content and platform expansion", "PLANNED", "Only after safety and release gates: expand curriculum, add analytics or sync where explicitly required, and broaden platform support. Exit criteria should be defined per feature rather than allowing new content to bypass the contract validator."),
    ]
    for title, status, body in phases:
        doc.add_status(status, title, body)

    doc.add_heading("6. Prioritized next implementation order", 1)
    doc.add_numbered(1, "Release configuration", "provide private signing secrets, verify a signed AAB, and run internal-track testing")
    doc.add_numbered(2, "Sandbox architecture spike", "choose the separate process or external sandbox boundary before adding more arbitrary-code features")
    doc.add_numbered(3, "Integration/device matrix", "automate real runtime startup, timeout recovery, persistence, accessibility, and relaunch checks")
    doc.add_numbered(4, "Curriculum graph and manifest", "add cycle detection, content hashes, migration policy, and all-mission contract validation")
    doc.add_numbered(5, "CI/evidence automation", "upload results, checksums, symbol maps, device artifacts, and roadmap traceability metadata")
    doc.add_numbered(6, "Content expansion", "proceed only after the safety and release gates are green")

    doc.page_break()
    doc.add_heading("7. File-level evidence map", 1)
    doc.add_paragraph(
        "These are the principal files that support the status decisions in this revision. The complete worktree also contains the related tests, CI workflow, runtime archive, and UI changes.",
        9.5,
    )
    file_map = [
        ("python_src/main.py", "Constrained service policy, authenticated HTTP contract, output cap, import/builtin controls, deadline, and explicit non-sandbox limitation."),
        ("lib/core/engine/python_runner.dart", "Dart asset-hash verification, worker lifecycle supervision on Android, authenticated JSON bridge, readiness polling, and timeout recovery."),
        ("lib/core/engine/python_worker_controller.dart", "Narrow platform channel for starting and stopping the Android worker process."),
        ("lib/main.dart", "Android worker entrypoint and bootstrap channel; web execution returns an explicit unsupported result."),
        ("android/app/src/main/kotlin/com/example/python_forge/PythonWorkerService.kt", "Application-owned :python_worker process containing the secondary Flutter engine and Serious Python entrypoint."),
        ("android/app/src/main/AndroidManifest.xml", "Non-exported worker service declaration with a separate Android process."),
        ("tooling/package_python_runtime.py", "Deterministic app.zip creation plus source/archive hash manifest generation and freshness checks."),
        ("lib/features/curriculum/data/repositories/curriculum_repository.dart", "Curriculum parsing and validation contract."),
        ("lib/core/progression/learning_progress.dart", "Derived unlocks, prerequisites, XP, level, resume, and stale-ID sanitization."),
        ("lib/core/progression/progress_manager.dart", "Idempotent completion, safe legacy migration, and progress-only reset."),
        ("lib/features/curriculum/presentation/screens/mission_screen.dart", "Mission validation, execution, completion, streak, achievements, and next mission."),
        ("lib/features/curriculum/presentation/screens/home_screen.dart", "Dashboard startup reconciliation, responsive title/progress layout, and semantic controls."),
        (".github/workflows/flutter.yml", "Pinned Flutter/Python quality workflow with archive, Python, Dart, web, APK, checksum, and artifact gates."),
        ("android/app/build.gradle.kts", "Native packaging, ZIP-named .so strip exclusion, and fail-closed production signing configuration."),
        ("test/ and python_src/test_main.py", "Curriculum, answer, progress, navigation, UI, settings, and direct runtime tests."),
    ]
    for path, purpose in file_map:
        doc.add_status("IMPLEMENTED", path, purpose)

    doc.add_heading("8. Risks, assumptions, and decisions", 1)
    doc.add_bullet("Android now has a killable worker process, but the runtime remains bounded constrained execution rather than a secure sandbox until OS resource controls and all target-platform backends are verified.")
    doc.add_bullet("A release AAB build passing is not equivalent to a distributable release; signing and certificate verification are still required.")
    doc.add_bullet("One Android device smoke pass is useful evidence but is not a device compatibility matrix.")
    doc.add_bullet("The original PDF remains unchanged. This updated PDF is a new artifact and does not assert that unreadable original body text was reproduced exactly.")
    doc.add_bullet("No commit or push is implied by this document. The repository owner should approve the release and sandbox decisions before creating a checkpoint commit.")

    doc.add_heading("9. Revision change log", 1)
    doc.add_bullet("Added explicit status labels for implemented, partial, planned, blocked, and evidence-gap work.")
    doc.add_bullet("Recorded the Android process worker, authenticated loopback protocol, runtime hash manifest, fail-closed release signing guard, prerequisite cycle detection, expanded CI workflow, and new validation evidence.")
    doc.add_bullet("Added the current validation command/result snapshot and release-symbol packaging explanation.")
    doc.add_bullet("Added remaining blockers and new work for sandbox isolation, integration/device qualification, signing, CI, curriculum DAG checks, version alignment, and evidence traceability.")
    doc.add_bullet("Added brief Phases 0 through 6 and a prioritized next implementation order.")
    doc.add_bullet("Preserved Python_Forge_Comprehensive_Review_and_Roadmap.pdf without overwriting it.")

    doc.add_callout(
        "CURRENT DECISION",
        "Python Forge is ready for continued internal development and controlled Android testing with the process worker. It is not yet ready to claim secure arbitrary-code execution or public production distribution: resource isolation, non-Android worker backends, hosted evidence, and signed-release verification remain open.",
        (0.90, 0.95, 0.91),
    )


def build_pdf(output_path: Path) -> None:
    document = Document()
    add_document_content(document)
    document.finish()

    objects: list[bytes] = []

    def add_object(value: bytes) -> int:
        objects.append(value)
        return len(objects)

    catalog_id = add_object(b"<< /Type /Catalog /Pages 2 0 R >>")
    pages_id = add_object(b"<< /Type /Pages /Kids [] /Count 0 >>")
    font_regular = add_object(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")
    font_bold = add_object(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>")
    font_mono = add_object(b"<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>")

    page_ids: list[int] = []
    for commands in document.pages:
        stream = "\n".join(commands).encode("latin-1", "replace")
        content_id = add_object(
            b"<< /Length " + str(len(stream)).encode("ascii") + b" >>\nstream\n" + stream + b"\nendstream"
        )
        page_id = add_object(
            (
                "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %.2f %.2f] "
                "/Resources << /Font << /F1 %d 0 R /F2 %d 0 R /F3 %d 0 R >> >> "
                "/Contents %d 0 R >>"
                % (PAGE_WIDTH, PAGE_HEIGHT, font_regular, font_bold, font_mono, content_id)
            ).encode("ascii")
        )
        page_ids.append(page_id)

    kids = " ".join(f"{page_id} 0 R" for page_id in page_ids)
    objects[pages_id - 1] = (
        f"<< /Type /Pages /Kids [{kids}] /Count {len(page_ids)} >>".encode("ascii")
    )
    info_id = add_object(
        b"<< /Title (Python Forge - Updated Comprehensive Review and Roadmap) "
        b"/Author (Python Forge project) "
        b"/Subject (Evidence-based implementation status and development phases) "
        b"/Creator (generate_updated_roadmap_pdf.py) "
        b"/CreationDate (D:20260810000000+00'00') >>"
    )

    output = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = [0]
    for index, value in enumerate(objects, start=1):
        offsets.append(len(output))
        output.extend(f"{index} 0 obj\n".encode("ascii"))
        output.extend(value)
        output.extend(b"\nendobj\n")

    xref_offset = len(output)
    output.extend(f"xref\n0 {len(objects) + 1}\n".encode("ascii"))
    output.extend(b"0000000000 65535 f\n")
    for offset in offsets[1:]:
        output.extend(f"{offset:010d} 00000 n\n".encode("ascii"))
    output.extend(
        (
            f"trailer\n<< /Size {len(objects) + 1} /Root {catalog_id} 0 R /Info {info_id} 0 R >>\n"
            f"startxref\n{xref_offset}\n%%EOF\n"
        ).encode("ascii")
    )

    output_path.write_bytes(output)
    print(f"Generated {output_path} ({len(document.pages)} pages, {len(output)} bytes)")


if __name__ == "__main__":
    build_pdf(Path(__file__).resolve().parents[1] / OUTPUT_NAME)
