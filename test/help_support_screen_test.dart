import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_booking/main.dart';
import 'package:taxi_booking/model/SettingModel.dart';
import 'package:taxi_booking/screens/HelpSupportScreen.dart';

void main() {
  testWidgets('support uses configured contacts and remains scrollable on a small display', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appStore.settingModel = SettingModel.fromJson({
      'contact_number': '+919000000001', 'contact_email': 'help@example.test',
      'office_address': 'A long company address ' * 20,
    });
    await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('+919000000001'), findsNWidgets(2));
    expect(find.text('help@example.test'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Company Address'), 100);
    await tester.pumpAndSettle();
    expect(find.text('Company Address'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing support settings do not open empty links', (tester) async {
    appStore.settingModel = SettingModel();
    await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));
    for (final tile in tester.widgetList<ListTile>(find.byType(ListTile))) {
      expect(tile.onTap, isNull);
    }
    expect(tester.takeException(), isNull);
  });
}
