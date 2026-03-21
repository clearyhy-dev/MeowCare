class BreedModel {
  final String breedId;
  final String name;
  final Map<String, String> localeNames;
  final bool enabled;
  final int order;

  const BreedModel({
    required this.breedId,
    required this.name,
    this.localeNames = const {},
    this.enabled = true,
    this.order = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'localeNames': localeNames,
      'enabled': enabled,
      'order': order,
    };
  }

  static BreedModel fromMap(Map<String, dynamic> map, String breedId) {
    final ln = map['localeNames'];
    Map<String, String> localeNames = {};
    if (ln is Map) {
      for (final e in ln.entries) {
        if (e.value != null) localeNames[e.key.toString()] = e.value.toString();
      }
    }
    return BreedModel(
      breedId: breedId,
      name: map['name'] as String? ?? '',
      localeNames: localeNames,
      enabled: map['enabled'] as bool? ?? true,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  String displayName(String locale) {
    if (localeNames.containsKey(locale)) return localeNames[locale]!;
    return name;
  }
}
