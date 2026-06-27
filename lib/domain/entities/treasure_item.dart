class TreasureItem {
  final String id;
  final String name;
  final String emoji;
  final List<String> mlKitLabels; // Labels from ML Kit that match this object
  final int starReward;
  bool isFound;

  TreasureItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.mlKitLabels,
    this.starReward = 10,
    this.isFound = false,
  });

  // Factory list of child-friendly target items to find at home
  static List<TreasureItem> get defaultItems => [
        TreasureItem(
          id: 'flower',
          name: 'Flower',
          emoji: '🌸',
          mlKitLabels: ['flower', 'rose', 'plant', 'petal', 'wildflower', 'flora', 'blossom'],
          starReward: 10,
        ),
        TreasureItem(
          id: 'cup',
          name: 'Cup / Mug',
          emoji: '☕',
          mlKitLabels: ['cup', 'mug', 'coffeecup', 'drinkware', 'tableware'],
          starReward: 10,
        ),
        TreasureItem(
          id: 'book',
          name: 'Book',
          emoji: '📖',
          mlKitLabels: ['book', 'publication', 'paperback', 'novel', 'textbook'],
          starReward: 10,
        ),
        TreasureItem(
          id: 'keyboard',
          name: 'Keyboard / Computer',
          emoji: '💻',
          mlKitLabels: ['keyboard', 'computer', 'laptop', 'monitor', 'screen', 'electronics'],
          starReward: 10,
        ),
      ];
}
