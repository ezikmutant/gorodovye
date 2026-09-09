// Проверки каталога — те же, что в self-check директивы, только машинные.
//
// Ручную сверку с Figma они не заменяют: тест не знает, как должно выглядеть.
// Он держит другое — что каталог полон, что каждая страница строится и что
// у каждого пропа есть тип и объяснение.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gorodovye/catalog/catalog.dart';
import 'package:gorodovye/catalog/pages/sandboxes.dart';
import 'package:gorodovye/ds/ds.dart';

import 'fonts.dart';

/// Полотно под целую страницу каталога: матрицы в 800×600 не помещаются.
void wideSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  // Песочницы меряются целиком, значит и текст должен быть настоящим:
  // заглушечная гарнитура переполняет кнопку «Показать на карте».
  setUpAll(loadDsFonts);

  test('в каталоге есть страница на каждый компонент базы', () {
    // Список ведётся руками намеренно: он и есть проверка. Появился компонент
    // в lib/ds/ — тест падает, пока для него не заведена страница.
    const expected = {
      'DsButton',
      'DsIconButton',
      'DsInput',
      'DsBadge',
      'DsNavbar',
      'DsStatusBar',
      'DsHandle',
      'DsIcon',
      'DsChip',
      'DsFilterRow',
      'DsSpoiler',
      'DsSpoilers',
      'DsFoundBadge',
      'DsToastError',
      'DsInkStamp',
    };
    final actual = {for (final page in catalogComponents) page.name};

    expect(actual, expected);
  });

  test('у каждого пропа есть тип и объяснение', () {
    for (final page in catalogComponents) {
      expect(page.figma, isNotEmpty, reason: page.name);
      expect(page.doc, isNotEmpty, reason: page.name);
      for (final prop in page.props) {
        expect(prop.type, isNotEmpty, reason: '${page.name}.${prop.name}');
        expect(prop.doc, isNotEmpty, reason: '${page.name}.${prop.name}');
        if (prop.kind == ControlKind.radio) {
          expect(prop.options, isNotEmpty,
              reason: '${page.name}.${prop.name}: перечисление без вариантов');
        }
      }
    }
  });

  test('сниппет собирается и называет компонент', () {
    for (final page in catalogComponents) {
      final args = Args({for (final p in page.props) p.name: p.initial});
      final code = page.code(args);
      expect(code, contains(page.name), reason: page.name);
    }
  });

  test('витринные пропсы в код не попадают', () {
    // forceState — приём каталога, а не продукта: он показывает ячейку
    // матрицы. В сниппете, который копируют в экран, его быть не должно.
    for (final page in catalogComponents) {
      for (final prop in page.props.where((p) => !p.inCode)) {
        final args = Args({for (final p in page.props) p.name: p.initial});
        expect(page.code(args), isNot(contains(prop.name)), reason: page.name);
      }
    }
  });

  testWidgets('каждая страница компонента строится', (tester) async {
    wideSurface(tester);

    for (final page in catalogComponents) {
      final args = Args({for (final p in page.props) p.name: p.initial});
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) => Center(
              child: page.build(context, args, (_, __) {}),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull, reason: page.name);
    }
  });

  testWidgets('каталог поднимается и переключает страницы', (tester) async {
    wideSurface(tester);
    await tester.pumpWidget(CatalogApp(sections: catalogSections));
    await tester.pumpAndSettle();

    expect(find.text('О каталоге'), findsWidgets);

    // Навигация: уходим на страницу кнопки и убеждаемся, что она собралась
    // вместе с матрицей.
    await tester.tap(find.text('DsButton').first);
    await tester.pumpAndSettle();

    expect(find.text('Figma · Button · 29:11'), findsOneWidget);
    expect(find.byType(DsButton), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('альбом ставит оттиски, но не отмечает карточки', (tester) async {
    // Собрано по `Screen/Collection` (308:2101). Оттиск стоит поверх каждой
    // карточки, а отметки «НАЙДЕНО» в сетке нет и быть не должно: в альбоме
    // лежит только собранное, и отмечать каждую карточку — повторять
    // очевидное. Первая сборка песочницы это правило нарушала.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (context) => albumSandbox.body(context)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(DsInkStamp), findsNWidgets(6));
    expect(find.byType(DsFoundBadge), findsNothing);

    await tester.tap(find.text('Показать пустой'));
    await tester.pumpAndSettle();
    expect(find.byType(DsInkStamp), findsNothing);
    expect(find.text('Пока пусто'), findsOneWidget);
  });

  testWidgets('первый чип стоит у края, а не с отступом', (tester) async {
    // `Wrap` ставит зазор между детьми независимо от их ширины. Крестик
    // сброса живёт первым в списке, и «пустая» его версия — `SizedBox.shrink`
    // на месте — всё равно отодвигала «Звери» от края на восемь пикселей.
    // Ушедший обязан исчезнуть из списка, а не сжаться в нём.
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (context) => filtersSandbox.body(context)),
    ));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.widgetWithText(DsChip, 'Звери')).left,
      tester.getRect(find.text('Коллекции')).left,
      reason: 'первый чип не встал по левому краю группы',
    );
  });

  testWidgets('«Как выглядит»: снимки столбцом, тап открывает просмотрщик',
      (tester) async {
    // Блок открывают, чтобы разглядеть фигурку, поэтому снимки идут друг
    // под другом шириной 300, а не лентой: горизонтальная прокрутка
    // заставляла бы листать вслепую.
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (context) => sheetSandbox.body(context)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Как выглядит · 3'));
    await tester.pumpAndSettle();

    final photos = find.byType(DsAppear);
    expect(photos, findsNWidgets(3));
    final rects = [
      for (var i = 0; i < 3; i++) tester.getRect(photos.at(i)),
    ];
    for (final r in rects) {
      expect(r.width, 300, reason: 'снимок не 300 шириной');
    }
    expect(rects[1].top, greaterThan(rects[0].bottom - 1),
        reason: 'второй снимок не под первым');
    expect(rects[2].top, greaterThan(rects[1].bottom - 1),
        reason: 'третий снимок не под вторым');
    expect(rects[1].left, rects[0].left);

    // Тап разворачивает снимок во весь экран; закрытие возвращает шторку.
    expect(find.byType(InteractiveViewer), findsNothing);
    await tester.tap(photos.at(2));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);

    // Окно просмотрщика встаёт вокруг нажатого снимка. Прибитое к началу
    // шторки, оно открывалось за пределами видимого — и выглядело это так,
    // будто снимки не нажимаются.
    final window = tester.getRect(find.byType(InteractiveViewer));
    final photo = rects[2];
    expect(window.top, lessThanOrEqualTo(photo.center.dy));
    expect(window.bottom, greaterThanOrEqualTo(photo.center.dy));

    await tester.tap(find.byWidgetPredicate(
        (w) => w is DsIconButton && w.icon == DsIconName.x));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('плашка сбоя не прячется от собственной кнопки',
      (tester) async {
    // «Повторить» повторяет попытку, а не убирает сообщение. Пока это была
    // одна и та же кнопка, песочница разбирала сама себя: нажал — и показать
    // больше нечего, плашки на экране нет.
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (context) => formSandbox.body(context)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(DsToastError), findsNothing);
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.byType(DsToastError), findsOneWidget);

    await tester.tap(find.text(L.retry));
    await tester.pumpAndSettle();
    expect(find.byType(DsToastError), findsOneWidget,
        reason: 'плашка исчезла от нажатия на «Повторить»');
  });

  testWidgets('в ряду альбома карточки одной высоты', (tester) async {
    // Высота карточки идёт от содержимого — имя бывает в одну строку и в две.
    // Но соседки по ряду обязаны равняться: карточка с коротким именем
    // не должна обрываться выше. Сначала высоты были прибиты к находке
    // руками, и «Улитка» оказалась ниже «Совы возле Кристалла».
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (context) => albumSandbox.body(context)),
    ));
    await tester.pumpAndSettle();

    Rect card(String name) => tester.getRect(
        find.ancestor(of: find.text(name), matching: find.byType(DsTilt)));

    for (final pair in [
      ('Белка с пистолетом', 'Птица на фонтане'),
      ('Пегас', 'Такса'),
      ('Сова возле Кристалла', 'Улитка'),
    ]) {
      final (left, right) = pair;
      expect(card(right).height, card(left).height, reason: '$left / $right');
      expect(card(right).top, card(left).top, reason: '$left / $right');
    }
  });

  testWidgets('шторка: отметка и свои фото только у найденного',
      (tester) async {
    // `Sheet` (301:1872). Своих снимков до находки не бывает, и отметка
    // находки — тоже её следствие, а не украшение карточки.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (context) => sheetSandbox.body(context)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(DsFoundBadge), findsOneWidget);
    expect(find.text('Мои фото'), findsOneWidget);
    // Плавающая кнопка (`BottomAction`, 331:1305) зависит от состояния.
    expect(find.text(L.showMap), findsOneWidget);

    // Тап проходит сквозь градиент: скрим — декорация. Пока он ловил пальцы,
    // весь низ шторки был мёртвым, и этот же тап не доходил.
    await tester.tap(find.text('Ненайденный'));
    await tester.pumpAndSettle();
    expect(find.byType(DsFoundBadge), findsNothing);
    expect(find.text('Мои фото'), findsNothing);
    expect(find.text(L.found), findsOneWidget);
  });
}
