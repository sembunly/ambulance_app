import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/dependency_injection.dart';
import 'app/language/app_translations.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  DependencyInjection.init();

  runApp(
    AmbulanceApp(
      initialLocale: AppTranslations.localeFor(
        preferences.getString('language') ?? 'en',
      ),
    ),
  );
}

class AmbulanceApp extends StatelessWidget {
  const AmbulanceApp({
    super.key,
    this.initialRoute = AppPages.initial,
    this.initialLocale = AppTranslations.english,
  });

  final String initialRoute;
  final Locale initialLocale;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ambulance',
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: AppTranslations.english,
    );
  }
}
