// lib/occasions/gratitude.dart

import 'package:flutter/material.dart';
import '../core/occasion.dart';

final Occasion gratitudeOccasion = Occasion(
  id: 'gratitude',
  emoji: '🙏',
  name: 'Gratitude',
  nameAr: 'الامتنان',
  subtitle: 'Remercier du fond du cœur',
  subtitleAr: 'شكراً من أعماق القلب',
  accent: const Color(0xFF9B7EC8),        // Violet doux et chaleureux
  accentSoft: const Color(0x339B7EC8),
  moods: [
    // Mood 1 : Sincère & Simple
    MoodTemplate(
      label: 'SINCÈRE',
      labelAr: 'صادق',
      emoji: '💜',
      text: (n) => n.isEmpty
          ? "كاين ناس كيبدلو حياتك بمجرد ما يكونو فيها...\nشكراً على وجودك 🙏"
          : "$n، الكلمات ما تكفيش باش نعبر على قيمتك عندي.\nMerci d’exister, merci d’être exactement qui tu es 💖",
    ),

    // Mood 2 : Profond & Émotionnel
    MoodTemplate(
      label: 'PROFOND',
      labelAr: 'عميق',
      emoji: '🌙',
      text: (n) => n.isEmpty
          ? "شكراً على كل شيء...\nMerci pour tout ce que tu fais sans jamais rien attendre 🌙"
          : "$n، شكراً باش تكون أنت.\nMerci d’être cette personne lumineuse qui rend le monde plus beau ✨",
    ),

    // Mood 3 : Lumineux & Chaleureux
    MoodTemplate(
      label: 'LUMINEUX',
      labelAr: 'مضيء',
      emoji: '🌤️',
      text: (n) => n.isEmpty
          ? "كرمك كيضوي كل شيء من حواليك.\nTa générosité illumine tout autour de toi ✨"
          : "$n، كل مرة نحتاج ليك كنتي هنا.\nJe n’oublierai jamais ta présence et ton soutien. Merci du fond du cœur 💛",
    ),
  ],
);