import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple immutable model describing a self-checkout category card.
class CategoryItem {
  final String id;
  final String title;
  final String description;
  final String imageAsset;
  final String heroTag;
  final bool isActive;
  final int sortOrder;

  const CategoryItem({
    this.id = '',
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.heroTag,
    this.isActive = true,
    this.sortOrder = 100,
  });

  bool get isWebImage =>
      imageAsset.startsWith('http://') || imageAsset.startsWith('https://');

  bool get isAssetImage => imageAsset.isNotEmpty && !isWebImage;

  factory CategoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final title = data['name'] ?? data['title'] ?? doc.id;
    final image = data['image'] ?? data['imageUrl'] ?? data['imageAsset'] ?? data['icon'] ?? '';
    final rawActive = data['is_active'] ?? data['isActive'] ?? data['status'];
    final bool active = rawActive is bool
        ? rawActive
        : (rawActive == null ||
            (rawActive.toString().toLowerCase() != 'false' &&
                rawActive.toString().toLowerCase() != 'inactive' &&
                rawActive != 0));

    final rawSort = data['sort_order'] ?? data['sortOrder'] ?? 100;
    int sortVal = 100;
    if (rawSort is int) {
      sortVal = rawSort;
    } else if (rawSort is double) {
      sortVal = rawSort.toInt();
    } else if (rawSort != null) {
      sortVal = int.tryParse(rawSort.toString()) ?? 100;
    }

    return CategoryItem(
      id: doc.id,
      title: title.toString(),
      description: (data['description'] ?? '').toString(),
      imageAsset: image.toString(),
      heroTag: 'category-${doc.id}',
      isActive: active,
      sortOrder: sortVal,
    );
  }
}

/// The six fallback categories shown on the welcome screen if database is empty or offline.
final List<CategoryItem> kCategories = [
  const CategoryItem(
    id: 'cat_veg_fruits',
    title: 'Vegetables & Fruits',
    description: 'Fresh & Healthy Everyday',
    imageAsset: 'assets/veg_fruits.png',
    heroTag: 'category-veg-fruits',
    sortOrder: 1,
  ),
  const CategoryItem(
    id: 'cat_grocery',
    title: 'Grocery',
    description: 'Daily Essentials For Your Home',
    imageAsset: 'assets/grocery.png',
    heroTag: 'category-grocery',
    sortOrder: 2,
  ),
  const CategoryItem(
    id: 'cat_beverages',
    title: 'Beverages',
    description: 'Refreshing Drinks For Everyone',
    imageAsset: 'assets/beverages.png',
    heroTag: 'category-beverages',
    sortOrder: 3,
  ),
  const CategoryItem(
    id: 'cat_household',
    title: 'Household',
    description: 'Cleaning & Household Essentials',
    imageAsset: 'assets/household.png',
    heroTag: 'category-household',
    sortOrder: 4,
  ),
  const CategoryItem(
    id: 'cat_chilled',
    title: 'Chilled Foods',
    description: 'Dairy, Yogurt & Ready To Eat',
    imageAsset: 'assets/chilledfood.png',
    heroTag: 'category-chilled',
    sortOrder: 5,
  ),
  const CategoryItem(
    id: 'cat_frozen',
    title: 'Frozen Foods',
    description: 'Frozen Goodness Always Fresh',
    imageAsset: 'assets/frozenfoods.jpeg',
    heroTag: 'category-frozen',
    sortOrder: 6,
  ),
];

