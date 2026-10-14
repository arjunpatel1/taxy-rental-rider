import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_booking/components/LocalTripLimitView.dart';
import 'package:taxi_booking/model/EstimatePriceModel.dart';

void main() {
  test('distance-limit response stays distinct from unavailable pickup', () {
    final limit = EstimatePriceModel.fromJson({'data': [], 'outside_city': true,
      'code': 'local_distance_limit', 'message': 'Choose outstation'});
    expect(limit.outsideCity, isTrue);
    expect(EstimatePriceModel.fromJson({'data': []}).outsideCity, isFalse);
  });
  testWidgets('limit card offers outstation and change drop on small display', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var outstation = 0;
    var change = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: LocalTripLimitView(onOutstation: () => outstation++, onChangeDrop: () => change++)))));
    expect(find.text('Book Outstation Instead'), findsOneWidget);
    await tester.tap(find.text('Continue as Outstation'));
    await tester.tap(find.text('Change Drop'));
    expect(outstation, 1);
    expect(change, 1);
    expect(find.textContaining('not available'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
