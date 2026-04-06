// lib/occasions/success.dart

import 'package:flutter/material.dart';
import '../core/occasion.dart';

final Occasion successOccasion = Occasion(
  id: 'success',
  emoji: '🏆',
  name: 'Réussite',
  nameAr: 'نجاح',
  subtitle: 'Célébrer le fruit de tes efforts',
  subtitleAr: 'احتفال بثمرة تعبك',
  accent: const Color(0xFFB87333),        // Or cuivré / Bronze chaud et victorieux
  accentSoft: const Color(0x33B87333),
  moods: [
    // Mood 1 : Fier & Reconnaissant
    MoodTemplate(
      label: 'FIER',
      labelAr: 'فخور',
      emoji: '🎖️',
      text: (n) => n.isEmpty
          ? "مبروك النجاح!\nLe travail, la persévérance et la foi finissent toujours par payer 🏆"
          : "مبروك يا $n!\nTu as prouvé ce que je savais depuis longtemps : tu es exceptionnel·le et capable de grandes choses.",
    ),

    // Mood 2 : Inspirant & Motivational
    MoodTemplate(
      label: 'INSPIRANT',
      labelAr: 'ملهم',
      emoji: '🚀',
      text: (n) => n.isEmpty
          ? "النجاح الكبير ديال اللي ما وقفوش يصدقو في أحلامهم.\nContinue à viser les étoiles, le ciel n’est pas la limite 🚀"
          : "$n، كل عقبة كانت تقربك من هنا.\nChaque difficulté t’a mené jusqu’à cette victoire. Bravo, tu l’as mérité !",
    ),

    // Mood 3 : Chaleureux & Émotionnel
    MoodTemplate(
      label: 'CHALEUREUX',
      labelAr: 'حنون',
      emoji: '🌟',
      text: (n) => n.isEmpty
          ? "هاد النجاح مستاهل فيه بزاف.\nCette victoire, tu la mérites cent fois. Je suis tellement fier·e de toi 🌟"
          : "$n، نجاحك يفرحني من أعماق قلبي.\nTon succès me remplit de joie et d’admiration. Continue à briller !",
    ),
  ],
);