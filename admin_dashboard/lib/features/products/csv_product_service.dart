import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/data/models.dart';
import '../../core/theme/app_theme.dart';
import 'product_providers.dart';

class CsvProductService {
  static const String sampleCsvData = '''name,sku,category,price,cost,stock,unit,status,expiryDate,imageUrl,description
Fresh Whole Milk 1L,VEL1001,chilledfood,350.0,300.0,50,piece,active,2026-09-15,,Pasteurized fresh whole milk
Cheddar Cheese 250g,VEL1002,chilledfood,750.0,620.0,35,piece,active,2026-11-20,,Premium rich cheddar cheese
Salted Creamery Butter 200g,VEL1003,chilledfood,620.0,500.0,40,piece,active,2026-10-30,,Creamy salted butter
White Sandwich Bread 450g,VEL1004,grocery,180.0,140.0,60,piece,active,2026-09-05,,Freshly baked sliced white bread
Basmati Rice 5kg,VEL1005,grocery,2200.0,1850.0,45,piece,active,2027-06-30,,Long grain aromatic basmati rice
Pure Coconut Oil 1L,VEL1006,grocery,850.0,720.0,30,piece,active,2027-08-15,,100% pure edible coconut oil
Fresh Red Tomatoes,VEL1007,vegetable & fruits,120.0,80.0,50,kg,active,2026-09-03,,Farm fresh ripe red tomatoes
Fresh Cavendish Bananas,VEL1008,vegetable & fruits,180.0,120.0,40,kg,active,2026-09-02,,Sweet ripe yellow bananas
Green Bell Pepper (Capsicum),VEL1009,vegetable & fruits,320.0,240.0,25,kg,active,2026-09-04,,Crisp fresh green bell peppers
Ceylon Black Tea 400g,VEL1010,beverages,550.0,420.0,55,piece,active,2027-12-31,,Premium high grown Ceylon black tea
Natural Mineral Water 1.5L,VEL1011,beverages,120.0,80.0,100,piece,active,2027-05-10,,Pure bottled spring water
Fresh Orange Juice 1L,VEL1012,beverages,480.0,380.0,30,piece,active,2026-09-10,,100% natural citrus juice
Chicken Sausage 500g,VEL1013,frozenfoods,850.0,680.0,30,piece,active,2026-12-25,,Delicious frozen chicken sausages
Mixed Vegetable Pack 500g,VEL1014,frozenfoods,450.0,350.0,40,piece,active,2027-01-15,,Frozen peas carrots and sweetcorn
Harpic Toilet Cleaner 750ml,VEL1015,household,320.0,250.0,50,piece,active,2028-01-01,,Powerful germ disinfectant cleaner
Sunlight Dishwashing Liquid 500ml,VEL1016,household,260.0,200.0,45,piece,active,2027-10-01,,Lemon dish wash power liquid''';

  /// Helper to parse multiple date formats flexibly
  static DateTime? parseFlexibleDate(String input) {
    final clean = input.trim();
    if (clean.isEmpty || clean.toLowerCase() == 'n/a' || clean == '—' || clean == '-') return null;

    // 1. Direct ISO parse (e.g. 2026-11-18 or 2026-11-18T00:00:00)
    final iso = DateTime.tryParse(clean);
    if (iso != null) return iso;

    // 2. Common formats
    final formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'd/M/yyyy',
      'd-M-yyyy',
      'yyyy/MM/dd',
      'yyyy.MM.dd',
      'dd.MM.yyyy',
      'MM/dd/yyyy',
      'MM-dd-yyyy',
      'dd MMM yyyy',
      'dd-MMM-yyyy',
      'dd MMMM yyyy',
      'MMM dd, yyyy',
      'MMMM dd, yyyy',
    ];

    for (final fmt in formats) {
      try {
        final d = DateFormat(fmt, 'en_US').parseLoose(clean);
        return d;
      } catch (_) {}
    }

    // 3. Fallback regex for DD/MM/YYYY or DD-MM-YYYY
    final dmyMatch = RegExp(r'^(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})$').firstMatch(clean);
    if (dmyMatch != null) {
      final p1 = int.tryParse(dmyMatch.group(1)!);
      final p2 = int.tryParse(dmyMatch.group(2)!);
      var yr = int.tryParse(dmyMatch.group(3)!);
      if (yr != null && yr < 100) yr += 2000;
      if (p1 != null && p2 != null && yr != null) {
        if (p2 <= 12 && p1 <= 31) {
          return DateTime(yr, p2, p1);
        } else if (p1 <= 12 && p2 <= 31) {
          return DateTime(yr, p1, p2);
        }
      }
    }

    // 4. Excel date serial number (e.g. 45614)
    final numVal = double.tryParse(clean);
    if (numVal != null && numVal > 30000 && numVal < 65000) {
      final base = DateTime(1899, 12, 30);
      return base.add(Duration(days: numVal.round()));
    }

    return null;
  }

  /// 1. Download sample CSV template
  static Future<void> downloadSampleCsv(BuildContext context) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(sampleCsvData));
      await FileSaver.instance.saveFile(
        name: 'sample_inventory_products',
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample CSV template downloaded successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading sample CSV: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 2. Export existing products to CSV
  static Future<void> exportProductsToCsv(
    BuildContext context,
    List<ProductModel> products,
  ) async {
    try {
      final List<List<dynamic>> rows = [
        ['name', 'sku', 'category', 'price', 'cost', 'stock', 'unit', 'status', 'expiryDate', 'imageUrl', 'description']
      ];

      for (final p in products) {
        final expStr = p.expiryDate != null
            ? '${p.expiryDate!.year.toString().padLeft(4, '0')}-${p.expiryDate!.month.toString().padLeft(2, '0')}-${p.expiryDate!.day.toString().padLeft(2, '0')}'
            : '';

        rows.add([
          p.name,
          p.sku,
          p.category,
          p.price,
          p.cost,
          p.stock,
          p.unit,
          p.status,
          expStr,
          p.imageUrl,
          p.description,
        ]);
      }

      final String csvContent = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(utf8.encode(csvContent));

      await FileSaver.instance.saveFile(
        name: 'velora_inventory_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${products.length} products to CSV!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 3. Pick and import products from CSV file into Firestore
  static Future<void> importProductsFromCsv(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Unable to read selected file contents.');
      }

      final String csvString = utf8.decode(bytes);
      final List<List<dynamic>> csvTable = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: true,
      ).convert(csvString);

      if (csvTable.isEmpty) {
        throw Exception('CSV file is empty.');
      }

      // Normalize headers: strip all spaces, underscores, hyphens for resilient matching
      final headers = csvTable.first
          .map((e) => e.toString().trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '').replaceAll('-', ''))
          .toList();

      final nameIdx = headers.indexOf('name');
      final skuIdx = headers.indexOf('sku');
      final catIdx = headers.indexOf('category');
      final priceIdx = headers.indexOf('price');
      final costIdx = headers.indexOf('cost');
      final stockIdx = headers.indexOf('stock');
      final unitIdx = headers.indexOf('unit');
      final statusIdx = headers.indexOf('status');
      final expIdx = headers.indexWhere((h) =>
          h == 'expirydate' ||
          h == 'expiry' ||
          h == 'expirationdate' ||
          h == 'expdate' ||
          h.contains('expir'));
      final imgIdx = headers.indexOf('imageurl');
      final descIdx = headers.indexOf('description');

      if (nameIdx == -1 || priceIdx == -1) {
        throw Exception('Invalid CSV header: "name" and "price" columns are required.');
      }

      final List<Map<String, dynamic>> parsedProducts = [];
      final datePreviewFmt = DateFormat('dd MMM yyyy');

      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.isEmpty) continue;

        String getCol(int idx, {String fallback = ''}) {
          if (idx != -1 && idx < row.length && row[idx] != null) {
            return row[idx].toString().trim();
          }
          return fallback;
        }

        final name = getCol(nameIdx);
        if (name.isEmpty) continue;

        final rawPrice = getCol(priceIdx, fallback: '0');
        final cleanPrice = rawPrice.replaceAll(RegExp(r'[^0-9.]'), '');
        final double price = double.tryParse(cleanPrice) ?? 0.0;

        final rawCost = getCol(costIdx, fallback: '0');
        final cleanCost = rawCost.replaceAll(RegExp(r'[^0-9.]'), '');
        final double cost = double.tryParse(cleanCost) ?? 0.0;

        final rawStock = getCol(stockIdx, fallback: '0');
        final cleanStock = rawStock.replaceAll(RegExp(r'[^0-9]'), '');
        final int stock = int.tryParse(cleanStock) ?? 0;

        final sku = getCol(skuIdx, fallback: 'VEL${1000 + i}');
        final category = getCol(catIdx, fallback: 'grocery');
        final unit = getCol(unitIdx, fallback: 'piece');
        final status = getCol(statusIdx, fallback: 'active');
        final rawExp = getCol(expIdx, fallback: '');
        final imageUrl = getCol(imgIdx, fallback: '');
        final description = getCol(descIdx, fallback: '');

        final DateTime? parsedExpiry = parseFlexibleDate(rawExp);

        parsedProducts.add({
          'name': name,
          'sku': sku,
          'category': category.toLowerCase(),
          'price': price,
          'cost': cost,
          'stock': stock,
          'unit': unit,
          'status': status.toLowerCase(),
          if (parsedExpiry != null) 'expiryDate': Timestamp.fromDate(parsedExpiry),
          'expiryPreview': parsedExpiry != null ? datePreviewFmt.format(parsedExpiry) : 'None',
          'imageUrl': imageUrl,
          'description': description,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (parsedProducts.isEmpty) {
        throw Exception('No valid product rows found in CSV.');
      }

      // Show confirmation dialog before write
      if (!context.mounted) return;

      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.upload_file_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Confirm CSV Import'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${parsedProducts.length} product(s) ready to import/update.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('Preview of items to import:'),
                const SizedBox(height: 6),
                ...parsedProducts.take(4).map(
                      (p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          '• ${p['name']} (SKU: ${p['sku']}) - Expiry: ${p['expiryPreview']} - Stock: ${p['stock']}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                if (parsedProducts.length > 4)
                  Text(
                    '  ...and ${parsedProducts.length - 4} more',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Import Now'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Upsert into Firestore (update existing by SKU or Name to prevent duplicates)
      final firestore = FirebaseFirestore.instance;
      final productsRef = firestore.collection('products');

      // Fetch existing products map (by SKU and by lowercased Name)
      final existingSnapshot = await productsRef.get();
      final Map<String, String> existingBySku = {};
      final Map<String, String> existingByName = {};

      for (final doc in existingSnapshot.docs) {
        final data = doc.data();
        final docSku = data['sku']?.toString().trim().toLowerCase() ?? '';
        final docName = data['name']?.toString().trim().toLowerCase() ?? '';
        if (docSku.isNotEmpty) existingBySku[docSku] = doc.id;
        if (docName.isNotEmpty) existingByName[docName] = doc.id;
      }

      // Batch Write to Firestore
      for (var i = 0; i < parsedProducts.length; i += 400) {
        final chunk = parsedProducts.skip(i).take(400).toList();
        final batch = firestore.batch();

        for (final p in chunk) {
          final cleanMap = Map<String, dynamic>.from(p)..remove('expiryPreview');
          final sku = cleanMap['sku']?.toString().trim().toLowerCase() ?? '';
          final name = cleanMap['name']?.toString().trim().toLowerCase() ?? '';

          String? existingDocId = (sku.isNotEmpty ? existingBySku[sku] : null) ?? existingByName[name];

          if (existingDocId != null) {
            // Update existing product document
            batch.update(productsRef.doc(existingDocId), cleanMap);
          } else {
            // Create new product document
            cleanMap['createdAt'] = FieldValue.serverTimestamp();
            final newDoc = productsRef.doc();
            batch.set(newDoc, cleanMap);
            // Track in lookup maps to prevent intra-file duplicates
            if (sku.isNotEmpty) existingBySku[sku] = newDoc.id;
            if (name.isNotEmpty) existingByName[name] = newDoc.id;
          }
        }

        await batch.commit();
      }

      // Invalidate provider to trigger immediate UI refresh
      ref.invalidate(firestoreProductsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported and updated ${parsedProducts.length} products!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV Import Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

