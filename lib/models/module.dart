/// Represents an academic course module.
class Module {
  final String code;
  final String name;
  final int credits;

  const Module({
    required this.code,
    required this.name,
    this.credits = 3,
  });
}