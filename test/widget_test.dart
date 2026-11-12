import 'package:cloud_quest/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Cloud Quest sign-in prompt', (tester) async {
    await tester.pumpWidget(const CloudQuestApp());

    expect(find.text('Cloud Quest'), findsOneWidget);
    expect(find.text('Sign in to start your quest.'), findsOneWidget);
  });
}