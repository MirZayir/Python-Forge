/// Represents an interactive learning mission within Python Forge.
class Mission {
  final String id;
  final String numberLabel;
  final String title;
  final String description;
  final String objective;
  final List<String> validAnswers;

  const Mission({
    required this.id,
    required this.numberLabel,
    required this.title,
    required this.description,
    required this.objective,
    required this.validAnswers,
  });

  /// Validates whether a provided string matches any acceptable answer for this mission.
  bool validateAnswer(String input) {
    final String formattedInput = input.trim();
    return validAnswers.contains(formattedInput);
  }
}
