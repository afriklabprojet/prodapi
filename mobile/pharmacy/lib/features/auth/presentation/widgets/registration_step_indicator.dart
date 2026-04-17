import 'package:flutter/material.dart';

/// A step indicator widget for multi-step forms.
/// Shows progress through numbered steps with connecting lines.
class RegistrationStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final bool isDark;

  const RegistrationStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    this.isDark = false,
  }) : assert(stepLabels.length == totalSteps);

  @override
  Widget build(BuildContext context) {
    final activeColor = Colors.teal;
    final inactiveColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final inactiveText = isDark ? Colors.grey.shade500 : Colors.grey.shade500;

    return Row(
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          final isCompleted = currentStep > stepIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              color: isCompleted ? activeColor : inactiveColor,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isActive = currentStep == stepIndex;
        final isCompleted = currentStep > stepIndex;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive || isCompleted ? activeColor : inactiveColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : inactiveText,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stepLabels[stepIndex],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? activeColor
                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
              ),
            ),
          ],
        );
      }),
    );
  }
}
