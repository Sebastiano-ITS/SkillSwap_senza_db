// lib/models/explore_category.dart
import 'package:flutter/material.dart';

// Modello per le grandi card di categoria
class InterestCategory {
  final String title;
  final String description;
  final String icon;
  final List<Color> gradient;

  InterestCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });

  factory InterestCategory.fromJson(Map<String, dynamic> json) {
    List<Color> colors = (json['gradient'] as List<dynamic>)
        .map((hex) => Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000))
        .toList();

    return InterestCategory(
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      gradient: colors,
    );
  }
}

// Modello per le piccole card dei "miei interessi"
class MyInterest {
  final String name;
  final String icon;

  MyInterest({required this.name, required this.icon});

  factory MyInterest.fromJson(Map<String, dynamic> json) {
    return MyInterest(
      name: json['name'],
      icon: json['icon'],
    );
  }
}