import 'package:flutter/material.dart';

import '../../../../core/engine/python_runner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/forge_scaffold.dart';

/// Quick interactive Python REPL playground.
class QuickConsoleScreen extends StatefulWidget {
  const QuickConsoleScreen({super.key});

  @override
  State<QuickConsoleScreen> createState() => _QuickConsoleScreenState();
}

class _QuickConsoleScreenState extends State<QuickConsoleScreen> {
  late final TextEditingController _codeController;
  final LocalPythonInterpreter _interpreter = LocalPythonInterpreter();

  String _outputText =
      '>>> Python REPL Ready\n>>> Enter code above and tap Exec.';
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
        text:
            '# Interactive Python Playground\nprint("Hello from Quick Console!")');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _runCode() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _outputText = '>>> Executing...';
    });

    final result = await _interpreter.run(_codeController.text);

    if (!mounted) return;

    setState(() {
      _isRunning = false;
      _outputText = result.output.isNotEmpty
          ? result.output
          : '>>> Executed successfully with no stdout.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ForgeScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderBlack, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowBlack,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.borderBlack,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Quick Console',
          style: TextStyle(
            color: AppColors.borderBlack,
            fontSize: 20.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Container(
        color: AppColors.bgCream,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            // Code Editor Box
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderBlack, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowBlack,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.neuYellow,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(13)),
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.borderBlack, width: 2.5)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.code_rounded,
                            color: AppColors.borderBlack, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'PYTHON REPL EDITOR',
                          style: TextStyle(
                            color: AppColors.borderBlack,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _codeController,
                    maxLines: 7,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14.0,
                      color: AppColors.borderBlack,
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(14),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Run Button
            GestureDetector(
              onTap: _isRunning ? null : _runCode,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.neuGreen,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderBlack, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowBlack,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRunning
                            ? Icons.hourglass_top_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.borderBlack,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRunning ? 'Running...' : 'Execute Script',
                        style: const TextStyle(
                          color: AppColors.borderBlack,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Terminal Output Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderBlack, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowBlack,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STDOUT CONSOLE',
                    style: TextStyle(
                      color: AppColors.neuYellow,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _outputText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.0,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
