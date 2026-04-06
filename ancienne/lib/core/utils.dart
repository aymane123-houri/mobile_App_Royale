// lib/core/utils.dart

import 'package:flutter/material.dart';
import 'constants.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget réutilisable pour les headers de pages
Widget pageHeader(String eyebrow, String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: GoogleFonts.cinzel(
          fontSize: 8,
          letterSpacing: 4,
          color: T.text.withOpacity(0.3),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        title,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 30,
          fontWeight: FontWeight.w300,
          height: 1.15,
          color: T.text,
        ),
      ),
      const SizedBox(height: 6),
      const _Divider(),
      const SizedBox(height: 24),
    ],
  );
}

/// Widget réutilisable pour les labels de champs
Widget fieldLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.cinzel(
        fontSize: 8,
        letterSpacing: 3,
        color: T.textMuted,
      ),
    ),
  );
}

/// Divider décoratif avec étoile
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, T.border],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "✦",
            style: TextStyle(color: T.border, fontSize: 10),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [T.border, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Peintre pour l'arrière-plan avec gradient subtil
class BgPainter extends CustomPainter {
  final Color accent;

  const BgPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.5, -0.7),
          radius: 1.0,
          colors: [
            accent.withOpacity(0.07),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(BgPainter oldDelegate) => oldDelegate.accent != accent;
}