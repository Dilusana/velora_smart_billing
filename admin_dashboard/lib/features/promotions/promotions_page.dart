import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import '../../core/services/cloudinary_service.dart';
import '../categories/category_provider.dart';
import '../products/product_providers.dart';
import 'promotion_providers.dart';

class PromotionsPage extends ConsumerStatefulWidget {
  const PromotionsPage({super.key});

  @override
  ConsumerState<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends ConsumerState<PromotionsPage> {
  final Set<String> _selectedIds = {};
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');
  final NumberFormat _currFmt = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2, locale: 'en_IN');

  String _searchQuery = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<PromotionModel> _fallbackPromotions = [
    PromotionModel(
      id: 'mock-1',
      name: 'Summer Sale',
      type: 'Discount %',
      value: 15.0,
      scope: 'All Products',
      startDate: DateTime(2023, 6, 1),
      endDate: DateTime(2023, 6, 30),
      status: 'active',
      usageCount: 450,
      couponCode: 'SUMMER15',
    ),
    PromotionModel(
      id: 'mock-2',
      name: 'Welcome Bonus',
      type: 'Flat Off',
      value: 100.0,
      scope: 'Specific Category',
      startDate: DateTime(2023, 1, 1),
      endDate: DateTime(2023, 12, 31),
      status: 'active',
      usageCount: 1200,
      couponCode: 'WELCOME100',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPromoDialog(BuildContext context, {PromotionModel? promoToEdit}) {
    final isEditing = promoToEdit != null;
    final nameCtrl = TextEditingController(text: promoToEdit?.name ?? '');
    final codeCtrl = TextEditingController(text: promoToEdit?.couponCode ?? '');
    final valueCtrl = TextEditingController(text: promoToEdit != null && promoToEdit.value > 0 ? promoToEdit.value.toString() : '');
    final descCtrl = TextEditingController(text: promoToEdit?.description ?? '');
    final minPurchaseCtrl = TextEditingController(text: promoToEdit != null && promoToEdit.minimumPurchaseAmount > 0 ? promoToEdit.minimumPurchaseAmount.toString() : '');
    final maxDiscountCtrl = TextEditingController(text: promoToEdit != null && promoToEdit.maximumDiscount > 0 ? promoToEdit.maximumDiscount.toString() : '');

    String selectedType = promoToEdit?.type ?? 'Discount %';
    String selectedScope = promoToEdit?.scope ?? 'All Products';
    DateTime startDate = promoToEdit?.startDate ?? DateTime.now();
    DateTime endDate = promoToEdit?.endDate ?? DateTime.now().add(const Duration(days: 30));
    List<String> selectedCategories = List.from(promoToEdit?.applicableCategories ?? []);
    List<String> selectedProducts = List.from(promoToEdit?.applicableProducts ?? []);

    String currentImageUrl = promoToEdit?.imageUrl ?? '';
    Uint8List? selectedImageBytes;
    String selectedImageName = '';
    bool isUploadingImage = false;
    double uploadProgress = 0.0;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final categoriesAsync = ref.watch(categoriesFirestoreProvider);
            final productsAsync = ref.watch(firestoreProductsProvider);

            Future<void> pickAndUploadImage() async {
              Uint8List? rawBytes;
              String? fileName;

              try {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                  allowMultiple: false,
                  withData: true,
                );

                if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
                  rawBytes = result.files.first.bytes;
                  fileName = result.files.first.name;
                }
              } catch (_) {
                try {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    rawBytes = await pickedFile.readAsBytes();
                    fileName = pickedFile.name;
                  }
                } catch (e) {
                  debugPrint('Image pick error: $e');
                }
              }

              if (rawBytes == null) return;

              setDialogState(() {
                selectedImageBytes = rawBytes;
                selectedImageName = fileName ?? 'promo_banner.jpg';
                isUploadingImage = true;
                uploadProgress = 0.15;
              });

              try {
                final uploadedUrl = await CloudinaryService.uploadImage(
                  imageBytes: rawBytes,
                  fileName: selectedImageName,
                  onProgress: (p) {
                    setDialogState(() {
                      uploadProgress = p;
                    });
                  },
                );

                setDialogState(() {
                  currentImageUrl = uploadedUrl;
                  isUploadingImage = false;
                });

                if (mounted) {
                  toastification.show(
                    context: context,
                    title: const Text('Banner Uploaded'),
                    description: const Text('16:9 promotion banner uploaded to Cloudinary successfully.'),
                    type: ToastificationType.success,
                  );
                }
              } catch (e) {
                setDialogState(() {
                  isUploadingImage = false;
                });
                if (mounted) {
                  toastification.show(
                    context: context,
                    title: const Text('Upload Failed'),
                    description: Text(e.toString()),
                    type: ToastificationType.error,
                  );
                }
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
              child: Container(
                width: 660,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isEditing ? Icons.edit_note : Icons.add_circle_outline,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isEditing ? 'Edit Promotion' : 'Create Promotion',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // 16:9 Banner Image Picker Section
                      const Text(
                        'Promotion Banner (16:9 Aspect Ratio) *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentImageUrl.isNotEmpty ? AppColors.primary : Colors.grey.shade400,
                              width: currentImageUrl.isNotEmpty ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (selectedImageBytes != null)
                                  Image.memory(
                                    selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                else if (currentImageUrl.isNotEmpty)
                                  Image.network(
                                    currentImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                    ),
                                  )
                                else
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade500),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add 16:9 Promotion Banner Image',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Connects directly to Cloudinary (Recommended: 1280x720 or 1920x1080)',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (isUploadingImage)
                                  Container(
                                    color: Colors.black54,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(color: Colors.white),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Uploading to Cloudinary... ${(uploadProgress * 100).toInt()}%',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  right: 12,
                                  bottom: 12,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    icon: Icon(
                                      currentImageUrl.isNotEmpty ? Icons.change_circle : Icons.upload_file,
                                      size: 18,
                                    ),
                                    label: Text(
                                      currentImageUrl.isNotEmpty ? 'Change Image' : 'Choose 16:9 Image',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    onPressed: isUploadingImage ? null : pickAndUploadImage,
                                  ),
                                ),
                                if (currentImageUrl.isNotEmpty && !isUploadingImage)
                                  Positioned(
                                    left: 12,
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.cloud_done, color: Colors.greenAccent, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'Cloudinary Synced',
                                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Promo Name *',
                                hintText: 'e.g. Summer Sale',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: codeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Coupon / Promo Code',
                                hintText: 'e.g. SUMMER15',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: ['Discount %', 'Flat Off', 'BOGO', 'monthly', 'Coupon'].contains(selectedType)
                                  ? selectedType
                                  : 'Discount %',
                              decoration: const InputDecoration(
                                labelText: 'Type',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: ['Discount %', 'Flat Off', 'BOGO', 'monthly', 'Coupon']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedType = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: ['All Products', 'Specific Category', 'Specific Products'].contains(selectedScope)
                                  ? selectedScope
                                  : 'All Products',
                              decoration: const InputDecoration(
                                labelText: 'Scope',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: ['All Products', 'Specific Category', 'Specific Products']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedScope = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      if (selectedScope == 'Specific Category') ...[
                        const SizedBox(height: 16),
                        categoriesAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox(),
                          data: (cats) {
                            // Deduplicate categories by name / id
                            final uniqueCats = <String, String>{};
                            for (final c in cats) {
                              if (c.name.trim().isNotEmpty) {
                                uniqueCats[c.id.isNotEmpty ? c.id : c.name] = c.name;
                              }
                            }

                            final String? currentValue = selectedCategories.isNotEmpty
                                ? (uniqueCats.containsKey(selectedCategories.first)
                                    ? selectedCategories.first
                                    : (uniqueCats.containsValue(selectedCategories.first)
                                        ? uniqueCats.entries.firstWhere((e) => e.value == selectedCategories.first).key
                                        : null))
                                : null;

                            return DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Select Target Category',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              value: currentValue,
                              hint: const Text('Choose a category'),
                              items: uniqueCats.entries
                                  .map((entry) => DropdownMenuItem<String>(
                                        value: entry.key,
                                        child: Text(entry.value, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final catName = uniqueCats[val] ?? val;
                                  setDialogState(() {
                                    selectedCategories = [catName];
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ],
                      if (selectedScope == 'Specific Products') ...[
                        const SizedBox(height: 16),
                        productsAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox(),
                          data: (prods) {
                            // Deduplicate products by id and name
                            final uniqueProds = <String, String>{};
                            for (final p in prods) {
                              final name = p.name.trim();
                              if (name.isNotEmpty) {
                                final id = p.id.isNotEmpty ? p.id : name;
                                uniqueProds[id] = name;
                              }
                            }

                            final String? currentProdValue = selectedProducts.isNotEmpty
                                ? (uniqueProds.containsKey(selectedProducts.first)
                                    ? selectedProducts.first
                                    : (uniqueProds.containsValue(selectedProducts.first)
                                        ? uniqueProds.entries.firstWhere((e) => e.value == selectedProducts.first).key
                                        : null))
                                : null;

                            return DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Select Target Product',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              value: currentProdValue,
                              hint: const Text('Choose a product'),
                              items: uniqueProds.entries
                                  .map((entry) => DropdownMenuItem<String>(
                                        value: entry.key,
                                        child: Text(entry.value, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final prodName = uniqueProds[val] ?? val;
                                  setDialogState(() {
                                    selectedProducts = [prodName];
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: valueCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: selectedType == 'Flat Off' ? 'Discount Amount (Rs.)' : 'Discount Value (%)',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: minPurchaseCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Min Purchase (Rs.)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text('Start: ${_dateFmt.format(startDate)}'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) setDialogState(() => startDate = picked);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event, size: 16),
                              label: Text('End: ${_dateFmt.format(endDate)}'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2035),
                                );
                                if (picked != null) setDialogState(() => endDate = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Enter promotion terms or details...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Icon(isEditing ? Icons.check : Icons.add, color: Colors.white, size: 18),
                            label: Text(
                              isEditing ? 'Update Promotion' : 'Create Promotion',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                toastification.show(
                                  context: context,
                                  title: const Text('Validation Error'),
                                  description: const Text('Please enter a promotion name'),
                                  type: ToastificationType.error,
                                );
                                return;
                              }

                              final val = double.tryParse(valueCtrl.text.trim()) ?? 0.0;
                              final minPurch = double.tryParse(minPurchaseCtrl.text.trim()) ?? 0.0;
                              final maxDisc = double.tryParse(maxDiscountCtrl.text.trim()) ?? 0.0;
                              final code = codeCtrl.text.trim();

                              final model = PromotionModel(
                                id: promoToEdit?.id ?? '',
                                name: name,
                                type: selectedType,
                                value: val,
                                scope: selectedScope,
                                startDate: startDate,
                                endDate: endDate,
                                status: promoToEdit?.status ?? 'active',
                                usageCount: promoToEdit?.usageCount ?? 0,
                                couponCode: code.isNotEmpty ? code : name.toUpperCase().replaceAll(' ', ''),
                                description: descCtrl.text.trim(),
                                minimumPurchaseAmount: minPurch,
                                maximumDiscount: maxDisc,
                                applicableCategories: selectedCategories,
                                applicableProducts: selectedProducts,
                                imageUrl: currentImageUrl,
                              );

                              try {
                                if (isEditing) {
                                  await ref.read(firestorePromotionsProvider.notifier).updatePromo(model);
                                } else {
                                  await ref.read(firestorePromotionsProvider.notifier).add(model);
                                }
                                if (mounted) {
                                  Navigator.pop(context);
                                  toastification.show(
                                    context: context,
                                    title: Text(isEditing ? 'Promotion Updated' : 'Promotion Created'),
                                    description: Text('"$name" has been saved to Firestore successfully.'),
                                    type: ToastificationType.success,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  toastification.show(
                                    context: context,
                                    title: const Text('Error Saving Promotion'),
                                    description: Text(e.toString()),
                                    type: ToastificationType.error,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPerformanceDialog(BuildContext context, PromotionModel promo) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final estimatedRevenue = (promo.usageCount * 100.0);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics, color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Performance: ${promo.name}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.blue.withValues(alpha: 0.08),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Redemptions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text('${promo.usageCount}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Colors.green.withValues(alpha: 0.08),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Revenue Impact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(_currFmt.format(estimatedRevenue), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Redemption Trend (Weekly)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
                              switch (val.toInt()) {
                                case 1: return const Text('W1', style: TextStyle(fontSize: 10));
                                case 2: return const Text('W2', style: TextStyle(fontSize: 10));
                                case 3: return const Text('W3', style: TextStyle(fontSize: 10));
                                case 4: return const Text('W4', style: TextStyle(fontSize: 10));
                                default: return const Text('');
                              }
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: (promo.usageCount * 0.15).clamp(5, 500), color: AppColors.primary, width: 20)]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: (promo.usageCount * 0.35).clamp(10, 800), color: AppColors.primary, width: 20)]),
                        BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: (promo.usageCount * 0.30).clamp(8, 700), color: AppColors.primary, width: 20)]),
                        BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: (promo.usageCount * 0.20).clamp(5, 600), color: AppColors.primary, width: 20)]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, PromotionModel promo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: Text('Are you sure you want to delete "${promo.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(firestorePromotionsProvider.notifier).delete(promo.id);
                if (mounted) {
                  toastification.show(
                    context: context,
                    title: const Text('Promotion Deleted'),
                    type: ToastificationType.info,
                  );
                }
              } catch (e) {
                if (mounted) {
                  toastification.show(
                    context: context,
                    title: const Text('Error Deleting Promotion'),
                    description: Text(e.toString()),
                    type: ToastificationType.error,
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final promotionsAsync = ref.watch(firestorePromotionsProvider);

    final List<PromotionModel> rawPromotions = promotionsAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list : _fallbackPromotions,
      orElse: () => _fallbackPromotions,
    );

    // Apply Search Query & Filter
    final q = _searchQuery.toLowerCase().trim();
    final promotions = rawPromotions.where((p) {
      if (q.isNotEmpty) {
        final nameMatch = p.name.toLowerCase().contains(q);
        final codeMatch = p.couponCode.toLowerCase().contains(q);
        final typeMatch = p.type.toLowerCase().contains(q);
        if (!nameMatch && !codeMatch && !typeMatch) return false;
      }

      if (_selectedFilter == 'Active' && !p.isActive) return false;
      if (_selectedFilter == 'Inactive' && p.isActive) return false;
      if (_selectedFilter == 'Discount %' && !p.type.toLowerCase().contains('discount')) return false;
      if (_selectedFilter == 'Flat Off' && !p.type.toLowerCase().contains('flat')) return false;
      if (_selectedFilter == 'BOGO' && !p.type.toLowerCase().contains('bogo')) return false;

      return true;
    }).toList();

    final allSelected = promotions.isNotEmpty && _selectedIds.length == promotions.length;
    final activeCount = rawPromotions.where((p) => p.isActive).length;
    final totalUsage = rawPromotions.fold<int>(0, (sum, p) => sum + p.usageCount);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Promotions & Discounts', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Manage discounts, coupon codes, and promotional campaigns',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showPromoDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Create Promotion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Campaigns', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text('${rawPromotions.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Active Promos', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text('$activeCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.confirmation_number_outlined, color: Colors.purple, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Redemptions', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text('$totalUsage', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search and Filter Bar
            Row(
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search promo name or coupon code...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedFilter,
                  underline: const SizedBox(),
                  items: ['All', 'Active', 'Inactive', 'Discount %', 'Flat Off', 'BOGO']
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text('Filter: $f', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedFilter = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Data Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.bgDarkBorder : AppColors.border),
                ),
                child: promotionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error loading promotions: $err')),
                  data: (_) {
                    if (promotions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_offer_outlined, size: 54, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            const Text('No promotions found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty ? 'Try adjusting your search query or filters.' : 'Click "Create Promotion" to add your first campaign.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    return DataTable2(
                      columnSpacing: 16,
                      horizontalMargin: 16,
                      columns: [
                        DataColumn2(
                          label: Checkbox(
                            value: allSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.addAll(promotions.map((p) => p.id));
                                } else {
                                  _selectedIds.clear();
                                }
                              });
                            },
                          ),
                          size: ColumnSize.S,
                        ),
                        const DataColumn2(label: Text('Banner'), size: ColumnSize.S),
                        const DataColumn2(label: Text('Promo Name'), size: ColumnSize.L),
                        const DataColumn2(label: Text('Type'), size: ColumnSize.M),
                        const DataColumn2(label: Text('Scope'), size: ColumnSize.M),
                        const DataColumn2(label: Text('Start Date'), size: ColumnSize.M),
                        const DataColumn2(label: Text('End Date'), size: ColumnSize.M),
                        const DataColumn2(label: Text('Usage'), size: ColumnSize.S, numeric: true),
                        const DataColumn2(label: Text('Active'), size: ColumnSize.S),
                        const DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                      ],
                      rows: promotions.map((promo) {
                        final isChecked = _selectedIds.contains(promo.id);
                        return DataRow(
                          selected: isChecked,
                          onSelectChanged: (_) => _showPerformanceDialog(context, promo),
                          cells: [
                            DataCell(
                              Checkbox(
                                value: isChecked,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIds.add(promo.id);
                                    } else {
                                      _selectedIds.remove(promo.id);
                                    }
                                  });
                                },
                              ),
                            ),
                            DataCell(
                              Container(
                                width: 56,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.grey.shade200,
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: promo.imageUrl.isNotEmpty
                                    ? Image.network(
                                        promo.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 16, color: Colors.grey),
                                      )
                                    : const Center(
                                        child: Icon(Icons.local_offer, size: 16, color: Colors.grey),
                                      ),
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    promo.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (promo.couponCode.isNotEmpty)
                                    Text(
                                      'Code: ${promo.couponCode}',
                                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  promo.type,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(promo.scope)),
                            DataCell(Text(_dateFmt.format(promo.startDate))),
                            DataCell(Text(_dateFmt.format(promo.endDate))),
                            DataCell(Text(promo.usageCount.toString())),
                            DataCell(
                              Switch(
                                value: promo.isActive,
                                activeColor: AppColors.primary,
                                onChanged: (val) async {
                                  try {
                                    await ref
                                        .read(firestorePromotionsProvider.notifier)
                                        .toggleStatus(promo.id, val);
                                    if (mounted) {
                                      toastification.show(
                                        context: context,
                                        title: Text(val ? 'Promotion Activated' : 'Promotion Deactivated'),
                                        type: ToastificationType.info,
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      toastification.show(
                                        context: context,
                                        title: const Text('Error Updating Status'),
                                        description: Text(e.toString()),
                                        type: ToastificationType.error,
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.analytics_outlined, size: 18),
                                    tooltip: 'Performance',
                                    onPressed: () => _showPerformanceDialog(context, promo),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Edit',
                                    onPressed: () => _showPromoDialog(context, promoToEdit: promo),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusRed),
                                    tooltip: 'Delete',
                                    onPressed: () => _confirmDelete(context, promo),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
