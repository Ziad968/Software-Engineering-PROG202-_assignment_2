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

  /// Creates a [Module] instance from a Supabase `modules` table row.
  factory Module.fromMap(Map<String, dynamic> map) {
    return Module(
      code: (map['module_code'] ?? '').toString().trim().toUpperCase(),
      name: (map['module_name'] ?? '').toString().trim(),
      credits: (map['credits'] as num?)?.toInt() ?? 3,
    );
  }

  /// Converts this [Module] into a map compatible with Supabase `modules` table.
  Map<String, dynamic> toMap() {
    return {
      'module_code': code.trim().toUpperCase(),
      'module_name': name.trim(),
      'credits': credits,
    };
  }
}