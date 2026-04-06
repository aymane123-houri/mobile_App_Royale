// lib/occasions/love.dart

import 'package:flutter/material.dart';
import '../core/occasion.dart';

final Occasion loveOccasion = Occasion(
  id: 'love',
  emoji: '💌',
  name: 'Déclaration',
  nameAr: 'إعلان حب',
  subtitle: 'Dire ce que le cœur ressent',
  subtitleAr: 'قول اللي في قلبك',
  accent: const Color(0xFFD44F7A),        // Rose rouge passionné et élégant
  accentSoft: const Color(0x33D44F7A),
  moods: [
    // Mood 1 : Doux & Tendre
    MoodTemplate(
      label: 'DOUX',
      labelAr: 'رقيق',
      emoji: '🌸',
      text: (n) => n.isEmpty
          ? "Il y a des personnes qui entrent dans notre vie et la transforment pour toujours...\nكاين ناس كيبدلو حياتك بمجرد ما يدخلوها 🌸"
          : "$n، أنت واحدة من هاد الناس.\nTu es devenu·e une partie de moi que je ne veux plus jamais perdre 💕",
    ),

    // Mood 2 : Romantique & Poétique
    MoodTemplate(
      label: 'ROMANTIQUE',
      labelAr: 'رومانسي',
      emoji: '🌹',
      text: (n) => n.isEmpty
          ? "Chaque fois que tu souris, j’oublie le reste du monde.\nكل مرة كتبتسم كنسى كل شيء 💗"
          : "يا $n، في جميع الأكوان الموازية كنختارك دائما.\nDans tous les univers parallèles, je te choisirais encore et encore ✨",
    ),

    // Mood 3 : Ardent & Passionné
    MoodTemplate(
      label: 'ARDENT',
      labelAr: 'عميق',
      emoji: '💘',
      text: (n) => n.isEmpty
          ? "Tu occupes chaque pensée, chaque rêve, chaque battement de cœur.\nكتملي كل فكرة وكل حلم، كنبغيك بجدية كبيرة 🔥"
          : "$n، أنت النار اللي ما غادي نحاول عمري نطفيها.\nJe t’aime profondément, sincèrement et pour toujours 💞",
    ),
  ],
);