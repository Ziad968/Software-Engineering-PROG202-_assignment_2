import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../utils/grade_calculator.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/grade_chip.dart';

/// Screen 11: Standalone instant mark-to-grade converter.
class GradeCalculatorScreen extends StatefulWidget {
  const GradeCalculatorScreen({super.key});

  @override
  State<GradeCalculatorScreen> createState() => _GradeCalculatorScreenState();
}

class _GradeCalculatorScreenState extends State<GradeCalculatorScreen> {
  final _controller = TextEditingController();
  double? _validMark;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMarkChanged(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      setState(() {
        _validMark = null;
        _errorText = null;
      });
      return;
    }

    final parsed = double.tryParse(text);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      setState(() {
        _validMark = null;
        _errorText = 'Enter a valid numeric mark';
      });
      return;
    }

    if (parsed < 0 || parsed > 100) {
      setState(() {
        _validMark = null;
        _errorText = 'Mark must be between 0 and 100';
      });
      return;
    }

    setState(() {
      _validMark = parsed;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grade = _validMark != null
        ? GradeCalculator.calculateGrade(_validMark!)
        : null;
    final remark = _validMark != null
        ? GradeCalculator.calculateRemark(_validMark!)
        : null;

    return Scaffold(
      appBar: buildAppBar(title: 'Grade Calculator'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Numeric Mark',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Type any score from 0 to 100 to calculate its Limkokwing letter grade and remark.',
                    style: TextStyle(fontSize: 13, color: AppColors.slate),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: _onMarkChanged,
                    decoration: InputDecoration(
                      labelText: 'Mark (0 - 100)',
                      hintText: 'e.g. 82',
                      prefixIcon: const Icon(Icons.calculate_outlined),
                      errorText: _errorText,
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _controller.clear();
                                _onMarkChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (grade != null && remark != null) ...[
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Calculated Result',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GradeChip(grade: grade, isLarge: true),
                    const SizedBox(height: 12),
                    Text(
                      remark,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: ${_validMark!.toStringAsFixed(1)} / 100 • ${GradeCalculator.isPass(_validMark!) ? "PASS" : "FAIL"}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GradeCalculator.isPass(_validMark!)
                            ? AppColors.gradeGreen
                            : AppColors.gradeRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}