// lib/core/utils.dart
// ═══════════════════════════════════════════════════════════════
//  UTILS — Widgets partagés, helpers visuels
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';

// ── pageHeader global
Widget pageHeader(String eyebrow, String title, {Color? accent}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(eyebrow, style: GoogleFonts.cinzel(fontSize: 8, letterSpacing: 5, color: Colors.white.withOpacity(0.2))),
      const SizedBox(height: 8),
      ...title.split('\n').map((line) => Text(line,
        style: GoogleFonts.cormorantGaramond(fontSize: 34, fontWeight: FontWeight.w300, height: 1.1, color: Colors.white))),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Container(height: 0.5,
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white10])))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('✦', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10))),
        Expanded(child: Container(height: 0.5,
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.white10, Colors.transparent])))),
      ]),
      const SizedBox(height: 4),
    ],
  );
}

// ── fieldLabel global
Widget fieldLabel(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Text(t, style: GoogleFonts.cinzel(fontSize: 7.5, letterSpacing: 3, color: Colors.white.withOpacity(0.2))),
);

// ── BgPainter (compatible avec l'ancien code)
class BgPainter extends CustomPainter {
  final Color accent;
  const BgPainter(this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF05000A));
    canvas.drawCircle(
      Offset(-size.width * 0.1, -size.height * 0.05),
      size.width * 0.8,
      Paint()..shader = RadialGradient(
        colors: [accent.withOpacity(0.07), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(-size.width * 0.1, -size.height * 0.05), radius: size.width * 0.8)),
    );
  }
  @override
  bool shouldRepaint(BgPainter old) => old.accent != accent;
}
