import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_booking/components/WalletBalanceCard.dart';
import 'package:taxi_booking/utils/BrandTheme.dart';

void main() {
  for (final width in [320.0, 360.0, 800.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Wallet balance and action fit width $width, text scale $scale', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var tapped = false;
        await tester.pumpWidget(MaterialApp(theme: BrandTheme.light(), home: Scaffold(
          body: MediaQuery(data: MediaQueryData(size: Size(width, 1000), textScaler: TextScaler.linear(scale)),
            child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: WalletBalanceCard(
              title: 'Available wallet balance for your account',
              amount: const Text('₹ 1234567890.85', style: TextStyle(fontSize: 26, color: Colors.white)),
              onAddMoney: () => tapped = true,
            ))),
        )));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('₹ 1234567890.85'), findsOneWidget);
        await tester.tap(find.text('Add money'));
        expect(tapped, isTrue);
      });
    }
  }
}
