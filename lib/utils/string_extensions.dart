extension StringCasingExtension on String {
  String toCapitalized() {
    if (trim().isEmpty) return '';
    final trimmed = trim();
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
