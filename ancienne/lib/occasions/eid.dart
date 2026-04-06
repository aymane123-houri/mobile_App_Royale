// lib/occasions/eid.dart

import 'package:flutter/material.dart';
import '../core/occasion.dart';

final Occasion eidOccasion = Occasion(
  id: 'eid',
  emoji: '🌙',
  name: 'Aïd Mubarak',
  nameAr: 'عيد مبارك',
  subtitle: 'Fête de joie, paix et bénédictions',
  subtitleAr: 'عيد الفرح والسلام والبركات',
  accent: const Color(0xFF5B9EBF),        // Bleu doux et élégant (lune + ciel nocturne)
  accentSoft: const Color(0x335B9EBF),
  moods: [
    // Mood 1 : Sincère & Spirituel
    MoodTemplate(
      label: 'SINCÈRE',
      labelAr: 'صادق',
      emoji: '🤲',
      text: (n) => n.isEmpty
          ? "عيد مبارك\nQue la paix, la lumière et la baraka remplissent ta maison et ton cœur 🕌"
          : "عيد مبارك يا $n !\nكل عام وأنت بألف خير — Que ce jour béni t’apporte bonheur, santé et toutes les bénédictions du ciel ✨",
    ),

    // Mood 2 : Romantique & Poétique
    MoodTemplate(
      label: 'ROMANTIQUE',
      labelAr: 'رومانسي',
      emoji: '🌙',
      text: (n) => n.isEmpty
          ? "هذا العيد يضيء قلبك كما يضيء القمر الليل.\nQue cet Aïd illumine ton cœur de douceur et de sérénité 🌙"
          : "يا $n، أنت أجمل هدية في هذا العيد.\nTu es ma plus belle bénédiction, aujourd’hui et toujours 💫",
    ),

    // Mood 3 : Passionné & Chaleureux
    MoodTemplate(
      label: 'PASSIONNÉ',
      labelAr: 'متحمس',
      emoji: '⭐',
      text: (n) => n.isEmpty
          ? "هذا العيد أجمل بوجودك.\nCette fête est plus belle parce que tu existes ⭐"
          : "$n، في هذا العيد ما أتمنى غير سعادتك وراحتك.\nJe ne veux que ton bonheur et ta paix intérieure 🌟",
    ),
  ],
);