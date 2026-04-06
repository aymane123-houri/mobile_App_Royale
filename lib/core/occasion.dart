// lib/core/occasion.dart

import 'package:flutter/material.dart';

/// Modèle pour un template d'ambiance (mood)
class MoodTemplate {
  final String label;
  final String labelAr;
  final String emoji;
  final String Function(String name) text;

  const MoodTemplate({
    required this.label,
    required this.labelAr,
    required this.emoji,
    required this.text,
  });
}

/// Modèle principal pour chaque occasion
class Occasion {
  final String id;
  final String emoji;
  final String name;
  final String nameAr;
  final String subtitle;
  final String subtitleAr;
  final Color accent;
  final Color accentSoft;
  final List<MoodTemplate> moods;

  const Occasion({
    required this.id,
    required this.emoji,
    required this.name,
    required this.nameAr,
    required this.subtitle,
    required this.subtitleAr,
    required this.accent,
    required this.accentSoft,
    required this.moods,
  });
}