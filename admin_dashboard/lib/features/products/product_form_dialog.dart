import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:toastification/toastification.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_compressor/image_compressor.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/data/models.dart';
import 'package:intl/intl.dart';
import '../categories/category_provider.dart';
import 'product_providers.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final ProductModel? product;

  const ProductFormDialog({super.key, this.product});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  final TextEditingController _imageUrlController = TextEditingController();
  bool _isLoading = false;
  DateTime? _expiryDate;

  // ── Image state ────────────────────────────────────────────────────────────
  Uint8List? _pickedImageBytes;
  String? _pickedFileName;
  String _imageUrl = '';
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  static const List<String> _fallbackCategories = [
    'grocery',
    'vegetable & fruits',
    'chilledfood',
    'frozenfoods',
    'beverages',
    'household',
    'dairy',
    'bakery',
    'snacks',
  ];

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.product?.imageUrl ?? '';
    _imageUrlController.text = _imageUrl;
    _expiryDate = widget.product?.expiryDate;
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  // ── Pick & Upload Image ───────────────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    Uint8List? rawBytes;
    String? fileName;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
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

    setState(() {
      _pickedFileName = fileName ?? 'product_image.jpg';
      _isUploading = true;
      _uploadProgress = 0.05;
    });

    try {
      final compressedBytes = await compressImageNative(
        rawBytes,
        maxWidth: 800,
        maxHeight: 800,
        quality: 0.8,
      );

      setState(() {
        _pickedImageBytes = compressedBytes;
        _uploadProgress = 0.20;
      });

      final secureUrl = await CloudinaryService.uploadImage(
        imageBytes: compressedBytes,
        fileName: _pickedFileName ?? 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = (0.20 + progress * 0.80).clamp(0.0, 1.0);
            });
          }
        },
      );

      setState(() {
        _imageUrl = secureUrl;
        _imageUrlController.text = secureUrl;
        _isUploading = false;
        _uploadProgress = 1.0;
      });

      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          title: const Text('Image uploaded!'),
          description: const Text('Product image uploaded to Cloudinary successfully.'),
          icon: const Icon(Icons.cloud_done_outlined),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('Cloudinary upload notice'),
          description: Text('${e.toString().replaceAll('Exception: ', '')}\nYou can also paste an image URL directly.'),
          icon: const Icon(Icons.error_outline),
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.product != null;
    final categoriesAsync = ref.watch(categoriesFirestoreProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Product' : 'Add Product',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? AppColors.bgDarkBorder : AppColors.border),

            // ── Form ─────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FormBuilder(
                  key: _formKey,
                  initialValue: {
                    if (isEdit) ...{
                      'name': widget.product!.name,
                      'sku': widget.product!.sku,
                      'category': widget.product!.category.toLowerCase().trim(),
                      'price': widget.product!.price.toString(),
                      'cost': widget.product!.cost.toString(),
                      'stock': widget.product!.stock.toString(),
                      'unit': widget.product!.unit.isNotEmpty ? widget.product!.unit : 'piece',
                      'description': widget.product!.description,
                      'isActive': widget.product!.status == 'active',
                    } else ...{
                      'isActive': true,
                      'unit': 'piece',
                      'category': 'grocery',
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & SKU
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: FormBuilderTextField(
                              name: 'name',
                              decoration: const InputDecoration(
                                labelText: 'Product Name *',
                                border: OutlineInputBorder(),
                                hintText: 'e.g. Fresh Milk 1L',
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(2),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: FormBuilderTextField(
                              name: 'sku',
                              decoration: const InputDecoration(
                                labelText: 'SKU / Barcode *',
                                border: OutlineInputBorder(),
                                hintText: 'e.g. VEL1001',
                              ),
                              validator: FormBuilderValidators.required(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      categoriesAsync.when(
                        loading: () => _buildCategoryDropdown(
                          categories: [],
                          currentVal: isEdit ? widget.product!.category : 'grocery',
                        ),
                        error: (_, __) => _buildCategoryDropdown(
                          categories: [],
                          currentVal: isEdit ? widget.product!.category : 'grocery',
                        ),
                        data: (cats) => _buildCategoryDropdown(
                          categories: cats,
                          currentVal: isEdit ? widget.product!.category : 'grocery',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price & Cost
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'price',
                              decoration: const InputDecoration(
                                labelText: 'Selling Price (Rs) *',
                                border: OutlineInputBorder(),
                                prefixText: 'Rs ',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
                                FormBuilderValidators.min(0.01),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'cost',
                              decoration: const InputDecoration(
                                labelText: 'Cost Price (Rs) *',
                                border: OutlineInputBorder(),
                                prefixText: 'Rs ',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
                                FormBuilderValidators.min(0),
                              ]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stock & Unit
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'stock',
                              decoration: const InputDecoration(
                                labelText: 'Stock Quantity *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.integer(),
                                FormBuilderValidators.min(0),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FormBuilderDropdown<String>(
                              name: 'unit',
                              decoration: const InputDecoration(
                                labelText: 'Unit *',
                                border: OutlineInputBorder(),
                              ),
                              validator: FormBuilderValidators.required(),
                              items: ['kg', 'piece', 'pack', 'liter', 'dozen', 'g', 'ml']
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Expiry Date Field
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 90)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2040),
                          );
                          if (picked != null) {
                            setState(() {
                              _expiryDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Expiry Date (Optional)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.event_outlined),
                            suffixIcon: _expiryDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setState(() => _expiryDate = null),
                                  )
                                : null,
                          ),
                          child: Text(
                            _expiryDate != null
                                ? DateFormat('dd MMM yyyy').format(_expiryDate!)
                                : 'No expiry date set',
                            style: TextStyle(
                              color: _expiryDate != null ? null : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      FormBuilderTextField(
                        name: 'description',
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          hintText: 'Product details, ingredients, or pack size...',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // ── Image Section (Upload or Direct URL) ─────────────
                      _buildImageSection(isDark),
                      const SizedBox(height: 16),

                      // Active toggle
                      FormBuilderSwitch(
                        name: 'isActive',
                        title: const Text('Status (Active / Available in Store)'),
                        decoration: const InputDecoration(border: InputBorder.none),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────────
            Divider(height: 1, color: isDark ? AppColors.bgDarkBorder : AppColors.border),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: (_isLoading || _isUploading) ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Update Product' : 'Save Product'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Dropdown Builder ──────────────────────────────────────────────
  Widget _buildCategoryDropdown({
    required List<CategoryModel> categories,
    required String currentVal,
  }) {
    final Map<String, String> categoryOptions = {};

    for (final cat in _fallbackCategories) {
      final label = cat.replaceAll('&', 'and').split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');
      categoryOptions[cat.toLowerCase().trim()] = label;
    }

    for (final c in categories) {
      final key = c.name.toLowerCase().trim();
      categoryOptions[key] = c.name;
      if (c.id.isNotEmpty) {
        categoryOptions[c.id.toLowerCase().trim()] = c.name;
      }
    }

    final curLower = currentVal.toLowerCase().trim();
    if (curLower.isNotEmpty && !categoryOptions.containsKey(curLower)) {
      categoryOptions[curLower] = currentVal;
    }

    final dropdownItems = categoryOptions.entries.map((e) {
      return DropdownMenuItem<String>(
        value: e.key,
        child: Text(e.value),
      );
    }).toList();

    return FormBuilderDropdown<String>(
      name: 'category',
      decoration: const InputDecoration(
        labelText: 'Category *',
        border: OutlineInputBorder(),
      ),
      validator: FormBuilderValidators.required(),
      items: dropdownItems,
    );
  }

  // ── Image Section Widget ───────────────────────────────────────────────────
  Widget _buildImageSection(bool isDark) {
    final borderColor = isDark ? AppColors.bgDarkBorder : AppColors.border;
    final bool hasImage = _pickedImageBytes != null || _imageUrl.trim().isNotEmpty;
    final bool isNetwork = _imageUrl.startsWith('http://') || _imageUrl.startsWith('https://');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Picture',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
            color: isDark ? AppColors.bgDarkCard : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image Preview Box
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: _isUploading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _pickedImageBytes != null
                              ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                              : _imageUrl.isNotEmpty
                                  ? (isNetwork
                                      ? Image.network(
                                          _imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                                          ),
                                        )
                                      : Image.asset(
                                          _imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.image, color: Colors.grey),
                                          ),
                                        ))
                                  : Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 36,
                                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                                    ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Actions & Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isUploading) ...[
                          Row(
                            children: [
                              Text(
                                'Uploading image… ',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ] else ...[
                          Text(
                            hasImage ? (_pickedFileName ?? 'Product Picture Set') : 'No image uploaded yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upload JPG, PNG, WEBP from your computer, or paste a link below',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed: _isUploading ? null : _pickAndUploadImage,
                              icon: Icon(hasImage ? Icons.swap_horiz : Icons.upload_file_rounded, size: 16),
                              label: Text(hasImage ? 'Change File' : 'Upload Image'),
                            ),
                            if (hasImage && !_isUploading)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _pickedImageBytes = null;
                                    _pickedFileName = null;
                                    _imageUrl = '';
                                    _imageUrlController.clear();
                                  });
                                },
                                icon: const Icon(Icons.delete_outline, size: 16),
                                label: const Text('Remove'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Image URL text input for manual/fallback input
              TextField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Or enter Image URL / Asset Path',
                  hintText: 'https://res.cloudinary.com/... or assets/images/...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.link, size: 18),
                  suffixIcon: _imageUrlController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            setState(() {
                              _imageUrl = '';
                              _imageUrlController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _imageUrl = val.trim();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Save logic ─────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    setState(() => _isLoading = true);
    final val = _formKey.currentState!.value;
    final isEdit = widget.product != null;

    final String finalImgUrl = _imageUrl.trim().isNotEmpty ? _imageUrl.trim() : _imageUrlController.text.trim();

    try {
      final product = ProductModel(
        id: isEdit
            ? widget.product!.id
            : 'prod_${DateTime.now().millisecondsSinceEpoch}',
        name: (val['name'] as String).trim(),
        sku: (val['sku'] as String).trim().toUpperCase(),
        category: (val['category'] as String).trim().toLowerCase(),
        price: double.parse(val['price'].toString()),
        cost: double.parse(val['cost'].toString()),
        stock: int.parse(val['stock'].toString()),
        unit: (val['unit'] as String).trim(),
        description: (val['description'] as String? ?? '').trim(),
        status: (val['isActive'] as bool? ?? true) ? 'active' : 'inactive',
        imageUrl: finalImgUrl,
        expiryDate: _expiryDate,
      );

      final notifier = ref.read(firestoreProductsProvider.notifier);

      if (isEdit) {
        await notifier.updateProduct(product);
      } else {
        await notifier.add(product);
      }

      if (!mounted) return;

      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: Text(isEdit ? 'Product updated!' : 'Product added!'),
        description: Text(isEdit
            ? '${product.name} has been updated successfully.'
            : '${product.name} has been added to your catalog.'),
        icon: const Icon(Icons.check_circle_outline),
        autoCloseDuration: const Duration(seconds: 3),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text('Failed to save product'),
        description: Text(e.toString()),
        icon: const Icon(Icons.error_outline),
        autoCloseDuration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
