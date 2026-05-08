import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'settings_provider.dart';
import 'sounds_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final settings = await SettingsProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => SoundsProvider()),
      ],
      child: const MemeApp(),
    ),
  );
}

final _lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6C63FF),
    brightness: Brightness.light,
  ),
  useMaterial3: true,
);

final _darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6C63FF),
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
);

class MemeApp extends StatelessWidget {
  const MemeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Meme',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('he'), Locale('en')],
      locale: const Locale('he'),
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: Duration.zero,
      home: const ThemeTransitionWrapper(),
    );
  }
}

class ThemeTransitionWrapper extends StatefulWidget {
  const ThemeTransitionWrapper({super.key});

  @override
  State<ThemeTransitionWrapper> createState() => _ThemeTransitionWrapperState();
}

class _ThemeTransitionWrapperState extends State<ThemeTransitionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  bool? _lastIsDark;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = context.watch<SettingsProvider>().isDarkMode;
    if (_lastIsDark != null && _lastIsDark != isDark) {
      _controller.forward(from: 0.0);
    }
    _lastIsDark = isDark;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeScreen(),
        AnimatedBuilder(
          animation: _opacity,
          builder: (context, _) {
            if (_opacity.value == 0) return const SizedBox.shrink();
            final isDark = context.read<SettingsProvider>().isDarkMode;
            return IgnorePointer(
              child: Opacity(
                opacity: (1.0 - _opacity.value).clamp(0.0, 0.6),
                child: Container(color: isDark ? Colors.black : Colors.white),
              ),
            );
          },
        ),
      ],
    );
  }
}
