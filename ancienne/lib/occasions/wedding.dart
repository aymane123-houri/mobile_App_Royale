// lib/occasions/wedding.dart

import 'package:flutter/material.dart';
import '../core/occasion.dart';

final Occasion weddingOccasion = Occasion(
  id: 'wedding',
  emoji: '💍',
  name: 'Mariage',
  nameAr: 'زواج / عرس',
  subtitle: 'Union sacrée et célébration de l’amour',
  subtitleAr: 'اتحاد مقدس واحتفال بالحب',
  accent: const Color(0xFFC0A46A),        // Or champagne / doré chaleureux et raffiné
  accentSoft: const Color(0x33C0A46A),
  moods: [
    // Mood 1 : Élégant & Solennel
    MoodTemplate(
      label: 'ÉLÉGANT',
      labelAr: 'راقي',
      emoji: '🕊️',
      text: (n) => n.isEmpty
          ? "مبروك الزواج!\nQue votre union soit éternelle, votre amour indestructible et votre vie remplie de bonheur 💍"
          : "مبروك يا $n!\nQue cet amour soit le fondement d’une vie exceptionnelle, pleine de tendresse et de complicité ✨",
    ),

    // Mood 2 : Poétique & Romantique
    MoodTemplate(
      label: 'POÉTIQUE',
      labelAr: 'شعري',
      emoji: '🌿',
      text: (n) => n.isEmpty
          ? "جوج أرواح وطريق واحد...\nDeux âmes, un seul chemin illuminé de lumière et de tendresse 🌿"
          : "$n، لقيتو فبعضكم ما قلة منو إيجادو.\nVous avez trouvé un amour rare, vrai et profond. Que Dieu bénisse votre union 💞",
    ),

    // Mood 3 : Chaleureux & Émotionnel
    MoodTemplate(
      label: 'CHALEUREUX',
      labelAr: 'حنون',
      emoji: '💛',
      text: (n) => n.isEmpty
          ? "هاد اللحظة هي بداية أجمل المغامرات.\nTout mon amour et mes prières vous accompagnent dans cette nouvelle vie 💛"
          : "يا $n، كل نهار يكون سبب جديد باش تحبو بعضكم أكثر.\nQue chaque jour renforce votre amour et votre bonheur mutuel 🌹",
    ),
  ],
);