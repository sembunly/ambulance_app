import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'en.dart';
import 'kh.dart';

class AppTranslations extends Translations {
  static const english = Locale('en', 'US');
  static const khmer = Locale('km', 'KH');

  static Locale localeFor(String language) =>
      language == 'km' ? khmer : english;

  @override
  Map<String, Map<String, String>> get keys => {'en_US': en, 'km_KH': kh};

  static String displayValue(String value) {
    for (final entry in en.entries) {
      if (entry.value == value) return entry.key.tr;
    }
    final minutes = RegExp(r'^(\d+) min$').firstMatch(value);
    if (minutes != null) {
      return 'MINUTES'.trParams({'count': minutes.group(1)!});
    }
    return value;
  }
}
