// lib/occasions/birthday.dart

import 'package:flutter/material.dart';
import '../core/occasion.dart';

final Occasion birthdayOccasion = Occasion(
  id: 'birthday',
  emoji: '🎂',
  name: 'Anniversaire',
  nameAr: 'عيد الميلاد',
  subtitle: 'Une journée magique à célébrer',
  subtitleAr: 'يوم سحري يستحق الاحتفال',
  accent: const Color(0xFFE8A838),        // Or chaud luxueux
  accentSoft: const Color(0x33E8A838),    // Or très doux
  moods: [
    // Mood 1 : Joyeux & Festif
    MoodTemplate(
      label: 'JOYEUX',
      labelAr: 'فرحان',
      emoji: '🎉',
      text: (n) => n.isEmpty
          ? "Que cette journée brille autant que ton sourire !\nعيد ميلاد سعيد وكل عام وأنت أجمل ✨"
          : "Joyeux anniversaire $n ! 🎂\nعيد ميلاد سعيد يا $n — que chaque instant soit rempli de joie pure et de magie ✨",
    ),

    // Mood 2 : Touchant & Émotionnel
    MoodTemplate(
      label: 'TOUCHANT',
      labelAr: 'من القلب',
      emoji: '🥹',
      text: (n) => n.isEmpty
          ? "Une année de plus remplie de beauté et de grâce.\nكل سنة وأنت بخير يا غالي 💛"
          : "$n، كل سنة وأنت بألف خير.\nChaque année qui passe révèle encore plus la personne extraordinaire et lumineuse que tu es 💖",
    ),

    // Mood 3 : Ardent & Profond
    MoodTemplate(
      label: 'ARDENT',
      labelAr: 'من الأعماق',
      emoji: '🔥',
      text: (n) => n.isEmpty
          ? "Le monde est plus beau depuis le jour où tu es né·e.\nالدنيا أجمل بوجودك 🌹"
          : "$n، أنت الشخص الذي يجعل يومي أجمل.\nTu es ma personne préférée sur cette terre, aujourd’hui et pour toujours 💫",
    ),
  ],
);