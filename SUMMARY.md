## Objective
- Rendre les 4 pages (Sound Capsule, Settings & Storage, Language, About) 100 % fonctionnelles et persistées dans Tunefy (Muzo-v4), en reproduisant Hivefy, reliées aux services existants, puis build + install + vérification sur téléphone.

## Important Details
- Utilisateur parle français, répondre en français.
- App installée et lancée sans crash sur 192.168.1.104:46099. Activity réelle : com.shashwat.ytx.MainActivity.
- adb : C:\Users\grand\Android\Sdk\platform-tools\adb.exe ; APK release C:\flutter\s_potify\Muzo-v4\build\app\outputs\flutter-apk\app-release.apk ; build Gradle OK.
- Couleurs Hivefy : hivefyBg = 0xFF121212, hivefyGreen = 0xFF1DDA63. assets/hivefy_icon.png = vrai logo ; assets/hivefy_logo.png = HTML corrompu à ne pas utiliser.
- Repo Hivefy source : C:\Users\grand\AppData\Local\Temp\opencode\hivefy.
- share_plus v10.1.4 → API Share.shareXFiles([XFile...], text:, subject:).
- L'appareil est un téléphone réel en usage : ne pas envoyer de taps automatiques pendant que l'utilisateur l'utilise. Vérifier via uiautomator dump + logcat, pas par interaction continue.
- L'app sur le device est en FRANÇAIS (appLanguage persisté = fr) : les écrans localisés (Settings, About, Sound Capsule) s'affichent en français.

## Work State
### Completed
- BUG CORRIGÉ : "le settings est vide" (session actuelle).
  - Cause : settings_screen.dart : _buildAvatar faisait storage.username![0] → en mode invité username==null → exception "Null check operator used on a null value" pendant le build → l'écran Settings & Storage s'affichait entièrement vide.
  - Correctif : garde null-safe (storage.username == null || storage.username!.isEmpty) ? 'U' : storage.username![0]....
  - Vérifié : flutter analyze OK, build apk --release OK, install -r Success, relance → Settings & Storage affiche toutes les sections (Cache, Notifications, Confidentialité, ...) sans exception (logcat sans Null check / E/flutter).
  - Vérifié aussi : about_screen.dart ligne 226 storage.username! est bien protégé par if (storage.username != null) (ligne 224) → pas de bug.
- CORRECTION précédente : hivefy_drawer.dart "Tunefy v1.0.0" → "Tunefy v3.9.0" (cohérence pubspec/About).
- Fonctionnalités déjà implémentées (sessions précédentes) :
  - lib/utils/format.dart ; listening_stats_service.dart (statsListenable) ; storage_service.dart (getters/setters persistés + clearDownloads/clearHistory/downloadsTotalBytes).
  - Sound Capsule réécrit (top 5/10/50, stats, activités, sections, carte partageable RepaintBoundary, Download PNG + Share, état vide si totalSongs==0).
  - Settings & Storage réécrit (ConsumerStatefulWidget, SliverAppBar, sections Account/Appearance/Audio Quality/Playback/Downloads/Cache/Notifications/Privacy/Security).
  - Language réécrit (recherche, 90+ langues, changement instantané localeProvider + persistance).
  - About réécrit (version 3.9.0, dev Grandel AGBANOU (GradenX), socials, email, support, updates, licenses).
  - main.dart branché locales ; flutter analyze lib/ : aucune erreur.

### Active
- Rien en cours.

### Blocked
- Aucun. Vérifications on-device de Sound Capsule/About OK précédemment ; Settings vérifié après fix.

## Next Move
1. Laisser l'app à l'utilisateur pour confirmer visuellement.
2. "(none)"

## Anomalie résolue (précédente)
- Tooltip back "Enrere" (catalan) : expliqué par un appLanguage persisté différent ; l'app est désormais en français, back tooltip = "Retour". Cosmétique, géré par l'écran Language.

## Relevant Files
- C:\flutter\s_potify\Muzo-v4\lib\screens\settings_screen.dart (fix null-check avatar)
- C:\flutter\s_potify\Muzo-v4\lib\widgets\hivefy_drawer.dart (v3.9.0)
- C:\flutter\s_potify\Muzo-v4\lib\screens\features\sound_capsule_screen.dart
- C:\flutter\s_potify\Muzo-v4\lib\screens\features\language_screen.dart
- C:\flutter\s_potify\Muzo-v4\lib\screens\features\about_screen.dart
- C:\flutter\s_potify\Muzo-v4\lib\main.dart
- C:\flutter\s_potify\Muzo-v4\lib\services\storage_service.dart
- C:\flutter\s_potify\Muzo-v4\build\app\outputs\flutter-apk\app-release.apk
