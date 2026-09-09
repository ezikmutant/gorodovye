// ignore_for_file: avoid_print — печать здесь и есть результат:
// проба нужна, чтобы прочитать числа глазами.

// Проба движения покадрово.
//
// Глазами я анимацию не вижу, поэтому меряю: прокручиваю по 16 мс и снимаю
// фактическую матрицу трансформации — `getTransformTo(null)` отдаёт то, что
// правда нарисовано, вместе с масштабом и поворотом, а не то, что задумано.
//
// Ловит ровно те поломки, которые вкусом не ловятся: анимации нет вовсе,
// первый кадр прыгает, два таймера расходятся.
//
//     flutter test test/motion_probe.dart --plain-name проба

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gorodovye/ds/ds.dart';

/// Что видно на кадре: сдвиг, масштаб, поворот.
class Frame {
  Frame(this.ms, Matrix4 m)
      : x = m.storage[12],
        y = m.storage[13],
        sx = Offset(m.storage[0], m.storage[1]).distance,
        sy = Offset(m.storage[4], m.storage[5]).distance,
        deg = Offset(m.storage[0], m.storage[1]).direction * 180 / 3.1415926;

  final int ms;
  final double x, y, sx, sy, deg;
}

/// Прокрутить N кадров, снимая матрицу у найденного узла.
Future<List<Frame>> sample(
  WidgetTester tester,
  Finder finder, {
  int frames = 40,
  int stepMs = 16,
}) async {
  final out = <Frame>[];
  for (var i = 0; i <= frames; i++) {
    if (finder.evaluate().isEmpty) {
      out.add(Frame(i * stepMs, Matrix4.identity()..setEntry(3, 3, 0)));
    } else {
      out.add(Frame(i * stepMs, tester.renderObject(finder).getTransformTo(null)));
    }
    await tester.pump(Duration(milliseconds: stepMs));
  }
  return out;
}

/// Печать столбиком плюс разбор: сколько прошло за первый кадр, был ли
/// перелёт, где остановилось.
/// Что удалось померить. Возвращаем, а не только печатаем: на этих числах
/// стоят проверки ниже.
class Metrics {
  Metrics(this.span, this.jump, this.overshoot, this.settledMs, this.range);

  /// Пройденный путь от первого кадра к последнему.
  final double span;

  /// Доля пути, проглоченная за первый кадр. Больше четверти — это не
  /// анимация, а скачок.
  final double jump;

  /// Перелёт за цель, долей пути.
  final double overshoot;

  /// Когда значение перестало уходить дальше процента размаха.
  final int settledMs;

  /// Размах: от минимума к максимуму. У движения «туда и обратно» — вроде
  /// полного оборота — путь равен нулю, и мерить можно только этим.
  final double range;
}

Metrics report(String title, List<Frame> f, double Function(Frame) pick) {
  final v = f.map(pick).toList();
  final first = v.first, last = v.last;
  final span = (last - first).abs();
  final jump = span == 0 ? 0.0 : (v[1] - v[0]).abs() / span;
  final over = v.reduce((a, b) =>
      (b - first).abs() > (a - first).abs() ? b : a);
  final overshoot =
      span == 0 ? 0.0 : ((over - first).abs() - span) / span;

  // Когда доехало: первый кадр, после которого значение больше не уходит
  // дальше одного процента фактического размаха. Считаем от размаха, а не
  // от пути — иначе у движения «туда и обратно» порог нулевой и «доехало»
  // показывает последний кадр всегда.
  final spread = (v.reduce((a, b) => a > b ? a : b) -
      v.reduce((a, b) => a < b ? a : b));
  var settled = v.length - 1;
  for (var i = 1; i < v.length; i++) {
    if (v.sublist(i).every((x) => (x - last).abs() < spread * 0.01 + 1e-9)) {
      settled = i;
      break;
    }
  }

  final lo0 = v.reduce((a, b) => a < b ? a : b);
  final hi0 = v.reduce((a, b) => a > b ? a : b);
  final range = hi0 - lo0;

  // Рисуем по фактическому размаху, а не по пути от начала к концу: у
  // движения «туда и обратно» путь равен нулю, и нормировка по нему
  // превращает картинку в сплошную заливку.
  final bar = v
      .map((x) => range < 1e-9
          ? '·'
          : '▁▂▃▄▅▆▇█'[(((x - lo0) / range * 7).clamp(0, 7)).round()])
      .join();

  final lo = lo0, hi = hi0;

  print('  $title');
  print('    $bar');
  print('    ${first.toStringAsFixed(3)} → ${last.toStringAsFixed(3)}   '
      'мин ${lo.toStringAsFixed(3)} макс ${hi.toStringAsFixed(3)}');
  if (span > 1e-6) {
    print('    путь ${span.toStringAsFixed(2)} · '
        'первый кадр ${(jump * 100).toStringAsFixed(0)} % пути · '
        'перелёт ${(overshoot * 100).toStringAsFixed(1)} % · '
        'доехало за ${settled * 16} мс');
  } else {
    // Начало и конец совпали — движение было туда и обратно. Доля пути
    // здесь ничего не значит, важен размах.
    print('    туда-обратно, размах ${(hi - lo).toStringAsFixed(3)}');
  }
  return Metrics(span, jump, overshoot, settled * 16, range);
}

class _Tabs extends StatefulWidget {
  const _Tabs();
  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  DsTab tab = DsTab.map;
  @override
  Widget build(BuildContext context) => DsNavbar(
      active: tab, onChanged: (t) => setState(() => tab = t));
}

class _Row extends StatefulWidget {
  const _Row();
  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool on = false;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 240,
        child: DsFilterRow(
            label: 'Все', selected: on, onTap: () => setState(() => on = !on)),
      );
}

Widget bare(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(alignment: Alignment.topLeft, child: child),
    );

void main() {
  testWidgets('проба движения', (tester) async {
    print('');

    // --- навбар: переезд пилюли -----------------------------------------
    await tester.pumpWidget(bare(const _Tabs()));
    await tester.tapAt(tester.getCenter(find.byType(DsNavbar)) +
        const Offset(64, 0));
    final pill = find.descendant(
        of: find.byType(DsNavbar), matching: find.byType(ClipRRect));
    final navbar = await sample(tester, pill, frames: 45);
    print('НАВБАР');
    final pillX = report('положение пилюли', navbar, (f) => f.x);
    final pillW = report('ширина пилюли', navbar, (f) => f.sx);
    await tester.pumpAndSettle();

    // Пилюля обязана ехать, а не переставляться.
    expect(pillX.jump, lessThan(0.25),
        reason: 'первый кадр съедает больше четверти пути — это скачок');
    // Перелёта нет: пружина критически затухающая. Отскок здесь был и снят
    // как навязчивый — проверка держит, чтобы он не вернулся правкой числа.
    expect(pillX.overshoot, lessThan(0.005),
        reason: 'пилюля проскакивает цель — вернулся отскок');
    expect(pillX.settledMs, lessThanOrEqualTo(320));
    // И не деформируется: растяжение с сжатием были частью того же приёма.
    expect(pillW.range, lessThan(0.001),
        reason: 'пилюля меняет ширину — вернулось растяжение');

    // --- спойлер: раскрытие ---------------------------------------------
    // Высоту трансформация не показывает, поэтому меряем по сдвигу маркера
    // под спойлером: насколько он уехал вниз, настолько спойлер и раскрылся.
    const marker = ValueKey('маркер');
    await tester.pumpWidget(bare(SizedBox(
      width: 343,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DsSpoiler(
              title: 'Где искать',
              child: Text('Подсказка', style: T.bodySm)),
          const SizedBox(key: marker, height: 1),
        ],
      ),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Где искать'));
    final grow = await sample(tester, find.byKey(marker), frames: 25);
    print('');
    print('СПОЙЛЕР');
    final height = report('высота раскрытия', grow, (f) => f.y);
    await tester.pumpAndSettle();

    // Раскрытие: 300 мс, как у аккордеона motion-primitives. Кривая пологая,
    // поэтому первый кадр обязан быть маленьким — рывка в начале нет.
    expect(height.span, greaterThan(10),
        reason: 'содержимое не раскрывается');
    expect(height.jump, lessThan(0.1),
        reason: 'раскрытие стартует рывком, а не пологой кривой');
    expect(height.settledMs, inInclusiveRange(272, 320),
        reason: 'раскрытие уложилось не в 300 мс');

    // --- строка фильтра: появление галочки ------------------------------
    await tester.pumpWidget(bare(const _Row()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Все'));
    final check = find.descendant(
        of: find.byType(DsFilterRow), matching: find.byType(DsIcon));
    final row = await sample(tester, check, frames: 20);
    print('');
    print('СТРОКА ФИЛЬТРА');
    final checkScale = report('масштаб галочки', row, (f) => f.sx);
    report('её сдвиг', row, (f) => f.x);
    await tester.pumpAndSettle();

    // Регрессия, которую поймала проба: с `begin` у DsPop галочка
    // проигрывала появление на первой сборке и дальше не двигалась вовсе —
    // масштаб шёл 1.000 → 1.000. Проверка держит именно это.
    expect(checkScale.span, greaterThan(0.2),
        reason: 'галочка не анимируется: масштаб не меняется');
    expect(checkScale.settledMs, lessThanOrEqualTo(260));

    print('');
  });
}
