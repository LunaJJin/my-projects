import 'package:flutter_test/flutter_test.dart';
import 'package:lotto_app/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LottoApp());
    expect(find.text('로또번호 추출기'), findsOneWidget);
  });
}
