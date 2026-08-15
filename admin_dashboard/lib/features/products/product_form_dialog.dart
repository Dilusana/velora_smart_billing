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
  bool _isLoading = false;

  // ── Image state ────────────────────────────────────────────────────────────
  /// Holds the picked file bytes (for in-memory preview before upload).
  Uint8List? _pickedImageBytes;

  /// Holds the filename of the picked file.
  String? _pickedFileName;

  /// The current imageUrl — starts from the existing product (edit) or empty.
  String _imageUrl = '';

  /// Whether we are currently uploading the image.
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.product?.imageUrl ?? '';
  }

  // ── Pick & Upload ──────────────────────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    Uint8List? rawBytes;
    String? fileName;

    // 1. Pick image using ImagePicker (or FilePicker as fallback)
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        rawBytes = await pickedFile.readAsBytes();
        fileName = pickedFile.name;
      }
    } catch (_) {
      // Fallback to FilePicker if ImagePicker is unsupported
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        rawBytes = result.files.first.bytes;
        fileName = result.files.first.name;
      }
    }

    if (rawBytes == null) return;

    setState(() {
      _pickedFileName = fileName ?? 'product_image.jpg';
      _isUploading = true;
      _uploadProgress = 0.05;
    });

    try {
      // 2. Compress image using browser-native HTML Canvas on Web (or IO fallback)
      // Dramatically faster than Dart image package pixel manipulation
      final compressedBytes = await compressImageNative(
        rawBytes,
        maxWidth: 800,
        maxHeight: 800,
        quality: 0.8,
      );

      setState(() {
        _pickedImageBytes = compressedBytes;
        _uploadProgress = 0.15;
      });

      // 3. Upload to Cloudinary using unsigned upload preset (r0gfpzep / velora_billing)
      final secureUrl = await CloudinaryService.uploadImage(
        imageBytes: compressedBytes,
        fileName: _pickedFileName ?? 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = (0.15 + progress * 0.85).clamp(0.0, 1.0);
            });
          }
        },
      );

      setState(() {
        _imageUrl = secureUrl;
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
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        // Revert preview if upload failed
        _pickedImageBytes = null;
        _pickedFileName = null;
      });

      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('Upload failed'),
          description: Text(e.toString().replaceAll('Exception: ', '')),
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
        width: 600,
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
                      'category': widget.product!.category,
                      'price': widget.product!.price.toString(),
                      'cost': widget.product!.cost.toString(),
                      'stock': widget.product!.stock.toString(),
                      'unit': widget.product!.unit,
                      'description': widget.product!.description,
                      'isActive': widget.product!.status == 'active',
                    } else ...{
                      'isActive': true,
                      'unit': 'piece',
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
                            child: FormBuilderTextField(
                              name: 'name',
                              decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(3),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'sku',
                              decoration: const InputDecoration(labelText: 'SKU *', border: OutlineInputBorder()),
                              textCapitalization: TextCapitalization.characters,
                              validator: FormBuilderValidators.required(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category
                      categoriesAsync.when(
                        loading: () => FormBuilderDropdown<String>(
                          name: 'category',
                          decoration: InputDecoration(
                            labelText: 'Category *',
                            border: OutlineInputBorder(),
                            suffixIcon: SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          items: [],
                        ),
                        error: (e, _) => FormBuilderDropdown<String>(
                          name: 'category',
                          decoration: InputDecoration(
                            labelText: 'Category *',
                            border: const OutlineInputBorder(),
                            errorText: 'Failed to load categories',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: () => ref.invalidate(categoriesFirestoreProvider),
                            ),
                          ),
                          items: const [],
                        ),
                        data: (categories) => FormBuilderDropdown<String>(
                          name: 'category',
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            border: OutlineInputBorder(),
                          ),
                          validator: FormBuilderValidators.required(),
                          items: categories
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ))
                              .toList(),
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
                                labelText: 'Selling Price *',
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
                                labelText: 'Cost Price *',
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
                              decoration: const InputDecoration(labelText: 'Stock Quantity *', border: OutlineInputBorder()),
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
                              decoration: const InputDecoration(labelText: 'Unit *', border: OutlineInputBorder()),
                              validator: FormBuilderValidators.required(),
                              items: ['kg', 'piece', 'pack', 'liter', 'dozen']
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      FormBuilderTextField(
                        name: 'description',
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // ── Image Picker (replaces old plain imageUrl text field) ──
                      _buildImagePicker(isDark),
                      const SizedBox(height: 16),

                      // Active toggle
                      FormBuilderSwitch(
                        name: 'isActive',
                        title: const Text('Status (Active / Inactive)'),
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

  // ── Image Picker Widget ────────────────────────────────────────────────────
  Widget _buildImagePicker(bool isDark) {
    final borderColor = isDark ? AppColors.bgDarkBorder : AppColors.border;
    final hasImage = _pickedImageBytes != null || _imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Image',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // ── Thumbnail / placeholder ──────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: _isUploading
                      ? const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      : _pickedImageBytes != null
                          // In-memory preview (just picked, upload succeeded)
                          ? Image.memory(
                              _pickedImageBytes!,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            )
                          : _imageUrl.isNotEmpty
                              // Existing URL from Firestore (edit mode)
                              ? Image.network(
                                  _imageUrl,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    size: 36,
                                    color: Colors.grey,
                                  ),
                                )
                              : Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                                ),
                ),
              ),

              // ── Info & actions ───────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isUploading) ...[
                        Row(
                          children: [
                            Text(
                              'Optimizing & Uploading… ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            minHeight: 6,
                            backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pickedFileName ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else if (hasImage) ...[
                        Text(
                          _pickedFileName ?? 'Image uploaded',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Change Image" to replace',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                        ),
                      ] else ...[
                        Text(
                          'No image selected',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PNG, JPG, WEBP supported',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Choose / Change button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                            onPressed: _isUploading ? null : _pickAndUploadImage,
                            icon: Icon(
                              hasImage ? Icons.swap_horiz : Icons.upload_outlined,
                              size: 16,
                            ),
                            label: Text(hasImage ? 'Change Image' : 'Choose Image'),
                          ),
                          // Remove button (only when an image is set)
                          if (hasImage && !_isUploading) ...[
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                              onPressed: () {
                                setState(() {
                                  _pickedImageBytes = null;
                                  _pickedFileName = null;
                                  _imageUrl = '';
                                });
                              },
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Remove'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
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

    try {
      final product = ProductModel(
        id: isEdit
            ? widget.product!.id
            : 'prod_${DateTime.now().millisecondsSinceEpoch}',
        name: (val['name'] as String).trim(),
        sku: (val['sku'] as String).trim().toUpperCase(),
        category: val['category'] as String,
        price: double.parse(val['price'].toString()),
        cost: double.parse(val['cost'].toString()),
        stock: int.parse(val['stock'].toString()),
        unit: val['unit'] as String,
        description: (val['description'] as String? ?? '').trim(),
        status: (val['isActive'] as bool? ?? true) ? 'active' : 'inactive',
        // Use the URL we stored from Firebase Storage upload
        imageUrl: _imageUrl,
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
