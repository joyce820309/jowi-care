import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/home/home_shell.dart';
import 'providers/locale_provider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await NotificationService.instance.init();

  runApp(const ProviderScope(child: JowiCareApp()));
}

class JowiCareApp extends ConsumerStatefulWidget {
  const JowiCareApp({super.key});

  @override
  ConsumerState<JowiCareApp> createState() => _JowiCareAppState();
}

class _JowiCareAppState extends ConsumerState<JowiCareApp> {
  AppThemeMode _themeMode = AppThemeMode.warmSand;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == AppThemeMode.warmSand
          ? AppThemeMode.mistBlue
          : AppThemeMode.warmSand;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Jowi Care',
      theme: getTheme(_themeMode),
      locale: locale,
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomeShell(onToggleTheme: _toggleTheme),
    );
  }
}
