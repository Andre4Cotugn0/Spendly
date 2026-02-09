import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final String iconName;
  final Color color;
  final bool isDefault;
  final DateTime createdAt;

  Category({
    String? id,
    required this.name,
    required this.iconName,
    required this.color,
    this.isDefault = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color': color.toARGB32(),
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['icon_name'] as String,
      color: Color(map['color'] as int),
      isDefault: (map['is_default'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? iconName,
    Color? color,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon_name': iconName,
    'color': color.toARGB32(),
    'is_default': isDefault,
    'created_at': createdAt.toIso8601String(),
  };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String,
      color: Color(json['color'] as int),
      isDefault: json['is_default'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
