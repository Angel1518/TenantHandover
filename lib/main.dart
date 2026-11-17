import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/tenant/ui/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TenantHandoverApp()));
}

class TenantHandoverApp extends ConsumerWidget {
  const TenantHandoverApp({super.key});

  static const Color accentTeal = Color(0xFF0F766E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'TenantHandover',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accentTeal),
      darkTheme: AppTheme.dark(accent: accentTeal),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
