import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String title;
  final String description;
  final String imageAsset;
  final int sortOrder;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.imageAsset,
    this.sortOrder = 100,
    this.isActive = true,
  });

  bool get isWebImage =>
      imageAsset.startsWith('http://') || imageAsset.startsWith('https://');

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final titleVal = (data['name'] ?? data['title'] ?? doc.id).toString();
    final imageVal = (data['image'] ?? data['imageUrl'] ?? data['imageAsset'] ?? data['icon'] ?? '').toString();
    final rawActive = data['is_active'] ?? data['isActive'] ?? data['status'];
    final bool active = rawActive is bool
        ? rawActive
        : (rawActive == null ||
            (rawActive.toString().toLowerCase() != 'false' &&
                rawActive.toString().toLowerCase() != 'inactive' &&
                rawActive != 0));

    final rawSort = data['sort_order'] ?? data['sortOrder'] ?? 100;
    int sortVal = 100;
    if (rawSort is num) {
      sortVal = rawSort.toInt();
    } else if (rawSort != null) {
      sortVal = int.tryParse(rawSort.toString()) ?? 100;
    }

    return CategoryModel(
      id: doc.id,
      title: titleVal,
      description: (data['description'] ?? '').toString(),
      imageAsset: imageVal,
      sortOrder: sortVal,
      isActive: active,
    );
  }
}
