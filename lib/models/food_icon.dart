class FoodIconOption {
  final String key;
  final String emoji;
  final String semanticLabel;

  const FoodIconOption(this.key, this.emoji, this.semanticLabel);
}

class FoodIconCatalog {
  const FoodIconCatalog._();

  static const String fallbackKey = 'other';

  static const List<FoodIconOption> options = [
    FoodIconOption('vegetables', '🥦', 'Gemüse'),
    FoodIconOption('fruit', '🍎', 'Obst'),
    FoodIconOption('potato', '🥔', 'Kartoffeln'),
    FoodIconOption('meat', '🥩', 'Fleisch'),
    FoodIconOption('sausage', '🌭', 'Wurst'),
    FoodIconOption('fish', '🐟', 'Fisch'),
    FoodIconOption('dairy', '🥛', 'Milchprodukte'),
    FoodIconOption('cheese', '🧀', 'Käse'),
    FoodIconOption('eggs', '🥚', 'Eier'),
    FoodIconOption('bakery', '🥖', 'Brot und Backwaren'),
    FoodIconOption('grains', '🍚', 'Nudeln und Reis'),
    FoodIconOption('preserves', '🥫', 'Konserven und Gläser'),
    FoodIconOption('frozen', '❄️', 'Tiefkühl'),
    FoodIconOption('spices', '🌿', 'Gewürze'),
    FoodIconOption('sauces', '🫙', 'Saucen'),
    FoodIconOption('oils', '🫒', 'Öle und Fette'),
    FoodIconOption('breakfast', '🥣', 'Frühstück'),
    FoodIconOption('baking', '🧁', 'Backen'),
    FoodIconOption('drinks', '🥤', 'Getränke'),
    FoodIconOption('sweets', '🍬', 'Snacks und Süßigkeiten'),
    FoodIconOption(fallbackKey, '🛒', 'Sonstiges'),
  ];

  static bool isValid(String? key) =>
      options.any((option) => option.key == key);

  static String normalizeKey(String? key) => isValid(key) ? key! : fallbackKey;

  static FoodIconOption optionFor(String? key) {
    final normalized = normalizeKey(key);
    return options.firstWhere((option) => option.key == normalized);
  }

  static String emojiFor(String? key) => optionFor(key).emoji;

  static String defaultForFoodId(String id) {
    final match = RegExp(r'^f_(\d+)').firstMatch(id);
    final number = match == null ? null : int.tryParse(match.group(1)!);
    if (number == null) return fallbackKey;
    if (number <= 42) return 'vegetables';
    if (number <= 65) return 'fruit';
    if (number <= 70) return 'potato';
    if (number <= 83) return 'meat';
    if (number <= 93) return 'sausage';
    if (number <= 101) return 'fish';
    if (number <= 115) return 'dairy';
    if (number <= 127) return 'cheese';
    if (number == 128) return 'eggs';
    if (number <= 140) return 'bakery';
    if (number <= 153) return 'grains';
    if (number <= 162) return 'preserves';
    if (number <= 171) return 'frozen';
    if (number <= 189) return 'spices';
    if (number <= 200) return 'sauces';
    if (number <= 205) return 'oils';
    if (number <= 212) return 'breakfast';
    if (number <= 222) return 'baking';
    if (number <= 231) return 'drinks';
    if (number <= 238) return 'sweets';
    return fallbackKey;
  }
}
