class DefaultCategoryEntry {
  final String name;
  final String icon;
  final String type;

  const DefaultCategoryEntry({
    required this.name,
    required this.icon,
    required this.type,
  });
}

class DefaultCategories {
  DefaultCategories._();

  static const List<DefaultCategoryEntry> list = [
    // Expense (10)
    DefaultCategoryEntry(name: 'Makanan & Minuman', icon: 'restaurant', type: 'expense'),
    DefaultCategoryEntry(name: 'Transportasi', icon: 'directions_car', type: 'expense'),
    DefaultCategoryEntry(name: 'Bensin', icon: 'local_gas_station', type: 'expense'),
    DefaultCategoryEntry(name: 'Belanja', icon: 'shopping_bag', type: 'expense'),
    DefaultCategoryEntry(name: 'Tagihan', icon: 'receipt', type: 'expense'),
    DefaultCategoryEntry(name: 'Hiburan', icon: 'movie', type: 'expense'),
    DefaultCategoryEntry(name: 'Kesehatan', icon: 'health_and_safety', type: 'expense'),
    DefaultCategoryEntry(name: 'Pendidikan', icon: 'school', type: 'expense'),
    DefaultCategoryEntry(name: 'Pakaian', icon: 'checkroom', type: 'expense'),
    DefaultCategoryEntry(name: 'Lainnya', icon: 'category', type: 'expense'),
    // Income (5)
    DefaultCategoryEntry(name: 'Gaji', icon: 'work', type: 'income'),
    DefaultCategoryEntry(name: 'Freelance', icon: 'laptop', type: 'income'),
    DefaultCategoryEntry(name: 'Bisnis', icon: 'store', type: 'income'),
    DefaultCategoryEntry(name: 'Investasi', icon: 'trending_up', type: 'income'),
    DefaultCategoryEntry(name: 'Lainnya', icon: 'category', type: 'income'),
  ];
}
