/// Simple immutable model describing a self-checkout category card.
class CategoryItem {
  final String title;
  final String description;
  final String imageAsset;
  final String heroTag;

  const CategoryItem({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.heroTag,
  });
}

/// The six categories shown on the welcome screen, in 2x3 grid order.
final List<CategoryItem> kCategories = [
  const CategoryItem(
    title: 'Vegetables & Fruits',
    description: 'Fresh & Healthy Everyday',
    imageAsset: 'assets/veg_fruits.png',
    heroTag: 'category-veg-fruits',
  ),
  const CategoryItem(
    title: 'Grocery',
    description: 'Daily Essentials For Your Home',
    imageAsset: 'assets/grocery.png',
    heroTag: 'category-grocery',
  ),
  const CategoryItem(
    title: 'Beverages',
    description: 'Refreshing Drinks For Everyone',
    imageAsset: 'assets/beverages.png',
    heroTag: 'category-beverages',
  ),
  const CategoryItem(
    title: 'Household',
    description: 'Cleaning & Household Essentials',
    imageAsset: 'assets/household.png',
    heroTag: 'category-household',
  ),
  const CategoryItem(
    title: 'Chilled Foods',
    description: 'Dairy, Yogurt & Ready To Eat',
    imageAsset: 'assets/chilledfood.png',
    heroTag: 'category-chilled',
  ),
  const CategoryItem(
    title: 'Frozen Foods',
    description: 'Frozen Goodness Always Fresh',
    imageAsset: 'assets/frozenfoods.jpeg',
    heroTag: 'category-frozen',
  ),
];
