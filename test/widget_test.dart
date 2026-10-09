import 'package:flutter_test/flutter_test.dart';
import 'package:proyek_motomanager_3/main.dart';

void main() {
  testWidgets('MotoManage App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MotoManageApp());

    // Verify that login title is displayed.
    expect(find.text('MotoManage'), findsOneWidget);
    expect(find.text('Masuk ke Sistem'), findsOneWidget);
  });
}
