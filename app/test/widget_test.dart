// Дымовые тесты ДС: собирается ли она вообще и держатся ли правила каталога.
//
// Проверяют не вид, а то, что дерево строится и матрицы совпадают с Figma.
// Сверка с макетом — глазами, тест её не заменяет и не пытается.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gorodovye/ds/ds.dart';
import 'package:gorodovye/main.dart';

/// Компонент без приложения: только направление письма, ничего больше.
Widget bare(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    );

/// Полотно под целую матрицу. Экран теста — 800×600, а 27 ячеек в него не
/// влезают: без этого тест ловил бы переполнение раскладки вместо ошибок ДС.
void wideSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(2400, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('витрина строится и прокручивается до кнопок', (tester) async {
    await tester.pumpWidget(const GorodovyeApp());
    expect(find.text('Дизайн-система «Городовых»'), findsOneWidget);

    // ListView строит только видимую часть, поэтому до кнопок надо доехать.
    // Цель прокрутки обязана быть единственной: `scrollUntilVisible` требует
    // ровно один элемент — и на пустом наборе, и на множественном он падает.
    // Подходит подпись кнопки с подзаголовком, она на витрине одна.
    await tester.scrollUntilVisible(find.text(L.trustMe), 400);
    expect(find.text(L.found), findsWidgets);
  });

  testWidgets('матрица Button — 27 ячеек строятся', (tester) async {
    final cells = [
      for (final type in DsButtonType.values)
        for (final size in DsButtonSize.values)
          for (final state in DsState.values)
            DsButton(
              label: L.found,
              type: type,
              size: size,
              forceState: state,
              onPressed: () {},
            ),
    ];
    expect(cells.length, 27);

    wideSurface(tester);
    await tester.pumpWidget(bare(Wrap(spacing: 8, runSpacing: 8, children: cells)));
    expect(tester.takeException(), isNull);
    expect(find.byType(DsButton), findsNWidgets(27));
  });

  testWidgets('матрица IconButton — 22 ячейки, у glass нет disabled',
      (tester) async {
    final cells = [
      for (final type in DsIconButtonType.values)
        for (final size in DsIconButtonSize.values)
          for (final state in DsState.values)
            if (!(type == DsIconButtonType.glass && state == DsState.disabled))
              DsIconButton(
                icon: DsIconName.camera,
                type: type,
                size: size,
                forceState: state,
                onPressed: () {},
              ),
    ];
    expect(cells.length, 22);

    wideSurface(tester);
    await tester.pumpWidget(bare(Wrap(spacing: 8, runSpacing: 8, children: cells)));
    expect(tester.takeException(), isNull);
  });

  test('glass с disabled не собирается', () {
    // Стеклянные кнопки в продукте не выключаются — ячейки в матрице нет,
    // и компонент не даёт её изобразить.
    expect(
      () => DsIconButton(
        icon: DsIconName.camera,
        type: DsIconButtonType.glass,
        forceState: DsState.disabled,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('нажатое: заливка у фоновых, подпись у ghost', (tester) async {
    // «Цвет приходит в момент действия» — но носитель цвета зависит от того,
    // есть ли фон. У primary и secondary под пальцем расходится терракотовая
    // заливка; ghost лежит поверх содержимого, заливка вырезала бы в нём
    // дыру, поэтому терракотой становится сама подпись.
    //
    // Слоёв теперь два: нижний в покое, верхний нажатый и обрезанный кругом.
    // Проверяем оба — иначе можно не заметить, что покой уехал вместе
    // с нажатием.
    List<Color> layers(WidgetTester t) => t
        .widgetList<ColoredBox>(find.descendant(
          of: find.byType(DsButton),
          matching: find.byType(ColoredBox),
        ))
        .map((b) => b.color)
        .toList();

    final resting = {
      DsButtonType.primary: S.surfaceActionPrimary,
      DsButtonType.secondary: S.surfaceActionSecondary,
    };
    for (final type in resting.keys) {
      await tester.pumpWidget(bare(DsButton(
        label: L.found,
        type: type,
        forceState: DsState.pressed,
        onPressed: () {},
      )));
      expect(layers(tester), [resting[type], S.surfaceActionPressed],
          reason: type.name);
    }

    await tester.pumpWidget(bare(DsButton(
      label: L.found,
      type: DsButtonType.ghost,
      forceState: DsState.pressed,
      onPressed: () {},
    )));
    await tester.pumpAndSettle();
    expect(layers(tester), [const Color(0x00000000), const Color(0x00000000)]);
    // Подпись тоже в двух видах: снизу спокойная, сверху терракотовая.
    // Круг обрезает верхнюю — терракота доходит до буквы ровно тогда,
    // когда доходит до места под ней.
    expect(
      tester
          .widgetList<Text>(find.text(L.found))
          .map((t) => t.style!.color)
          .toList(),
      [InkMode.light.textDefault, S.textAccent],
    );
  });

  testWidgets('заливка живёт только под пальцем', (tester) async {
    // Верхний слой существует, пока идёт нажатие или гашение, и уходит
    // из дерева совсем. Иначе прозрачный слой ловил бы попадания и
    // перерисовывался бы впустую на каждой кнопке экрана.
    await tester.pumpWidget(
        bare(DsButton(label: L.found, onPressed: () {})));
    final wash = find.descendant(
        of: find.byType(DsButton), matching: find.byType(ClipPath));
    expect(wash, findsNothing);

    final gesture = await tester.startGesture(
        tester.getTopLeft(find.byType(DsButton)) + const Offset(8, 8));
    // Два кадра: на первом контроллер только трогается, радиус ещё ноль,
    // и слой намеренно не рисуется.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(wash, findsOneWidget, reason: 'заливка не появилась под пальцем');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(wash, findsNothing, reason: 'заливка не убралась после отпускания');
  });

  testWidgets('чип не меняет размер при выборе', (tester) async {
    // Нашлось глазами: чип подпрыгивал на два пикселя при каждом тапе.
    // В Figma обводка внутренняя и высоту не меняет, во Flutter она
    // добавляется к размеру — поэтому рамка нужна обоим вариантам,
    // у выбранного просто цветом заливки.
    final sizes = <bool, Size>{};
    for (final selected in [false, true]) {
      await tester.pumpWidget(bare(
          DsChip(label: 'Мифические', selected: selected, onTap: () {})));
      sizes[selected] = tester.getSize(find.byType(DsChip));
    }
    expect(sizes[true], sizes[false]);
    expect(sizes[false]!.height, 37);
  });

  testWidgets('значок спойлера набирает цвет вместе с раскрытием',
      (tester) async {
    // Найдено глазами на витрине: значок был терракотовым всегда. В макете
    // цвет зависит от состояния — закрытый `ink-neutral` (`296:734`),
    // раскрытый `accent-500` (`296:745`).
    await tester.pumpWidget(bare(SizedBox(
      width: 343,
      child: DsSpoiler(
          title: 'Где искать', child: Text('Подсказка', style: T.bodySm)),
    )));
    Color? glyph() => tester
        .widget<DsIcon>(find.descendant(
            of: find.byType(DsSpoiler), matching: find.byType(DsIcon)))
        .color;

    expect(glyph(), S.inkNeutral);
    await tester.tap(find.text('Где искать'));
    await tester.pumpAndSettle();
    expect(glyph(), S.iconAccent);
    await tester.tap(find.text('Где искать'));
    await tester.pumpAndSettle();
    expect(glyph(), S.inkNeutral, reason: 'закрылся, а цвет остался');
  });

  testWidgets('плашка живёт по таймеру, а состояние — без него',
      (tester) async {
    // Пол в отрасли — 4 с (`SnackBar` во Flutter). У нас 5, а с кнопкой 10:
    // общее правило всех систем — с действием короткий таймер не ставят,
    // человеку нужно заметить, прочитать и дотянуться.
    var gone = 0;
    Widget toast({bool action = false, bool persistent = false}) => bare(
          SizedBox(
            width: 343,
            child: DsToastError(
              message: M.saveFailed,
              onAction: action ? () {} : null,
              persistent: persistent,
              onDismiss: () => gone++,
            ),
          ),
        );

    // Без кнопки — пять секунд. Уход теперь со своим движением, поэтому
    // экран узнаёт о нём не в тот же кадр, а после доводки.
    await tester.pumpWidget(toast());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    expect(gone, 0, reason: 'ушла раньше пяти секунд');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(gone, 1);

    // С кнопкой — десять.
    gone = 0;
    await tester.pumpWidget(toast(action: true));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    expect(gone, 0, reason: 'с кнопкой ушла раньше десяти секунд');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(gone, 1);

    // Состояние не гаснет вовсе.
    gone = 0;
    await tester.pumpWidget(toast(action: true, persistent: true));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    expect(gone, 0, reason: 'плашка о состоянии погасла по таймеру');

    // Но свайпом вниз убирается: это та самая «отключаемость» из WCAG.
    await tester.drag(find.byType(DsToastError), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(gone, 1, reason: 'свайп вниз не убрал плашку');
  });

  testWidgets('плашка приезжает и уезжает, а не возникает кадром',
      (tester) async {
    // Появление и уход — одно движение снизу, на свою высоту.
    // До этого плашка возникала мгновенно, притом что свайп её доводил
    // плавно: один элемент уходил двумя разными способами.
    var gone = 0;
    await tester.pumpWidget(bare(SizedBox(
      width: 343,
      child: DsToastError(message: M.saveFailed, onDismiss: () => gone++),
    )));
    // Меряем содержимое, а не саму плашку: сдвиг живёт внутри неё,
    // и внешняя коробка стоит на месте по построению.
    final plate = find.text(M.saveFailed);

    await tester.pump();
    final start = tester.getRect(plate).top;
    await tester.pump(const Duration(milliseconds: 120));
    final middle = tester.getRect(plate).top;
    await tester.pumpAndSettle();
    final home = tester.getRect(plate).top;

    expect(start, greaterThan(home + 8), reason: 'плашка не приезжала снизу');
    expect(middle, lessThan(start), reason: 'приезд не идёт кадрами');
    expect(middle, greaterThan(home), reason: 'приезд закончился слишком рано');

    // Уход по таймеру — то же движение назад, и только после него экран
    // убирает плашку из дерева.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 100));
    expect(gone, 0, reason: 'плашка сообщила об уходе, ещё не уехав');
    expect(tester.getRect(plate).top, greaterThan(home),
        reason: 'уход без движения');
    await tester.pumpAndSettle();
    expect(gone, 1);
  });

  testWidgets('под пальцем отсчёт плашки стоит', (tester) async {
    // Пять секунд могли истечь посреди жеста, и плашка исчезала из-под
    // пальца. Пока с ней взаимодействуют, таймер не идёт — общее правило
    // для всего, что гаснет само.
    var gone = 0;
    await tester.pumpWidget(bare(SizedBox(
      width: 343,
      child: DsToastError(message: M.saveFailed, onDismiss: () => gone++),
    )));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DsToastError)));
    // Сдвиг больше порога распознавания, но меньше порога закрытия (24).
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    expect(gone, 0, reason: 'плашка ушла из-под пальца');

    // Отпустили, не доведя: плашка вернулась, отсчёт пошёл заново.
    await gesture.up();
    await tester.pumpAndSettle();
    expect(gone, 0);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(gone, 1, reason: 'после возврата отсчёт не завёлся');
  });

  testWidgets('действие на плашке сбоя отвечает на палец', (tester) async {
    // «Повторить» — такая же кнопка, как остальные, и молчать под пальцем
    // не должна. Заливки нет: плашка уже красная, терракота на ней — грязь.
    // Отвечают просадка и притухание.
    await tester.pumpWidget(bare(SizedBox(
      width: 343,
      child: DsToastError(message: M.saveFailed, onAction: () {}),
    )));
    // Плашка теперь приезжает: пока она в пути, нажимать её незачем.
    await tester.pumpAndSettle();
    final action = find.text(L.retry);

    double scale() => tester
        .widget<AnimatedScale>(find.ancestor(
            of: action, matching: find.byType(AnimatedScale)))
        .scale;
    double opacity() => tester
        .widget<AnimatedOpacity>(find.ancestor(
            of: action, matching: find.byType(AnimatedOpacity)))
        .opacity;

    expect(scale(), 1);
    expect(opacity(), 1);

    final gesture = await tester.startGesture(tester.getCenter(action));
    await tester.pump();
    expect(scale(), Motion.pressScale);
    expect(opacity(), lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(), 1, reason: 'просадка не отпустила');
    expect(opacity(), 1);
  });

  testWidgets('карточка проседает под пальцем, а не парит', (tester) async {
    // Поворот тут ровно тот же, что был порт Basic Tilt Card, а читается
    // он по-разному — смотря что происходит с плоскостью покоя. Пока
    // карточка только качалась вокруг центра, один угол уходил вниз,
    // другой ровно настолько же вверх: движение подвешенного предмета.
    // «Как будто они висят в воздухе, а кнопка — лежит» (09.09.2026).
    //
    // Держим здесь то, что это чинит: под плоскость покоя уходят **оба**
    // угла, просто нажатый — заметно глубже. Перспектива уменьшает то,
    // что дальше от глаза, поэтому «глубже» значит «ближе к центру».
    //
    // И заодно ловушка, на которой наклон не работал вовсе: `Listener`
    // по умолчанию ждёт попадания в ребёнка, а пустое место карточки
    // хит-тест не проходит — палец в углу не доходил.
    await tester.pumpWidget(
        bare(const DsTilt(child: SizedBox(width: 164, height: 228))));
    final card = find.byType(DsTilt);
    final box = tester.renderObject<RenderBox>(
        find.descendant(of: card, matching: find.byType(SizedBox)));

    double corner(Offset local) =>
        (box.localToGlobal(local) - box.localToGlobal(const Offset(82, 114)))
            .distance;

    final rest = corner(Offset.zero);
    final gesture =
        await tester.startGesture(tester.getTopLeft(card) + const Offset(20, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final near = rest - corner(Offset.zero);
    final far = rest - corner(const Offset(164, 228));

    expect(near, greaterThan(2), reason: 'нажатый угол не просел');
    expect(far, greaterThan(0),
        reason: 'дальний угол вышел над плоскостью покоя — карточка парит');
    expect(near, greaterThan(far * 1.5),
        reason: 'просадка ровная: угол под пальцем ничем не выделен');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(corner(Offset.zero), closeTo(rest, 0.5),
        reason: 'карточка не вернулась в плоскость');
  });

  testWidgets('навбар проседает под пальцем, но пилюля едет как ехала',
      (tester) async {
    // Просаживается панель целиком, а не отдельный таб: у невыбранного таба
    // нет ни заливки, ни рамки — одно слово, и три процента просадки на нём
    // не видно. А нажатие по невыбранному табу и есть обычный случай.
    //
    // Держим здесь оба конца: реакция на палец есть, а переезд пилюли она
    // не трогает — «переезжает норм» (09.09.2026). `DsTilt` ловит палец
    // `Listener`, тот не входит в арену жестов, и тап по табу доходит.
    DsTab? tapped;
    await tester.pumpWidget(bare(
        DsNavbar(active: DsTab.map, onChanged: (t) => tapped = t)));
    final bar = find.byType(DsNavbar);
    final box = tester.renderObject<RenderBox>(
        find.descendant(of: bar, matching: find.byType(Container)).first);
    final size = box.size;

    double corner(Offset local) => (box.localToGlobal(local) -
            box.localToGlobal(Offset(size.width / 2, size.height / 2)))
        .distance;

    final restNear = corner(Offset(size.width, size.height));
    final restFar = corner(Offset.zero);

    final gesture =
        await tester.startGesture(tester.getCenter(bar) + const Offset(64, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final near = restNear - corner(Offset(size.width, size.height));
    final far = restFar - corner(Offset.zero);
    expect(near, greaterThan(2), reason: 'панель не просела под пальцем');
    // Ровно, без стороны. Наклон здесь был (4°) и снят как «многовато»:
    // те же градусы на широком низком объекте дают куда больший ход края,
    // чем на карточке. Сторону нажатия показывает тень, а не геометрия.
    expect(near, closeTo(far, 0.1),
        reason: 'панель качается — вернулся наклон');

    // Тап доходит до таба сквозь наклон: `Listener` наклона не отнимает
    // жест у того, на чём лежит.
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tapped, DsTab.finds, reason: 'наклон съел нажатие по табу');
    expect(corner(Offset(size.width, size.height)), closeTo(restNear, 0.5),
        reason: 'панель не вернулась в плоскость');
  });

  testWidgets('тень отвечает на нажатие', (tester) async {
    // Наклон сам по себе двусмыслен: один и тот же угол читается и как
    // «нажали сюда», и как «приподняли оттуда». Различает их тень —
    // поэтому она обязана поджиматься, темнеть и уезжать под поднятый край.
    await tester.pumpWidget(bare(DsTilt(
      child: DsPressShadow(
        shadow: Shadows.md,
        builder: (context, shadow) => DecoratedBox(
          decoration: BoxDecoration(boxShadow: shadow),
          child: const SizedBox(width: 164, height: 228),
        ),
      ),
    )));

    BoxShadow now() => ((tester
                .widget<DecoratedBox>(find.byType(DecoratedBox))
                .decoration as BoxDecoration)
            .boxShadow!)
        .single;

    final calm = Shadows.md.single;
    expect(now().blurRadius, calm.blurRadius, reason: 'в покое тень не своя');

    final gesture = await tester.startGesture(
        tester.getTopLeft(find.byType(DsTilt)) + const Offset(20, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(now().blurRadius, lessThan(calm.blurRadius * 0.6),
        reason: 'тень не поджалась к предмету');
    expect(now().color.a, greaterThan(calm.color.a),
        reason: 'контактная тень не потемнела');
    // Палец в левом верхнем углу — поднят правый нижний, туда тень и идёт.
    expect(now().offset.dx, greaterThan(1),
        reason: 'тень не ушла под поднятый край');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(now().blurRadius, closeTo(calm.blurRadius, 0.5),
        reason: 'тень не вернулась в покой');
  });

  testWidgets('штамп «Найдено» не растёт от рамки', (tester) async {
    // В Figma (`308:2102`) обводка внутренняя: 247×44 при тексте 215×28
    // и полях по 16. Во Flutter `Border` в `decoration` прибавился бы
    // к габариту — и оттиск, повёрнутый на 8°, встал бы мимо места.
    await tester.pumpWidget(bare(const DsFoundBadge(date: '12.06.26')));
    expect(tester.getSize(find.byType(DsFoundBadge)).height, 44);
  });

  test('чернильный режим меняет ровно три токена', () {
    // Остальные 54 смысловых значения одинаковы во всех режимах — они статикой
    // в S и от режима не зависят по построению.
    expect(InkMode.light.textDefault, isNot(InkMode.onDark.textDefault));
    expect(InkMode.light.textMuted, isNot(InkMode.disabled.textMuted));
    expect(InkMode.onDark.textDefault, InkMode.onDark.textSubtle);
  });

  test('текстовый стиль не несёт цвета', () {
    // В Figma TextStyle не знает про цвет — в коде так же, иначе три режима
    // перестают работать.
    for (final entry in T.all.entries) {
      expect(entry.value.color, isNull, reason: entry.key);
    }
  });
}
