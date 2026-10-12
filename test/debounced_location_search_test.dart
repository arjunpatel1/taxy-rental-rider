import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_booking/utils/DebouncedLocationSearch.dart';

void main() {
  testWidgets('typing a burst sends only its final address query',
      (tester) async {
    final requests = <String>[];
    final results = <String?>[];
    final search = DebouncedLocationSearch<String>(
        fetch: (q) async {
          requests.add(q);
          return q;
        },
        onResult: results.add);
    search.update('Dew');
    search.update('Dewas');
    search.update('Dewas station');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(requests, ['Dewas station']);
    expect(results.last, 'Dewas station');
    search.dispose();
  });
  testWidgets('a late pickup response cannot overwrite newer drop suggestions',
      (tester) async {
    final old = Completer<String>();
    final latest = Completer<String>();
    final results = <String?>[];
    final search = DebouncedLocationSearch<String>(
        fetch: (q) => q == 'pickup' ? old.future : latest.future,
        onResult: results.add);
    search.update('pickup');
    await tester.pump(const Duration(milliseconds: 350));
    search.update('drop');
    await tester.pump(const Duration(milliseconds: 350));
    latest.complete('correct drop');
    await tester.pump();
    old.complete('stale pickup');
    await tester.pump();
    expect(results.last, 'correct drop');
    expect(results, isNot(contains('stale pickup')));
    search.dispose();
  });
  testWidgets('clearing invalidates an in-flight response', (tester) async {
    final pending = Completer<String>();
    final results = <String?>[];
    final search = DebouncedLocationSearch<String>(
        fetch: (_) => pending.future, onResult: results.add);
    search.update('address');
    await tester.pump(const Duration(milliseconds: 350));
    search.update('');
    pending.complete('old address');
    await tester.pump();
    expect(results.last, isNull);
    expect(results, isNot(contains('old address')));
    search.dispose();
  });
  testWidgets('disposal prevents delayed results and queued requests',
      (tester) async {
    final pending = Completer<String>();
    final results = <String?>[];
    var calls = 0;
    final search = DebouncedLocationSearch<String>(
        fetch: (_) {
          calls++;
          return pending.future;
        },
        onResult: results.add);
    search.update('address');
    await tester.pump(const Duration(milliseconds: 350));
    search.dispose();
    pending.complete('late');
    await tester.pump();
    search.update('another');
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    expect(results, isNot(contains('late')));
  });
}
