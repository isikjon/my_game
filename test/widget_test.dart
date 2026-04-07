import 'package:flutter_test/flutter_test.dart';
import 'package:svoya_igra/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ViktorinaApp());
  });
}
