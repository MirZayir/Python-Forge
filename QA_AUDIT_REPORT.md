# Python Forge — QA Audit Report

**Date:** 15 August 2026
**Tester role:** Senior QA / exploratory test engineer
**App under test:** Python Forge (Flutter mobile app, embedded Python execution engine)
**Test device:** realme GT 6T (RMX3853), Android, connected via wireless ADB debugging
**Build tested:** Local debug APK built from current workspace source (`flutter build apk --debug`)
**Rules followed:** No application source code was modified during testing. No bug was "fixed" while testing it. All findings below were reproduced and evidence-checked before being reported.

---

## Executive Summary

**Overall Quality: 7.5/10**

Python Forge is a well-architected, carefully hardened application. Its Python execution sandbox, curriculum content-integrity system, persistence/migration logic, and automated test suite are all built to a noticeably higher standard than most hobby or early-stage learning apps. All 33 Flutter tests and 8 Python tests pass, and 28/28 adversarial sandbox-security probes (blocked imports, blocked builtins, timeouts, malformed requests, auth bypass attempts) passed cleanly against the real execution service.

However, exploratory testing found **one confirmed CRITICAL defect in the core grading logic**: MCQ and fill-in-blank answer checking is case-insensitive, which allows objectively incorrect Python answers (e.g., `true`, `TRUE`) to be accepted as correct for a quiz whose entire pedagogical point is that Python's boolean literal is case-sensitive (`True` only). This was reproduced live on-device: selecting the wrong option and submitting displayed "🎉 Mission Complete!", awarded XP, advanced the streak, and permanently persisted the incorrect completion. For a Python-learning app, this is a direct failure of the product's core promise — accurate feedback on Python knowledge — and it silently miseducates rather than merely malfunctioning.

Apart from this defect, the app is close to release-ready for internal/non-Play-Store use. No crashes, freezes, data loss, or security bypasses were found anywhere else in this session.

---

## Critical Findings

1. **BUG-1 (CRITICAL, Confirmed):** Case-insensitive MCQ/fill-in-blank grading accepts wrong answers as correct, defeating case-sensitivity-focused quiz questions and permanently corrupting progress/XP/streak/achievement state.
2. **BUG-2 (MEDIUM, Confirmed):** No memory-allocation limit in the Python execution sandbox; only request size, output size, and a 5-second CPU deadline are enforced.
3. **BUG-3 (LOW, Confirmed):** `ValidationStatus.methodWarning` is declared but never produced by any validator — dead code with no observable user impact today, but a latent trap for future maintenance.
4. **BUG-4 (LOW, Confirmed):** README advertises `v0.5.0` while `pubspec.yaml` declares `1.0.0+1` — version identity is inconsistent across the repository.

---

## Bug Summary

| ID | Severity | Area | Title | Status |
|----|----------|------|-------|--------|
| BUG-1 | CRITICAL | Quiz grading (AnswerValidator) | Case-insensitive matching lets wrong MCQ/fill-in answers pass as correct | Confirmed |
| BUG-2 | MEDIUM | Python execution sandbox | No memory/allocation limit; only time and I/O size are bounded | Confirmed |
| BUG-3 | LOW | Code quality (AnswerValidator) | `ValidationStatus.methodWarning` is unreachable dead code | Confirmed |
| BUG-4 | LOW | Documentation | README version (v0.5.0) does not match pubspec version (1.0.0+1) | Confirmed |
| BUG-5 | LOW | Curriculum design (not a code bug) | No mission declares `expectedOutput`, so only exact source-structure matters, not runtime output equivalence | Confirmed (design characteristic) |

---

## Detailed Bug Reports

### BUG-1

**Title:** Case-insensitive answer matching allows objectively incorrect MCQ/fill-in-blank answers to be graded as correct

**Severity:** CRITICAL

**Confidence:** Confirmed (reproduced live on-device and in source/tests)

**Area:** Quiz grading — `lib/core/engine/answer_validator.dart`, mission `m2_1` ("Booleans Quiz")

**Preconditions:** Any mission of type `mcq` or `fill_in_blank` whose valid answer has a lowercase/uppercase variant that is also Python-meaningful but incorrect.

**Steps to reproduce:**
1. Open mission `m2_1`, "Booleans Quiz" — objective: "Which keyword represents a true boolean state in Python?"
2. Options presented: `true`, `True`, `TRUE`, `boolean`. The only Python-valid boolean literal is `True`.
3. Select the lowercase option `true` (an invalid Python identifier — using it in real code raises `NameError`).
4. Tap "Submit Answer".

**Expected result:** The app should reject `true` as incorrect, since Python's boolean literal is case-sensitive and this quiz exists specifically to test that knowledge.

**Actual result:** The app displayed the completion dialog "🎉 Mission Complete! Great job completing this challenge. +50 XP", advanced the learner's streak to 1 day, added `m2_1` to `completed_missions`, and unlocked the next mission. This was verified directly against the device's persisted SharedPreferences (`completed_missions` went from `[...m1_5]` to `[...m1_5, m2_1]` after submission).

**Root cause:** `AnswerValidator._normalizeAnswer` performs `value.trim().toLowerCase()` for both the submission and every `validAnswer` before comparing MCQ/fill-in-blank answers (`answer_validator.dart`). `True`, `TRUE`, and `true` all normalize to the same string `"true"`, so all three options for `m2_1` are treated as correct — only the fourth option, `boolean`, would actually be rejected. This is not a device-specific fluke: the project's own test suite documents and asserts this exact behavior (`test/answer_validator_test.dart`, "MCQ and fill-in missions validate their own answer contracts" asserts `fullCode: 'true'` against `validAnswers: ['True']` returns `ValidationStatus.correct`).

A second, narrower instance of the same defect exists in mission `m7_4` ("KeyError Fill-In"): typing `keyerror` (invalid Python — exception names are case-sensitive) would also be accepted, because the same lowercase normalization is applied.

**Frequency:** Always (100% reproducible; not timing- or state-dependent).

**Impact:** This corrupts the app's fundamental value proposition for a Python-learning product. A learner can pass a quiz specifically designed to teach that Python is case-sensitive while never learning that fact, and receive positive reinforcement (XP, streak, "Mission Complete") for doing so. The incorrect completion is written to persistent storage and there is no in-app path to detect or selectively undo it — the only recovery is `Settings → Reset All Progress`, which erases everything, not just the affected mission.

**Evidence:** Reproduced end-to-end on-device (screenshot + UI-hierarchy dump showing the "true" option selected, followed by the "🎉 Mission Complete! +50 XP" dialog; SharedPreferences dump before/after showing `m2_1` added to `completed_missions`). Root cause independently confirmed by reading `answer_validator.dart` and by the project's own existing unit test in `test/answer_validator_test.dart`.

**Suggested fix / root cause analysis:** MCQ and fill-in-blank validation should not apply blanket case-folding when the underlying content is Python syntax where case is semantically significant (keywords, boolean literals, exception/class names). Options:
- Preserve case-sensitive comparison for MCQ/fill-in-blank by default, and only case-fold for missions explicitly marked as case-insensitive (e.g., free-text conceptual answers where wording varies).
- At minimum, remove the case-insensitive comparison for `m2_1`'s answer set, or add a curriculum-level flag (`caseSensitive: true`) consumed by `_normalizeAnswer`/`_validateChoice`/`_validateFillInBlank`.
- Update `test/answer_validator_test.dart`'s assertion, since it currently encodes the buggy behavior as expected behavior.

---

### BUG-2

**Title:** No memory-allocation limit in the Python execution sandbox

**Severity:** MEDIUM

**Confidence:** Confirmed

**Area:** Python execution sandbox — `python_src/main.py`

**Preconditions:** None; any code submission.

**Steps to reproduce:**
1. Submit `x = [0] * (10**9)` (a 1-billion-element list, allocating several GB) to the execution service directly over its authenticated HTTP endpoint.
2. Observe the response and the service's subsequent availability.

**Expected result:** The service should reject or bound excessive memory allocation, since uncontrolled allocation can degrade or crash the hosting process.

**Actual result:** The allocation succeeded without error (`has_error: false`, output `1000000000`), and a follow-up request confirmed the service remained alive and responsive afterward. No `MemoryError` or resource guard was triggered in this test environment.

**Frequency:** Always, up to the point where the host process would actually run out of memory (not reached in this test).

**Impact:** `python_src/main.py`'s own docstring already states this is "constrained execution... not a security sandbox" and the project roadmap documents "native resource limits... remain incomplete" as a known gap — this finding is consistent with, not contradictory to, that documented status. On Android, allocation-driven failure is contained by the separate `:python_worker` OS process (an OOM there is recoverable via the existing worker-restart path). On non-Android fallback platforms, where Serious Python runs in the same process as the host Flutter app, a large-enough allocation could destabilize the entire app rather than just the sandboxed code.

**Evidence:** Direct HTTP probe against a live `python_src/main.py` subprocess; response captured and logged. Confirmed the service was still responsive to a subsequent well-formed request.

**Suggested fix / root cause analysis:** This requires the OS-level resource controls already tracked as a known gap in the project roadmap (`tooling/generate_updated_roadmap_pdf.py`, Phase 1). No new gap is being introduced by this report; it is independent confirmation of an already-documented limitation.

---

### BUG-3

**Title:** `ValidationStatus.methodWarning` is unreachable dead code

**Severity:** LOW

**Confidence:** Confirmed

**Area:** Code quality — `lib/core/engine/answer_validator.dart`, `lib/features/curriculum/presentation/screens/mission_screen.dart`

**Steps to reproduce:** Search all validator branches (`_validateCode`, `_validateChoice`, `_validateFillInBlank`) for any path returning `ValidationStatus.methodWarning`.

**Expected result:** If the enum value exists and `mission_screen.dart` has dedicated haptic handling for it (`medium impact`), some validation path should be able to produce it.

**Actual result:** No validator method ever returns `ValidationStatus.methodWarning`; only `correct` and `incorrect` are produced. The `mission_screen.dart` branch handling `methodWarning` haptics is therefore unreachable.

**Frequency:** Always (structural, not state-dependent).

**Impact:** None currently observable to users. This is a latent code-quality issue that could confuse future maintainers into believing a third feedback tier exists and is exercised.

**Evidence:** Static review of `answer_validator.dart`'s three private validators and their call sites.

**Suggested fix:** Either remove the unused enum value and its associated dead branch, or implement an actual use case for it (e.g., partially-correct code structure) if one was originally intended.

---

### BUG-4

**Title:** README version does not match pubspec version

**Severity:** LOW

**Confidence:** Confirmed

**Area:** Documentation

**Steps to reproduce:** Compare `README.md`'s version badge/heading with `pubspec.yaml`'s `version:` field.

**Expected result:** Both should agree on the current app version.

**Actual result:** `README.md` states `v0.5.0` (badge and "What's New in v0.5.0" section) while `pubspec.yaml` declares `version: 1.0.0+1`.

**Frequency:** Always (static content).

**Impact:** Cosmetic/documentation-only; does not affect app behavior. Could confuse contributors or users comparing release notes to the shipped build. This mismatch is already tracked in the project's own roadmap doc under "Documentation and version alignment."

**Evidence:** Direct file comparison.

**Suggested fix:** Align README version badges/text with `pubspec.yaml`, or adopt a single source of truth referenced by both.

---

### BUG-5 (design characteristic, not a defect)

**Title:** No mission declares `expectedOutput`; grading is purely structural, not output-based

**Severity:** LOW (educational/UX friction, not a functional bug)

**Confidence:** Confirmed

**Area:** Curriculum design — `assets/curriculum/missions.json`, `lib/core/engine/answer_validator.dart`

**Details:** A grep across all 40 missions found zero uses of the `expectedOutput` field, even though `AnswerValidator._validateCode` supports comparing actual runtime output against a declared expected output. As shipped, every code mission is graded purely by normalized source-code structure. This means a learner who writes a functionally correct but differently-structured solution (e.g., `from math import sqrt; print(sqrt(16))` instead of the expected `import math; print(math.sqrt(16))` for `m8_1`) will be marked incorrect even though their code runs and produces the right answer.

**Impact:** This is an intentional design choice (the project's roadmap explicitly states the curriculum declares "exact source contracts"), but it is real friction for any learner who already knows valid alternative Python syntax. Flagging for product awareness, not as a code defect.

---

## Functional Findings

- **Install/upgrade path:** `adb install -r` over an existing installation correctly preserved all existing data — completed missions, streak dates, and unlocked achievements were verified byte-for-byte identical in SharedPreferences before and after reinstalling the freshly built debug APK. No data loss on upgrade.
- **Cold start / dashboard:** Rendered correctly with real curriculum data: streak, "5/40 • Lvl 3 • 250 XP earned" progress summary, module completion state ("DONE" badge on a fully completed module), and a working "Resume Learning" card pointing at the correct next mission.
- **Navigation:** Dashboard → mission → completion dialog → next mission via `pushReplacement` all worked without dead ends, duplicate screens, or navigation stalls. Backing out of a mission screen via the custom back button returned cleanly to the dashboard.
- **Interruption recovery:** Sending the app to the background (`KEYCODE_HOME`) mid-mission (with unsaved code in the editor) and relaunching via `am start` brought the app back to the same mission screen without a crash. This is Android task-resumption behavior (the activity was not destroyed), not proof of full state-restoration after process death — that scenario (`am kill` / low-memory eviction) was not tested in this session and should be called out as an area requiring further testing.
- **Empty-input handling:** Submitting a code mission with no code entered produced a graceful "No code provided to execute." + "❌ Execution failed" result — no crash, no hang, no ambiguous state.
- **Achievements/Profile consistency:** The Profile screen ("LEVEL 4, 300 XP", "1 Days Daily Streak", "6 Missions Done", "15% Complete — Control Flow & Decisions") and the Achievements screen ("TROPHY COLLECTION, 2 of 5 Unlocked" with Spark Ignited + Explorer shown as unlocked) agreed with each other and with the underlying persisted completion count at every point checked. No stale-UI or double-counting was observed. (Note: the "300 XP"/"Level 4" state reflects the corrupted completion from BUG-1; the *consistency* of the derived-state pipeline itself is sound — it faithfully reflects whatever is in `completed_missions`, correct or not.)
- **Code editor:** Syntax highlighting is correct (keywords, string literals, numeric literals rendered in distinct colors) and a formatting toolbar (`TAB`, `:`, `=`, `()`, `""`, `''`, `[]`, `{}`) is available. **No auto-indentation** was observed after typing a line ending in `:` (e.g., after `if score > 50:` and pressing Enter, the next line started at column 0 rather than being auto-indented 4 spaces). This is worth a product decision — many code-focused editors do auto-indent after a colon, and its absence adds friction for typing multi-line answers that require exact indentation to match the curriculum's structural-match grading. Not filed as a numbered bug because it is a UX enhancement question, not a defect against a stated requirement, but it compounds the impact of the exact-source-match grading design (BUG-5).

## Educational Accuracy Findings

- Independently reasoned through all 40 missions' `validAnswers` across all 8 modules: every declared answer is syntactically valid Python 3 and produces the outcome described in its objective/hint text. No incorrect Python claims were found in any mission description, objective, or hint.
- Reviewed all 8 MCQ missions and 6 fill-in-blank missions for correctness of the *intended* answer and plausibility of distractors: every intended correct answer is technically accurate, and every distractor is genuinely wrong (either invalid Python syntax or a factually incorrect claim). No MCQ has zero or multiple technically-correct options *by design* — the only issue is the *implementation* of the grading (BUG-1) accidentally treating additional options as correct at runtime.
- `m2_1` in particular is a well-designed question in *content* (it correctly tests that only `True` is a valid boolean literal, with `true`, `TRUE`, and `boolean` as deliberate, well-chosen wrong answers) — the defect is purely in the grading engine failing to respect that design, not in the curriculum content itself.

## UI/UX Findings

- Neubrutalist visual style (bold borders, drop shadows, high-contrast cream/yellow/green palette) is applied consistently across dashboard, mission, profile, and achievements screens.
- All interactive elements checked exposed proper `content-desc`/semantic labels in the UI hierarchy (e.g., "Answer option True, Double tap to select", "Submit answer, Submit Answer", "Resume learning, Booleans Quiz"), which is a good sign for screen-reader compatibility, though a live screen-reader pass was not performed in this session.
- No overlapping, cut-off, or misaligned elements were observed on any screen tested at the device's native resolution (1080×2376).
- The existing automated suite (`test/widget_test.dart`) already covers a 360×800 narrow viewport and 2.0x text scaling and passes, which is stronger small-screen/accessibility-scaling coverage than most apps at this stage ship with.

## Performance Findings

- No slow transitions, frozen UI, or excessive load times were observed during this session's navigation, submission, and screen-switching sequences.
- App recovered instantly from being backgrounded and re-foregrounded.
- Full Flutter test suite (33 tests) completes in ~8–10 seconds locally; Python test suite (8 tests) completes in ~6 seconds. Both are fast enough for routine local iteration and CI.
- Repeated open/close cycling (20–30x) of the same screen, as suggested by standard QA protocol for detecting memory-leak-driven degradation, was **not performed** in this session due to time constraints of manual ADB-driven interaction; flagging as an area requiring further testing (see Test Coverage).

## Accessibility Findings

- Semantic labels are present and descriptive on buttons, MCQ options, and progress indicators (confirmed via UI-hierarchy dumps, not a live screen-reader pass).
- Text scaling to 2.0x is covered by an existing, passing automated test (`widget_test.dart`).
- Color is not used as the sole signal for correctness feedback — messages use ✅/❌ emoji plus text, not color alone.
- **Not independently verified in this session:** actual TalkBack/screen-reader narration quality, minimum touch-target sizing across all buttons, and focus-order correctness for keyboard/switch-access navigation. These require dedicated assistive-technology testing tooling beyond what was available here.

## Security Findings

All findings below were produced by 28 targeted adversarial requests sent directly to a live `python_src/main.py` subprocess (the same code path the shipped app uses), plus review of the Android process-isolation architecture.

- **Import allow-list enforced correctly:** `os`, `socket`, `subprocess`, `sys`, and the `__import__` builtin were all rejected with `ImportError`, both for direct imports and dunder-style bypass attempts.
- **Dangerous builtins removed, not just restricted:** `open`, `eval`, `exec`, `input`, `breakpoint`, `compile`, and `help` are stripped from the execution namespace entirely (`NameError` on use), which is a stronger guarantee than merely blocking their arguments.
- **Execution timeout enforced reliably:** an infinite loop (`while True: pass`) was terminated at almost exactly 5 seconds via `ExecutionTimeout`, matching the documented deadline.
- **Output bounded:** a 1,000,000-character `print()` was truncated to the documented 20,000-character cap with `truncated: true` set.
- **Request size bounded:** a >128 KB request body was rejected with HTTP 413.
- **Authentication enforced:** requests with a missing or incorrect `X-Python-Forge-Token` header were rejected with HTTP 403; a GET request without the header was also rejected. The service refuses to even start without an auth token configured outside test mode (confirmed by the project's own `test_http_auth.py`, independently re-run in this session).
- **No information leakage on malformed input:** malformed JSON, non-object JSON, and wrong-typed fields all returned structured 400 responses with a safe error description — no raw Python tracebacks or internal paths were exposed.
- **State isolation between executions confirmed:** a variable defined in one request did not leak into a subsequent request (each execution uses a fresh namespace).
- **Android process isolation:** the architecture correctly isolates code execution in a separate `:python_worker` OS process (confirmed via `AndroidManifest.xml` and `PythonWorkerService.kt`), which is killed via `Process.killProcess` on timeout or error — a genuine OS-level kill boundary, not merely cooperative cancellation.
- **Gap (already documented by the project, independently confirmed here):** no memory-allocation limit (BUG-2), and non-Android platforms lack the same process-level kill boundary — both are pre-existing, disclosed limitations, not newly discovered security holes.
- **No authentication/account system exists** in the app (confirmed absent by design — this is a fully local, single-user app with no login, and therefore no session-hijacking, credential-stuffing, or account-takeover surface to test).

## Test Coverage

**Automated suites executed (all passing):**
- Flutter: 33/33 tests across 9 files — `answer_validator_test.dart` (3), `curriculum_contract_test.dart` (6), `learning_progress_test.dart` (6), `mission_entry_screen_test.dart` (1), `mission_screen_test.dart` (3), `progress_manager_test.dart` (3), `settings_service_test.dart` (2), `streak_and_achievements_test.dart` (5), `widget_test.dart` (4).
- Python: 8/8 tests — `test_main.py` (5), `test_http_auth.py` (3), run via `python -m unittest discover` (the `pytest` package was not installed on this machine; `unittest` executed the same test files successfully, so this is a local environment note, not a project defect).

**Manual/exploratory coverage this session:**
- Screens tested: Dashboard/Home, Mission (MCQ type, Code type), Profile, Achievements. **4 of ~7** distinct screens (Settings modal and Quick Console screen were inspected in source but not exercised live on-device this session; Fill-in-blank mission type was not exercised live, only via source/test review).
- Mission types exercised live on-device: MCQ (`m2_1`, including the confirmed defect), Code (`m2_2`, partially — empty-submission path confirmed, full valid-answer submission not completed due to ADB text-input tooling limitations, see below).
- Quiz scenarios executed: 1 live on-device (the case-sensitivity defect reproduction on `m2_1`) + 33 automated. Full manual pass across all 8 MCQ + 6 fill-in-blank missions was done via independent Python/logic review, not live device interaction for every single one.
- Python execution scenarios executed: 28 direct adversarial HTTP probes (sandbox security) + 8 automated + 1 live on-device (empty code).
- Persistence checks: install-over-existing (data preserved, confirmed), background/foreground interruption (recovered, confirmed), post-completion state correctness across Dashboard/Profile/Achievements (confirmed consistent, including the corrupted-but-consistent state from BUG-1).

**Areas not testable / requiring further work in this session:**
- Full-app-kill (process death, not just backgrounding) persistence recovery — not exercised.
- Live screen-reader (TalkBack) narration — not exercised; only static semantic-label evidence was gathered.
- Repeated 20–30x screen open/close performance-degradation probe — not exercised due to session time constraints.
- Complete live on-device pass through all 40 missions — impractical for a single manual session; representative sampling plus full static/logical review was used instead, and is the reason the case-sensitivity defect surfaced from a *targeted* pick (a boolean-literal quiz) rather than a fixed script that would not have caught it.
- Fill-in-blank mission type was not driven live via the on-screen keyboard (ADB shell text-input tooling had escaping issues with special characters in this environment); its correctness was instead verified through source code review and the existing automated widget test (`mission_screen_test.dart`), plus confirmed applicability of the same case-insensitivity defect to `m7_4` via source analysis.
- Network-loss / mid-request interruption scenarios were not separately exercised, since the app has no network dependency for its core learning flow (Python execution is a local loopback HTTP call, not internet-dependent) — this significantly reduces the relevance of that specific test vector for this app.
- No user accounts/authentication exist, so account-related test vectors (signup, login, session expiry, multi-account) are not applicable to this app and were correctly scoped out rather than skipped.

## Release Recommendation

**RELEASE BLOCKED**

**Reasoning:** Every other system checked in this audit — the execution sandbox, persistence and migration logic, curriculum integrity verification, navigation, and interruption recovery — is solid, well-tested, and free of crashes or data loss. But BUG-1 is not a peripheral issue: it is a confirmed, 100%-reproducible defect in the exact mechanism a Python-learning app depends on to be trustworthy — telling a learner whether their answer was actually correct. It currently allows a case-sensitivity quiz to accept the wrong answer as right, silently teaches the wrong lesson, and permanently writes a false "completed" record into the learner's progress with no in-app way to correct just that one mission.

Shipping this to real students risks actively miseducating them on a foundational Python concept (case-sensitive keywords) while telling them they got it right — which is a worse outcome for a learning product than a visible crash would be, because it is invisible to both the student and the app itself.

**Before release, at minimum:** fix the case-insensitive MCQ/fill-in-blank comparison in `AnswerValidator` (BUG-1) and re-verify `m2_1` and `m7_4` reject their invalid-case options. BUG-2 through BUG-5 do not need to block release; they are appropriately low/medium severity and, in several cases, already-disclosed limitations.

---

> **Would you trust Python Forge to be released to real students in its current state?**
>
> **NO.**
>
> The reasoning is narrow and specific, not a wholesale rejection of the app: the architecture, sandboxing, persistence, and test discipline are genuinely strong, and 33/33 + 8/8 automated tests plus 28/28 adversarial security probes passed without issue. But BUG-1 directly undermines the one thing a grading system in a learning app cannot get wrong — telling a student whether they answered correctly. It is confirmed, reproducible on the very first quiz designed to test it, and it corrupts persisted learner progress with no self-service recovery path short of a full data wipe. Once that specific defect is fixed and re-verified, the rest of this audit found nothing else severe enough to block release on its own.
