import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/services/stripe_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe (only works on mobile)
  await initializeStripe();

  runApp(const ProviderScope(child: ServisKuApp()));
}

class ServisKuApp extends ConsumerWidget {
  const ServisKuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final app = MaterialApp.router(
      title: 'ServisKu',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        // Add localization delegates for Malay/English
      ],
      supportedLocales: const [
        Locale('en', 'MY'),
        Locale('ms', 'MY'),
      ],
    );

    // Constrain width on web to look like mobile app
    if (kIsWeb) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              child: app,
            ),
          ),
        ),
      );
    }

    return app;
  }
}
