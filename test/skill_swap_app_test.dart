import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/main.dart';

void main() {
  testWidgets('mostra un messaggio descrittivo quando l\'inizializzazione fallisce', (tester) async {
    await tester.pumpWidget(
      const SkillSwapApp(initializationError: 'Errore durante l\'inizializzazione: asset mancante'),
    );

    expect(
      find.textContaining('Errore durante l\'inizializzazione'),
      findsOneWidget,
    );
  });
}