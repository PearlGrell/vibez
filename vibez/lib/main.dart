import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/network/api_client.dart';
import 'package:vibez/core/network/socket_client.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/core/theme/theme.dart';
import 'package:vibez/data/services/player_audio_service.dart';
import 'package:vibez/data/services/download_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await ApiClient.instance.init();
  await DownloadService.init();

  final container = ProviderContainer();

  await PlayerAudioService.init(container);
  SocketClient.instance.initialize().catchError((Object err) {
    debugPrint('Socket initialize failed: $err');
  });

  runApp(UncontrolledProviderScope(container: container, child: const Vibez()));
}

class Vibez extends StatelessWidget {
  const Vibez({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.instance.router,
      scaffoldMessengerKey: AppSnackbar.messengerKey,
    );
  }
}
