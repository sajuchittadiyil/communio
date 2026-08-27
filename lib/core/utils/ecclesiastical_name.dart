String composeEcclesiasticalName({required String displayName, String? title}) {
  final name = displayName.trim();
  final prefix = title?.trim();
  if (prefix == null || prefix.isEmpty || name.isEmpty) return name;
  if (_startsWithEquivalentTitle(name, prefix)) return name;
  return '$prefix $name';
}

bool _startsWithEquivalentTitle(String name, String title) {
  final canonicalTitle = _canonicalTitle(title);
  final match = RegExp(
    r'^([A-Za-z]+)\.?\s+',
    caseSensitive: false,
  ).firstMatch(name);
  if (match == null) return false;
  return _canonicalTitle(match.group(1)!) == canonicalTitle;
}

String _canonicalTitle(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
