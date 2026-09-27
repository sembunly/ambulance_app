import 'package:ambulance_app/main.dart';
import 'package:ambulance_app/app/dependency_injection.dart';
import 'package:ambulance_app/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('app opens the login route', (tester) async {
    DependencyInjection.init();
    await tester.pumpWidget(
      const AmbulanceApp(initialRoute: Routes.AUTHENTICATION),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginScreen')), findsOneWidget);
    expect(find.byKey(const Key('phoneNumberField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
  });
}
