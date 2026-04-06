// lib/occasions/newbaby.dart

import 'package:flutter/material.dart';
import '../core/occasion.dart';

final Occasion newbabyOccasion = Occasion(
  id: 'newbaby',
  emoji: '👶',
  name: 'Naissance',
  nameAr: 'مولود جديد',
  subtitle: 'Bienvenue à ce petit miracle',
  subtitleAr: 'مرحبا بالمولود الجديد',
  accent: const Color(0xFF7DC4A0),        // Vert doux et tendre (vie, espoir, fraîcheur)
  accentSoft: const Color(0x337DC4A0),
  moods: [
    // Mood 1 : Doux & Tendre
    MoodTemplate(
      label: 'DOUX',
      labelAr: 'رقيق',
      emoji: '🌱',
      text: (n) => n.isEmpty
          ? "روح جديدة ونور جديد دخل الدنيا...\nUn petit être précieux est arrivé. Bienvenue parmi nous 🌱"
          : "مرحبا بيك يا $n 💚\nBienvenue au monde, toi qui es déjà tellement aimé·e avant même de savoir parler.",
    ),

    // Mood 2 : Joyeux & Célébration
    MoodTemplate(
      label: 'JOYEUX',
      labelAr: 'فرحان',
      emoji: '🎀',
      text: (n) => n.isEmpty
          ? "أغلى هدية وصلات للدنيا.\nLe plus beau des cadeaux est arrivé. مبروك للوالدين وللعائلة 🎀"
          : "يا $n، الدنيا كانت تستناك بدون ما تعرف...\nQuelle joie immense tu apportes avec toi ! Ton arrivée est une bénédiction ✨",
    ),

    // Mood 3 : Profond & Émotionnel
    MoodTemplate(
      label: 'PROFOND',
      labelAr: 'عميق',
      emoji: '✨',
      text: (n) => n.isEmpty
          ? "في هاد الكيان الصغير كاين حلام كبيرة بزاف.\nDes rêves infinis habitent déjà ce petit être extraordinaire ✨"
          : "$n، جيتي لعالم محتاج لنورك.\nGrandis libre, heureux·se, entouré·e d’amour et de paix infinie 💫",
    ),
  ],
);