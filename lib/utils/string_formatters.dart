String formatUserFacingLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final normalized = trimmed.replaceAll('_', ' ');
  final collapsed = normalized.replaceAll(RegExp(r'\s+'), ' ');
  final sanitizedKey = collapsed.replaceAll(' ', '').toLowerCase();

  const specialCases = {
    'noespecificado': 'No especificado',
    'noespecifica': 'No especificado',
  };

  if (specialCases.containsKey(sanitizedKey)) {
    return specialCases[sanitizedKey]!;
  }

  final spaced = collapsed.replaceAllMapped(
    RegExp(r'(?<=[a-z0-9])(?=[A-Z])'),
    (_) => ' ',
  );
  final cleaned = spaced.replaceAll(RegExp(r'\s+'), ' ').trim();

  if (cleaned.isEmpty) {
    return cleaned;
  }

  final lower = cleaned.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}
