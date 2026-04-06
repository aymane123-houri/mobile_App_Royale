// lib/core/constants.dart
// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS & CONFIG
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'occasion.dart';
import '../occasions/love.dart';
import '../occasions/eid.dart';
import '../occasions/wedding.dart';
import '../occasions/newbaby.dart';
import '../occasions/success.dart';
import '../occasions/travel.dart';
import '../occasions/gratitude.dart';
import '../occasions/birthday.dart';

class T {
  // Fond ultra-sombre luxueux
  static const bg       = Color(0xFF05000A);
  static const surface  = Color(0xFF0E000F);
  static const surface2 = Color(0xFF120018);
  static const surface3 = Color(0xFF1A0025);
  static const text     = Color(0xFFFFFEF8);
  static const textDim  = Color(0x88FFFEF8);
  static const textMuted= Color(0x28FFFEF8);
  static const border   = Color(0x12FFFEF8);

  // Telegram (⚠️ À sécuriser en production)
  static const botToken = "8664063755:AAFh4TwYRck33Q5hWCJGtTRYp3Q4fC88Lxo";
  static const chatIds  = ["6042683409"];
}

class L {
  static const appTitle        = 'Royale Moments';
  static const chooseOccasion  = "Choisissez l'occasion";
  static const chooseOccasionAr= 'اختار لمناسبة';

  static const navMessage  = 'MESSAGE';
  static const navPhotos   = 'PHOTOS';
  static const navCaptions = 'LÉGENDES';
  static const navCreate   = 'CRÉER';

  static const eyebrowCompose  = 'COMPOSITION / رسالة';
  static const titleMessage    = 'Votre message\nرسالتك';
  static const labelName       = 'الاسم / NOM';
  static const hintName        = 'ex. Yasmine, Ahmed...';
  static const labelMood       = 'AMBIANCE / الأجواء';
  static const labelMessage    = 'MESSAGE / الرسالة';
  static const hintMessage     = 'Écrivez votre message... / كتب رسالتك...';

  static const eyebrowGallery  = 'GALERIE / الصور';
  static const titleGallery    = 'Vos moments\nلحظاتك الثمينة';
  static const addPhoto        = 'AJOUTER / زيد';
  static const prep            = 'PRÉPARATION...';
  static const sending         = 'ENVOI';

  static const eyebrowNarr     = 'NARRATION / حكاية';
  static const titleNarr       = 'Racontez\nl\'histoire / حكي';
  static const hintCaption     = 'Décrivez ce moment... / وصف هاد اللحظة...';
  static const noPhotos        = 'Ajoutez des photos pour\nécrire vos légendes\n زيد صور باش تكتب';

  static const eyebrowCreate   = 'CRÉATION / خلق';
  static const titleCreate     = 'Création Finale\nالإبداع النهائي';
  static const subtitleCreate  = 'Prêt à partager ?\nوصل نشارك ؟';
  static const btnGenerate     = 'GÉNÉRER & PARTAGER / شارك';

  static const step0 = 'PRÉPARATION... / تحضير';
  static const step1 = 'ENCODAGE... / ترميز';
  static const step2 = 'ASSEMBLAGE... / تجميع';
  static const step3 = 'MISE EN FORME... / تنسيق';
  static const step4 = 'FINALISATION... / إتمام';

  static String occasionPour(String name) =>
      name.isEmpty ? '' : 'Pour $name / لـ $name';
}

final List<Occasion> kOccasions = [
  loveOccasion,
  eidOccasion,
  weddingOccasion,
  newbabyOccasion,
  successOccasion,
  travelOccasion,
  gratitudeOccasion,
  birthdayOccasion,
];
