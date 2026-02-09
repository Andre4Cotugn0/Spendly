import 'package:flutter/material.dart';
import '../models/category.dart';

/// Categorie predefinite dell'app
class DefaultCategories {
  static final List<Category> categories = [
    Category(
      id: 'food',
      name: 'Cibo',
      iconName: 'food',
      color: const Color(0xFFFF6B6B),
      isDefault: true,
    ),
    Category(
      id: 'transport',
      name: 'Trasporti',
      iconName: 'transport',
      color: const Color(0xFF4ECDC4),
      isDefault: true,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      iconName: 'shopping',
      color: const Color(0xFFFFE66D),
      isDefault: true,
    ),
    Category(
      id: 'bills',
      name: 'Bollette',
      iconName: 'bills',
      color: const Color(0xFF95E1D3),
      isDefault: true,
    ),
    Category(
      id: 'entertainment',
      name: 'Svago',
      iconName: 'entertainment',
      color: const Color(0xFFA66CFF),
      isDefault: true,
    ),
    Category(
      id: 'health',
      name: 'Salute',
      iconName: 'health',
      color: const Color(0xFFFF9671),
      isDefault: true,
    ),
    Category(
      id: 'home',
      name: 'Casa',
      iconName: 'home',
      color: const Color(0xFF6BCB77),
      isDefault: true,
    ),
    Category(
      id: 'other',
      name: 'Altro',
      iconName: 'other',
      color: const Color(0xFF778DA9),
      isDefault: true,
    ),
  ];

  static Category? getById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
