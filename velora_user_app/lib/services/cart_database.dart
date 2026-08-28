import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cart_item.dart';

class CartDatabase {
  static final CartDatabase instance = CartDatabase._init();

  static Database? _database;

  CartDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('user_cart.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    if (kIsWeb) {
      return await openDatabase(
        inMemoryDatabasePath,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    }

    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId TEXT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL,
        quantity INTEGER NOT NULL,
        imageUrl TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE cart ADD COLUMN productId TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE cart ADD COLUMN price REAL');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE cart ADD COLUMN imageUrl TEXT');
      } catch (_) {}
    }
  }

  final List<CartItem> _memoryCart = [];

  Future<CartItem> insertItem(CartItem item) async {
    try {
      final db = await database;
      final int id = await db.insert('cart', item.toMap());
      final newItem = item.copyWith(id: id);
      _memoryCart.add(newItem);
      return newItem;
    } catch (_) {
      final newItem = item.copyWith(id: _memoryCart.length + 1);
      _memoryCart.add(newItem);
      return newItem;
    }
  }

  Future<CartItem> addOrIncrementItem(CartItem item) async {
    try {
      final db = await database;
      final existing = await db.query(
        'cart',
        where: 'title = ?',
        whereArgs: [item.title],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final current = CartItem.fromMap(existing.first);
        final updated = current.copyWith(
          productId: item.productId.isNotEmpty ? item.productId : current.productId,
          price: item.price > 0 ? item.price : current.price,
          quantity: current.quantity + item.quantity,
          imageUrl: item.imageUrl.isNotEmpty ? item.imageUrl : current.imageUrl,
        );
        await updateItem(updated);
        return updated;
      }

      return insertItem(item);
    } catch (_) {
      final idx = _memoryCart.indexWhere((i) => i.title == item.title);
      if (idx != -1) {
        final current = _memoryCart[idx];
        final updated = current.copyWith(
          productId: item.productId.isNotEmpty ? item.productId : current.productId,
          price: item.price > 0 ? item.price : current.price,
          quantity: current.quantity + item.quantity,
          imageUrl: item.imageUrl.isNotEmpty ? item.imageUrl : current.imageUrl,
        );
        _memoryCart[idx] = updated;
        return updated;
      }
      return insertItem(item);
    }
  }

  Future<List<CartItem>> getItems() async {
    try {
      final db = await database;
      final items = await db.query('cart');
      return items.map((map) => CartItem.fromMap(map)).toList();
    } catch (_) {
      return List.unmodifiable(_memoryCart);
    }
  }

  Future<int> updateItem(CartItem item) async {
    try {
      final db = await database;
      return db.update(
        'cart',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } catch (_) {
      final idx = _memoryCart.indexWhere((i) => i.id == item.id || i.title == item.title);
      if (idx != -1) {
        _memoryCart[idx] = item;
        return 1;
      }
      return 0;
    }
  }

  Future<int> deleteItem(int id) async {
    try {
      final db = await database;
      return db.delete('cart', where: 'id = ?', whereArgs: [id]);
    } catch (_) {
      final countBefore = _memoryCart.length;
      _memoryCart.removeWhere((i) => i.id == id);
      return countBefore - _memoryCart.length;
    }
  }

  Future<int> clearCart() async {
    try {
      final db = await database;
      await db.delete('cart');
      _memoryCart.clear();
      return 1;
    } catch (_) {
      final count = _memoryCart.length;
      _memoryCart.clear();
      return count;
    }
  }
}
