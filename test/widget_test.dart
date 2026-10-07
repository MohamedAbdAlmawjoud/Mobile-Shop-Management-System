import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_shop_management_system/main.dart';

void main() {
  testWidgets('app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MobileShopApp()));

    expect(find.text('Mobile Shop'), findsOneWidget);
  });
}
