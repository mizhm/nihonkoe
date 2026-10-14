enum CardLayout {
  grid(2, 2),
  compact(3, 0),
  list(1, 3);

  const CardLayout(this.columns, this.tags);
  final int columns;
  final int tags; // tag chips shown per card

  CardLayout get next => values[(index + 1) % values.length];
}

CardLayout toCardLayout(String? name) => CardLayout.values.asNameMap()[name] ?? CardLayout.grid;
