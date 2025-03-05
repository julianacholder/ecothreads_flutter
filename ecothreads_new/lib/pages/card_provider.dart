// cart_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];

  CartProvider() {
    _loadCartFromPrefs();
  }

  List<CartItem> get items => _items;

  int get totalPoints => _items.fold(0, (sum, item) => sum + item.points);

  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartJson = prefs.getString('cart');

    if (cartJson != null) {
      final List<dynamic> decodedList = json.decode(cartJson);
      _items = decodedList.map((item) => CartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList =
        json.encode(_items.map((item) => item.toJson()).toList());
    await prefs.setString('cart', encodedList);
  }

  Future<void> addItem(CartItem item) async {
    try {
      _items.add(item);
      await _saveCartToPrefs();
      notifyListeners();
    } catch (e) {
      print('Error adding item to cart: $e');
      // Optionally rethrow or handle the error
    }
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    _saveCartToPrefs();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveCartToPrefs();
    notifyListeners();
  }
}
