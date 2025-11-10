/// Extension methods para manipulación de strings
extension StringExtensions on String {
  /// Convierte un string a Title Case (primera letra de cada palabra mayúscula)
  /// Ejemplo: "press de banca" → "Press De Banca"
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map(
          (word) =>
              word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  /// Capitaliza solo la primera letra del string
  /// Ejemplo: "press de banca" → "Press de banca"
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
