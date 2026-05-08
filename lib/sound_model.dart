class SoundModel {
  final String id;
  final String name;
  final String? nameHe;
  final String filePath;
  final List<String> tags;
  final bool isBuiltIn;

  SoundModel({
    required this.id,
    required this.name,
    this.nameHe,
    required this.filePath,
    this.tags = const [],
    this.isBuiltIn = false,
  });

  /// השם שיוצג — עברית אם קיים, אחרת אנגלית
  String get displayName => nameHe ?? name;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameHe': nameHe,
    'filePath': filePath,
    'tags': tags,
    'isBuiltIn': isBuiltIn,
  };

  factory SoundModel.fromJson(Map<String, dynamic> json) => SoundModel(
    id: json['id'] as String,
    name: json['name'] as String,
    nameHe: json['nameHe'] as String?,
    filePath: json['filePath'] as String,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    isBuiltIn: json['isBuiltIn'] as bool? ?? false,
  );
}
