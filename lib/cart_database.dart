import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'cart_item.dart';

class CartDatabase {
  static final CartDatabase instance = CartDatabase._init();

  static Database? _database;

  CartDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cart.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String path = join(appDocDir.path, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        quantity INTEGER NOT NULL
      )
    ''');
  }

  Future<CartItem> insertItem(CartItem item) async {
    final db = await database;
    final int id = await db.insert('cart', item.toMap());
    return item.copyWith(id: id);
  }

  Future<CartItem> addOrIncrementItem(CartItem item) async {
    final db = await database;
    final existing = await db.query(
      'cart',
      where: 'title = ?',
      whereArgs: [item.title],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final current = CartItem.fromMap(existing.first);
      final updated = current.copyWith(quantity: current.quantity + item.quantity);
      await updateItem(updated);
      return updated;
    }

    return insertItem(item);
  }

  Future<List<CartItem>> getItems() async {
    final db = await database;
    final items = await db.query('cart');
    return items.map((map) => CartItem.fromMap(map)).toList();
  }

  Future<int> updateItem(CartItem item) async {
    final db = await database;
    return db.update(
      'cart',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return db.delete('cart', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearCart() async {
    final db = await database;
    return db.delete('cart');
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
