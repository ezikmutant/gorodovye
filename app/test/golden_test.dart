// Снимок витрины целиком — эталон, с которым сверяются последующие правки.
//
// Тесты по умолчанию рисуют текст заглушечной гарнитурой, поэтому шрифты
// подгружаются вручную: без них снимок показал бы раскладку, но не типографику,
// а типографика — половина этой ДС.
//
//     flutter test --update-goldens test/golden_test.dart   # переснять
//     flutter test test/golden_test.dart                    # сверить

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gorodovye/showcase.dart';

import 'fonts.dart';

void main() {
  setUpAll(loadDsFonts);

  testWidgets('витрина целиком', (tester) async {
    // Высокое узкое полотно: витрину смотрят прокруткой, а снимок нужен
    // целиком, поэтому берём высоту с запасом и рисуем без скролла.
    tester.view.physicalSize = const Size(900, 6400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(data: MediaQueryData(), child: Showcase()),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Showcase),
      matchesGoldenFile('goldens/showcase.png'),
    );
  });
}
