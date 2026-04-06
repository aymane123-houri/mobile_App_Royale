// lib/occasions/travel.dart

import 'package:flutter/material.dart';
import '../core/occasion.dart';

final Occasion travelOccasion = Occasion(
  id: 'travel',
  emoji: '✈️',
  name: 'Voyage',
  nameAr: 'رحلة / سفر',
  subtitle: 'Aventure, découverte et liberté',
  subtitleAr: 'مغامرة واكتشاف وحرية',
  accent: const Color(0xFF4A90C4),        // Bleu océan / ciel — frais et aventureux
  accentSoft: const Color(0x334A90C4),
  moods: [
    // Mood 1 : Aventurier & Dynamique
    MoodTemplate(
      label: 'AVENTURIER',
      labelAr: 'مغامر',
      emoji: '🧭',
      text: (n) => n.isEmpty
          ? "الدنيا كبيرة وزينة بزاف...\nQue ce voyage soit le début d’une belle et grande histoire 🌍"
          : "$n، تمنالك رحلة تملا القلب وتكحل العينين.\nBon voyage ! Que chaque destination t’apporte joie et émerveillement 🗺️",
    ),

    // Mood 2 : Poétique & Rêveur
    MoodTemplate(
      label: 'POÉTIQUE',
      labelAr: 'شعري',
      emoji: '🌍',
      text: (n) => n.isEmpty
          ? "المشي كيولدك من جديد...\nPartir, c’est naître un peu. Que ce voyage te transforme et t’inspire 🌏"
          : "$n، أجمل الذكريات هي اللي ما خططتيلهاش.\nVis chaque instant pleinement, sans rien prévoir. L’aventure t’attend ✨",
    ),

    // Mood 3 : Tendre & Émotionnel
    MoodTemplate(
      label: 'TENDRE',
      labelAr: 'حنون',
      emoji: '💫',
      text: (n) => n.isEmpty
          ? "أينما مشيتي، حمل معاك حب الناس اللي كيحبوك.\nPorte avec toi tout cet amour partout où tu iras 💙"
          : "يا $n، راح تبان لينا بحال ما بعدتيش.\nReviens avec des étoiles plein les yeux et des histoires plein le cœur 🌟",
    ),
  ],
);