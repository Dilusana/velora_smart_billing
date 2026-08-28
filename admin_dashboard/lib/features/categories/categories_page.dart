import 'dart:async';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import '../../core/services/cloudinary_service.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/data/models.dart';
import 'category_provider.dart';

// ── Combined result from the background isolate ──────────────────────────────
class _AnalyzeResult {
  final Uint8List bytes;    // compressed JPEG bytes
  final bool ratioWarning; // true if not close to 16:9
  const _AnalyzeResult(this.bytes, this.ratioWarning);
}

// Runs entirely in a background isolate — no main-thread blocking.
// Resizes to max 480 px longest side, JPEG @ 65% quality (~15–40 KB).
_AnalyzeResult _analyzeAndCompress(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return _AnalyzeResult(raw, false);

  // Ratio check
  final ratio = decoded.width / decoded.height;
  final ratioWarning = (ratio - (16 / 9)).abs() > 0.18;

  // Resize — 480 px longest side is plenty for a card thumbnail
  const maxDim = 480;
  final resized = (decoded.width > maxDim || decoded.height > maxDim)
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxDim : -1,
          height: decoded.height > decoded.width ? maxDim : -1,
        )
      : decoded;

  final compressed =
      Uint8List.fromList(img.encodeJpg(resized, quality: 65));
  return _AnalyzeResult(compressed, ratioWarning);
}

// ============================================================================
// Categories Page
// ============================================================================
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesFirestoreProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Category'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  onPressed: () => _showCategoryDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: categoriesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: AppColors.statusRed),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load categories.\n$err',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.statusRed),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(categoriesFirestoreProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (categories) {
                  if (categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FontAwesomeIcons.tags,
                              size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No categories yet. Add your first category.',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1000
                          ? 4
                          : (constraints.maxWidth > 700 ? 3 : 2);
                      final childAspectRatio = constraints.maxWidth > 1000
                          ? 1.35
                          : (constraints.maxWidth > 700 ? 1.25 : 1.12);

                      return GridView.builder(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          // Cards are roughly 16:9 image + info footer
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) =>
                            _CategoryCard(category: categories[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {CategoryModel? category}) {
    showDialog(
      context: context,
      builder: (_) => _CategoryFormDialog(category: category),
    );
  }
}

// ============================================================================
// Category Card — shows the 16:9 image as the card header
// ============================================================================
class _CategoryCard extends ConsumerStatefulWidget {
  final CategoryModel category;
  const _CategoryCard({required this.category});

  @override
  ConsumerState<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends ConsumerState<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = widget.category;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        child: GestureDetector(
          onTap: () => context.go('/products?category=${Uri.encodeComponent(cat.name)}'),
          child: Card(
            elevation: _isHovered ? 10 : 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.18),
            color: isDark ? AppColors.bgDarkCard : AppColors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _isHovered
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : (isDark ? AppColors.bgDarkBorder : AppColors.border),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 16:9 Image banner ──────────────────────────────────────
                Expanded(
                  flex: 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image or placeholder
                      cat.imageUrl.isNotEmpty
                          ? Image.network(
                              cat.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _ImagePlaceholder(isDark: isDark),
                            )
                          : _ImagePlaceholder(isDark: isDark),

                      // Gradient overlay at bottom for readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Action buttons (top-right on hover)
                      if (_isHovered)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              _ActionChip(
                                icon: Icons.edit,
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => _CategoryFormDialog(
                                      category: cat),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _ActionChip(
                                icon: Icons.delete,
                                color: AppColors.statusRed,
                                onTap: () => _confirmDelete(context, ref),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Info footer ────────────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            cat.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (cat.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Flexible(
                            child: Text(
                              cat.description,
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Are you sure you want to delete "${widget.category.name}"? '
            '${widget.category.productCount} products will be unassigned.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: AppColors.statusRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(categoriesFirestoreProvider.notifier)
                    .delete(widget.category.id);
                if (context.mounted) {
                  toastification.show(
                    context: context,
                    type: ToastificationType.success,
                    title: const Text('Category deleted'),
                    autoCloseDuration: const Duration(seconds: 3),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  toastification.show(
                    context: context,
                    type: ToastificationType.error,
                    title: Text('Delete failed: $e'),
                    autoCloseDuration: const Duration(seconds: 4),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Small icon chip overlaid on the card image
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color ?? Colors.white),
      ),
    );
  }
}

// Placeholder shown when no image is set
class _ImagePlaceholder extends StatelessWidget {
  final bool isDark;
  const _ImagePlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1E2533) : const Color(0xFFEFF2F7),
      child: Center(
        child: Icon(
          FontAwesomeIcons.image,
          size: 36,
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
    );
  }
}

// ============================================================================
// Add / Edit Dialog — with 16:9 image picker
// ============================================================================
class _CategoryFormDialog extends ConsumerStatefulWidget {
  final CategoryModel? category;
  const _CategoryFormDialog({this.category});

  @override
  ConsumerState<_CategoryFormDialog> createState() =>
      _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;

  // Image state
  Uint8List? _pickedImageBytes;
  String? _pickedFileName;
  String _imageUrl = '';
  bool _isCompressing = false;        // isolate compression in progress
  bool _isUploading = false;          // Firebase Storage upload in progress
  double _uploadProgress = 0.0;       // 0.0 – 1.0
  bool _ratioWarning = false;         // image is not ~16:9
  int _compressedKb = 0;              // size of compressed file in KB

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.category?.imageUrl ?? '';
  }

  // ── Pick & Upload ──────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    // Phase 1: show spinner immediately, run ALL heavy work in isolate
    setState(() {
      _pickedImageBytes = null;
      _pickedFileName = file.name;
      _isCompressing = true;
      _isUploading = false;
      _uploadProgress = 0.0;
      _ratioWarning = false;
      _compressedKb = 0;
    });

    // Phase 2: compress + ratio-check — entirely off the main thread
    late Uint8List uploadBytes;
    try {
      final result = await compute(_analyzeAndCompress, file.bytes!);
      uploadBytes = result.bytes;
      if (!mounted) return;
      setState(() {
        _pickedImageBytes = uploadBytes;
        _ratioWarning = result.ratioWarning;
        _compressedKb = (uploadBytes.lengthInBytes / 1024).round();
        _isCompressing = false;
        _isUploading = true;
        _uploadProgress = 0.0;
      });
    } catch (_) {
      uploadBytes = file.bytes!;
      if (!mounted) return;
      setState(() {
        _pickedImageBytes = uploadBytes;
        _isCompressing = false;
        _isUploading = true;
        _uploadProgress = 0.0;
      });
    }

    // Phase 3: upload to Cloudinary with progress tracking
    try {
      final secureUrl = await CloudinaryService.uploadImage(
        imageBytes: uploadBytes,
        fileName: _pickedFileName ?? 'category_${DateTime.now().millisecondsSinceEpoch}.jpg',
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _imageUrl = secureUrl;
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Image uploaded!'),
        description: const Text('Category image uploaded to Cloudinary successfully.'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _pickedImageBytes = null;
        _pickedFileName = null;
      });
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Upload failed'),
        description: Text(e.toString().replaceAll('Exception: ', '')),
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }

  // ── Cancel active upload ─────────────────────────────────────────────────────
  void _cancelUpload() {
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.category != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ────────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Category' : 'Add Category',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Form ─────────────────────────────────────────────────────────
            FormBuilder(
              key: _formKey,
              initialValue: {
                'name': isEdit ? widget.category!.name : '',
                'description':
                    isEdit ? widget.category!.description : '',
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name field
                  FormBuilderTextField(
                    name: 'name',
                    decoration: const InputDecoration(
                      labelText: 'Category Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(),
                  ),
                  const SizedBox(height: 16),

                  // 16:9 Image picker
                  _buildImagePicker(isDark),
                  const SizedBox(height: 16),

                  // Description field
                  FormBuilderTextField(
                    name: 'description',
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Actions ───────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                  ),
                  onPressed: (_isSaving || _isUploading || _isCompressing)
                      ? null
                      : _save,
                  child: (_isSaving || _isUploading || _isCompressing)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 16:9 Image Picker Widget ───────────────────────────────────────────────
  Widget _buildImagePicker(bool isDark) {
    final isBusy = _isCompressing || _isUploading;
    final borderColor = isDark ? AppColors.bgDarkBorder : AppColors.border;
    final hasImage = _pickedImageBytes != null || _imageUrl.isNotEmpty;

    // Label shown inside the spinner
    String busyLabel;
    if (_isCompressing) {
      busyLabel = 'Compressing image…';
    } else if (_uploadProgress > 0) {
      busyLabel = 'Uploading… ${(_uploadProgress * 100).toStringAsFixed(0)}%';
    } else {
      busyLabel = 'Preparing upload…';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Image',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),

        // 16:9 preview container
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isBusy
                    ? AppColors.primary
                    : _ratioWarning
                        ? Colors.amber.shade600
                        : borderColor,
                width: (isBusy || _ratioWarning) ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
              color: isDark
                  ? const Color(0xFF1E2533)
                  : const Color(0xFFEFF2F7),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Preview / busy state ──────────────────────────────────
                if (isBusy)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            value: (_isUploading && _uploadProgress > 0)
                                ? _uploadProgress
                                : null,
                            strokeWidth: 5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          busyLabel,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        // Cancel button — only during upload phase
                        if (_isUploading) ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _cancelUpload,
                            icon: const Icon(Icons.close, size: 14),
                            label: const Text('Cancel',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else if (_pickedImageBytes != null)
                  Image.memory(
                    _pickedImageBytes!,
                    fit: BoxFit.cover,
                  )
                else if (_imageUrl.isNotEmpty)
                  Image.network(
                    _imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _noImageBody(isDark),
                  )
                else
                  _noImageBody(isDark),

                // ── Overlay buttons ──────────────────────────────────────
                if (!isBusy)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.65),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            textStyle: const TextStyle(fontSize: 13),
                            elevation: 0,
                          ),
                          onPressed: _pickImage,
                          icon: Icon(
                            hasImage
                                ? Icons.swap_horiz
                                : Icons.upload_outlined,
                            size: 16,
                          ),
                          label: Text(
                              hasImage ? 'Change Image' : 'Choose Image'),
                        ),
                        if (hasImage) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.red.withValues(alpha: 0.8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              textStyle: const TextStyle(fontSize: 13),
                              elevation: 0,
                            ),
                            onPressed: () => setState(() {
                              _pickedImageBytes = null;
                              _pickedFileName = null;
                              _imageUrl = '';
                              _ratioWarning = false;
                            }),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Remove'),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── 16:9 ratio warning ───────────────────────────────────────────
        if (_ratioWarning && !isBusy) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border:
                  Border.all(color: Colors.amber.shade400, width: 1.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Picture should be in 16:9 ratio for best display.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // File name hint + compressed size
        if (_pickedFileName != null && !isBusy) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  _pickedFileName!,
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_compressedKb > 0)
                Text(
                  '$_compressedKb KB',
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.greenAccent.shade200
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _noImageBody(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 42,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap "Choose Image" to upload\n16:9 ratio recommended',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    setState(() => _isSaving = true);
    final val = _formKey.currentState!.value;
    final isEdit = widget.category != null;

    final newCat = CategoryModel(
      id: isEdit ? widget.category!.id : '',
      name: (val['name'] as String).trim(),
      imageUrl: _imageUrl,
      description: (val['description'] as String? ?? '').trim(),
      productCount: isEdit ? widget.category!.productCount : 0,
      revenueShare: isEdit ? widget.category!.revenueShare : 0.0,
    );

    try {
      if (isEdit) {
        await ref
            .read(categoriesFirestoreProvider.notifier)
            .updateCategory(newCat);
      } else {
        await ref.read(categoriesFirestoreProvider.notifier).add(newCat);
      }
      if (mounted) {
        Navigator.pop(context);
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: Text(isEdit ? 'Category updated' : 'Category added'),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text('Save failed: $e'),
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    }
  }
}
