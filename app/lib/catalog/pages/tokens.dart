// Раздел Foundation: все переменные системы — и смысловые, и глобальные.
//
// Директива требует, чтобы каталог был зеркалом системы целиком, а не только
// её компонентов, и чтобы значения он **читал из токенов**, а не повторял
// руками. Поэтому каждая страница здесь перебирает карту `all` своего слоя:
// добавили токен в `ds/tokens/` — он появился в каталоге сам.

import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/widgets.dart';

import '../../ds/ds.dart';
import '../chrome.dart';
import '../model.dart';

String _hex(Color color) {
  final argb = color.toARGB32();
  final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  final alpha = (argb >> 24) & 0xFF;
  if (alpha == 0xFF) return '#$rgb';
  return '#$rgb · ${(alpha / 255 * 100).round()}%';
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color, {this.alias});

  final String name;
  final Color color;
  final String? alias;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: Space.s12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(color: S.borderDefault),
            ),
          ),
          const SizedBox(height: Space.s1),
          Text(name,
              style: T.bodyXs.copyWith(color: InkMode.light.textDefault)),
          Mono(_hex(color)),
          if (alias != null) Mono('→ $alias', color: S.textAccent),
        ],
      ),
    );
  }
}

Widget _swatches(List<Widget> children) => Wrap(
      spacing: Space.s3,
      runSpacing: Space.s4,
      children: children,
    );

bool _startsWithAny(String name, List<String> prefixes) =>
    prefixes.any(name.startsWith);

// ---------------------------------------------------------------------------
// Цвет
// ---------------------------------------------------------------------------

final colorPage = DocPage(
  title: 'Цвет',
  doc: 'Два слоя. Примитив — сырое значение, смысловой токен — алиас к нему. '
      'Компонент ссылается только на смысловой: правка палитры доходит до '
      'экранов в одном месте. Прозрачность живёт внутри значения переменной, '
      'а не задаётся поверх заливки.',
  body: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CatalogBlock(
        'Смысловые — поверхности',
        doc: 'Под каждым свотчем: значение и примитив, на который он ссылается.',
        child: _swatches([
          for (final e in S.all.entries)
            if (e.key.startsWith('surface-'))
              _Swatch(e.key, e.value, alias: S.aliases[e.key]),
        ]),
      ),
      const SizedBox(height: Space.s6),
      CatalogBlock(
        'Смысловые — текст, обводки, состояния, чернила',
        child: _swatches([
          for (final e in S.all.entries)
            if (_startsWithAny(
                e.key, const ['text-', 'border-', 'bg-', 'ink-']))
              _Swatch(e.key, e.value, alias: S.aliases[e.key]),
        ]),
      ),
      const SizedBox(height: Space.s6),
      CatalogBlock(
        'Три чернильных режима',
        doc: 'Из 58 смысловых токенов режим меняет ровно три текстовых — '
            'они лежат на вариантах InkMode. Остальные 54 одинаковы везде. '
            'Это не тема: режим включается на узле, а не на приложении.',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final mode in InkMode.values) ...[
              Expanded(child: _InkModeCard(mode)),
              const SizedBox(width: Space.s3),
            ],
          ],
        ),
      ),
      const SizedBox(height: Space.s6),
      CatalogBlock(
        'Примитивы',
        doc: 'В компонентах не используются никогда. Показаны здесь, потому '
            'что палитра сама по себе — часть системы.',
        child: _swatches([
          for (final e in P.all.entries) _Swatch(e.key, e.value),
        ]),
      ),
    ],
  ),
);

class _InkModeCard extends StatelessWidget {
  const _InkModeCard(this.mode);

  final InkMode mode;

  @override
  Widget build(BuildContext context) {
    final onDark = mode == InkMode.onDark;
    return Container(
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: onDark ? S.surfaceOverlay : S.surfaceSubtle,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: S.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mode.name, style: T.labelXs.copyWith(color: mode.textMuted)),
          const SizedBox(height: Space.s3),
          Text('text-default',
              style: T.bodySm.copyWith(color: mode.textDefault)),
          Text('text-subtle', style: T.bodySm.copyWith(color: mode.textSubtle)),
          Text('text-muted', style: T.bodySm.copyWith(color: mode.textMuted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Типографика
// ---------------------------------------------------------------------------

final typographyPage = DocPage(
  title: 'Типографика',
  doc: 'Пятнадцать стилей. Цвет в стиль не зашит — иначе весь текст оказался '
      'бы одного цвета и три чернильных режима перестали бы работать. '
      'Dela Gothic One — только Display и Heading 3xl/2xl, остальное Onest.',
  body: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final e in T.all.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Городовые ходят по крышам',
                  style: e.value.copyWith(color: InkMode.light.textDefault)),
              const SizedBox(height: Space.s1),
              Row(
                children: [
                  Mono(e.key, color: S.textAccent),
                  const SizedBox(width: Space.s3),
                  Mono(_styleSpec(e.value)),
                ],
              ),
            ],
          ),
        ),
    ],
  ),
);

String _styleSpec(TextStyle style) {
  final parts = <String>[
    style.fontFamily ?? '—',
    '${style.fontSize?.toStringAsFixed(0)}px',
    'w${style.fontWeight?.value ?? 400}',
    'lh ${style.height?.toStringAsFixed(2)}',
  ];
  if (style.letterSpacing != null && style.letterSpacing != 0) {
    parts.add('tracking ${style.letterSpacing!.toStringAsFixed(2)}');
  }
  return parts.join(' · ');
}

// ---------------------------------------------------------------------------
// Тени
// ---------------------------------------------------------------------------

final shadowPage = DocPage(
  title: 'Тени',
  doc: 'Пять. Тень шторки светит вверх, и это не опечатка: шторка приходит '
      'снизу, тень должна лежать на карте над её краем. У glow теней две — '
      'короткая даёт контакт с поверхностью, широкая ореол вокруг: на карте '
      'фон под маркером меняется каждые несколько пикселей, и односторонняя '
      'тень читается как грязь, а не как объём.',
  body: (context) => Wrap(
    spacing: Space.s8,
    runSpacing: Space.s8,
    children: [
      for (final e in Shadows.all.entries)
        SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(Space.s4),
                child: Container(
                  width: Space.s16,
                  height: Space.s16,
                  decoration: BoxDecoration(
                    color: S.surfaceDefault,
                    borderRadius: BorderRadius.circular(Radii.md),
                    boxShadow: e.value,
                  ),
                ),
              ),
              Mono(e.key, color: S.textAccent),
              for (final shadow in e.value)
                Mono('${shadow.offset.dx.toStringAsFixed(0)} '
                    '${shadow.offset.dy.toStringAsFixed(0)} '
                    'blur ${shadow.blurRadius.toStringAsFixed(0)}'
                    '${shadow.spreadRadius == 0 ? '' : ' spread ${shadow.spreadRadius.toStringAsFixed(0)}'} '
                    '· ${_hex(shadow.color)}'),
            ],
          ),
        ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Пространство
// ---------------------------------------------------------------------------

final spacePage = DocPage(
  title: 'Пространство',
  doc: 'Отступы, радиусы, размеры и шкала кегля. Значение вне шкалы — повод '
      'добавить токен, а не прибить число.',
  body: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CatalogBlock(
        'Отступы',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in Space.all.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s2),
                child: Row(
                  children: [
                    SizedBox(width: 96, child: Mono(e.key)),
                    SizedBox(
                        width: 48,
                        child: Mono('${e.value.toStringAsFixed(0)}px')),
                    Container(
                      width: e.value == 0 ? 1 : e.value,
                      height: Space.s3,
                      color: e.value == 0 ? S.borderStrong : S.surfaceAccent,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: Space.s6),
      CatalogBlock(
        'Радиусы',
        child: Wrap(
          spacing: Space.s4,
          runSpacing: Space.s4,
          children: [
            for (final e in Radii.all.entries)
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: Space.s16,
                      height: Space.s16,
                      decoration: BoxDecoration(
                        color: S.surfaceSunken,
                        borderRadius: BorderRadius.circular(e.value),
                        border: Border.all(color: S.borderStrong),
                      ),
                    ),
                    const SizedBox(height: Space.s1),
                    Mono('${e.key} · ${e.value.toStringAsFixed(0)}'),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: Space.s6),
      CatalogBlock(
        'Размеры и кегль',
        child: CatalogTable(
          columns: const ['Токен', 'Значение', 'Где'],
          flex: const [4, 2, 6],
          rows: [
            for (final e in Sizes.all.entries)
              [
                Mono(e.key, color: InkMode.light.textDefault),
                Mono('${e.value.toStringAsFixed(0)}px'),
                Text(
                  e.key == 'size-touch-min'
                      ? 'минимальная цель для пальца: sm-кнопки, FilterRow, '
                          'вкладки'
                      : 'высота контрола: Input, IconButton lg',
                  style: T.bodyXs.copyWith(color: InkMode.light.textMuted),
                ),
              ],
            for (final e in FontSize.all.entries)
              [
                Mono(e.key, color: InkMode.light.textDefault),
                Mono('${e.value.toStringAsFixed(0)}px'),
                Text('шкала кегля',
                    style: T.bodyXs.copyWith(color: InkMode.light.textMuted)),
              ],
          ],
        ),
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Движение
// ---------------------------------------------------------------------------


/// Стенд движения: замедление, общий пуск и сравнение кривых парами.
///
/// Смотреть анимацию на нормальной скорости бесполезно — `ds/motion.md`
/// говорит про это прямо: «Замедлять в 3–5 раз: на скорости не видно,
/// расходятся ли прозрачность и трансформация».
class _MotionLab extends StatefulWidget {
  const _MotionLab();

  @override
  State<_MotionLab> createState() => _MotionLabState();
}

class _MotionLabState extends State<_MotionLab> {
  double _slow = 1;
  int _run = 0;
  DsTab _tab = DsTab.map;
  bool _checked = false;

  @override
  void dispose() {
    // Множитель глобальный: оставить его включённым значит замедлить всё
    // приложение, включая соседние страницы каталога.
    timeDilation = 1;
    super.dispose();
  }

  void _setSlow(double v) {
    setState(() => _slow = v);
    timeDilation = v;
  }

  void _play() => setState(() {
        _run++;
        _tab = _tab == DsTab.map ? DsTab.finds : DsTab.map;
        _checked = !_checked;
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Space.s2,
          runSpacing: Space.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final v in [1.0, 3.0, 5.0])
              DsChip(
                label: v == 1 ? 'обычно' : '×${v.toInt()} медленнее',
                selected: _slow == v,
                onTap: () => _setSlow(v),
              ),
            const SizedBox(width: Space.s4),
            DsButton(
              label: 'Проиграть',
              size: DsButtonSize.sm,
              onPressed: _play,
            ),
          ],
        ),
        const SizedBox(height: Space.s6),
        _stand('Переезд таба', DsNavbar(
          active: _tab,
          onChanged: (t) => setState(() => _tab = t),
        )),
        _stand(
          'Появление галочки',
          SizedBox(
            width: 240,
            child: DsFilterRow(
              label: 'Все',
              selected: _checked,
              onTap: () => setState(() => _checked = !_checked),
            ),
          ),
        ),
        const SizedBox(height: Space.s4),
        CatalogNote(
          'Кривые парами. Обе дорожки трогаются от одной кнопки, поэтому '
          'разницу видно, а не приходится помнить.',
        ),
        const SizedBox(height: Space.s3),
        _Race(run: _run, top: ('ease-out', Motion.easeOut),
            bottom: ('ease-out-back', Motion.easeOutBack)),
        const SizedBox(height: Space.s3),
        _Race(run: _run, top: ('ease-out-back · перелёт 10%', Motion.easeOutBack),
            bottom: ('ease-out-soft-back · перелёт 2.6%',
                Motion.easeOutSoftBack)),
      ],
    );
  }

  Widget _stand(String title, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: Space.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Mono(title),
            const SizedBox(height: Space.s2),
            child,
          ],
        ),
      );
}

/// Две дорожки, один пуск. Квадрат едет от края до края заданной кривой:
/// характер кривой виден по тому, где он ускоряется и проскакивает ли цель.
class _Race extends StatelessWidget {
  const _Race({required this.run, required this.top, required this.bottom});

  final int run;
  final (String, Curve) top, bottom;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lane(top),
          const SizedBox(height: Space.s2),
          _lane(bottom),
        ],
      );

  Widget _lane((String, Curve) lane) {
    final (name, curve) = lane;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Mono(name),
        const SizedBox(height: Space.s1),
        Container(
          height: Space.s8,
          width: 320,
          padding: const EdgeInsets.all(Space.s1),
          decoration: BoxDecoration(
            color: S.surfaceSunken,
            borderRadius: BorderRadius.circular(Radii.full),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: run.isOdd ? 1.0 : 0.0),
            duration: Motion.reveal,
            curve: curve,
            builder: (context, t, child) => Align(
              // Перелёт кривой уводит t за единицу — не зажимаем, иначе
              // сравнивать будет нечего: весь смысл в том, что видно.
              alignment: Alignment(t * 2 - 1, 0),
              child: child,
            ),
            child: Container(
              width: Space.s6,
              height: Space.s6,
              decoration: const BoxDecoration(
                color: S.surfaceActionPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final motionPage = DocPage(
  title: 'Движение',
  doc: 'Интерфейс статичен и почти бесцветен — цвет живёт в движении. '
      'Акцент появляется только в момент действия и обязательно возвращается '
      'к спокойному состоянию. Потолок интерфейсной анимации 300 мс; штамп — '
      'сознательное исключение на 600–700 мс, но он не переход, а награда, '
      'и в компоненты ДС не входит.',
  body: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CatalogBlock(
        'Стенд',
        doc: 'Движение на скорости не разглядеть: 200 мс — это двенадцать '
            'кадров. Замедлите и нажмите «Проиграть»: всё, что здесь есть, '
            'тронется одновременно, и станет видно, расходятся ли '
            'прозрачность и трансформация. Замедление глобальное и снимается '
            'при уходе со страницы.',
        child: _MotionLab(),
      ),
      const SizedBox(height: Space.s6),
      CatalogBlock(
        'Живьём',
        doc: 'Нажмите и подержите. Просадка 3% приходит за 120 мс, '
            'возвращается за 180 — вход быстрый, возврат спокойнее.',
        child: Wrap(
          spacing: Space.s4,
          runSpacing: Space.s4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DsButton(label: L.found, onPressed: () {}),
            DsIconButton(icon: DsIconName.camera, onPressed: () {}),
            DsChip(label: 'Чип', onTap: () {}),
          ],
        ),
      ),
      const SizedBox(height: Space.s6),
      const CatalogBlock(
        'Кривые',
        doc: 'ease-in не используется нигде: он начинается медленно ровно '
            'в тот момент, когда человек смотрит внимательнее всего.',
        child: _CurveDemo(),
      ),
      const SizedBox(height: Space.s6),
      CatalogBlock(
        'Длительности',
        child: CatalogTable(
          columns: const ['Токен', 'Значение', 'Где'],
          flex: const [4, 3, 7],
          rows: [
            for (final e in Motion.durations.entries)
              [
                Mono(e.key, color: InkMode.light.textDefault),
                Mono('${e.value.inMilliseconds} мс'),
                Text(_motionWhere[e.key] ?? '',
                    style: T.bodyXs.copyWith(color: InkMode.light.textMuted)),
              ],
          ],
        ),
      ),
    ],
  ),
);

const _motionWhere = <String, String>{
  'press-in': 'нажатие кнопки, маркера, чипа — вход',
  'press-out': 'возврат после отпускания',
  'reveal': 'спойлер: высота и прозрачность',
  'drawer-in': 'шторка приходит',
  'drawer-out': 'шторка уходит',
  'toast-in': 'ToastError входит снизу',
  'toast-out': 'ToastError уходит туда же',
  'ceiling': 'потолок интерфейсной анимации',
};

class _CurveDemo extends StatefulWidget {
  const _CurveDemo();

  @override
  State<_CurveDemo> createState() => _CurveDemoState();
}

class _CurveDemoState extends State<_CurveDemo> {
  bool _right = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in Motion.curves.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s3),
            child: Row(
              children: [
                SizedBox(width: 120, child: Mono(e.key, color: S.textAccent)),
                Expanded(
                  child: Container(
                    height: Space.s8,
                    decoration: BoxDecoration(
                      color: S.surfaceSunken,
                      borderRadius: BorderRadius.circular(Radii.full),
                    ),
                    child: AnimatedAlign(
                      alignment:
                          _right ? Alignment.centerRight : Alignment.centerLeft,
                      duration: Motion.drawerIn,
                      curve: e.value,
                      child: Container(
                        width: Space.s8,
                        height: Space.s8,
                        decoration: const BoxDecoration(
                          color: S.surfaceAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        DsButton(
          label: _right ? 'Обратно' : 'Прокатить',
          type: DsButtonType.secondary,
          size: DsButtonSize.sm,
          onPressed: () => setState(() => _right = !_right),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Строки
// ---------------------------------------------------------------------------

final stringsPage = DocPage(
  title: 'Строки',
  doc: 'Подписи кнопок и сообщения системы живут переменными, а не набираются '
      'на экране: формулировка меняется в одном месте и расходится по всем '
      'экранам. Это же готовый ключ для локализации. label- — надпись на '
      'управляющем элементе, msg- — сообщение системы о собственном состоянии.',
  body: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CatalogBlock(
        'label-* — подписи',
        child: CatalogTable(
          columns: const ['Переменная', 'В коде', 'Текст'],
          flex: const [4, 4, 8],
          rows: [
            for (final e in L.all.entries)
              [
                Mono(e.key, color: InkMode.light.textDefault),
                Mono('L.${_camel(e.key, 'label-')}', color: S.textAccent),
                Text(e.value,
                    style: T.bodySm.copyWith(color: InkMode.light.textSubtle)),
              ],
          ],
        ),
      ),
      const SizedBox(height: Space.s6),
      CatalogBlock(
        'msg-* — сообщения',
        child: CatalogTable(
          columns: const ['Переменная', 'В коде', 'Текст'],
          flex: const [4, 4, 8],
          rows: [
            for (final e in M.all.entries)
              [
                Mono(e.key, color: InkMode.light.textDefault),
                Mono('M.${_camel(e.key, 'msg-')}', color: S.textAccent),
                Text(e.value,
                    style: T.bodySm.copyWith(color: InkMode.light.textSubtle)),
              ],
          ],
        ),
      ),
    ],
  ),
);

String _camel(String key, String prefix) {
  final parts = key.substring(prefix.length).split('-');
  return [
    parts.first,
    for (final part in parts.skip(1)) part[0].toUpperCase() + part.substring(1),
  ].join();
}

final tokenPages = <DocPage>[
  colorPage,
  typographyPage,
  shadowPage,
  spacePage,
  motionPage,
  stringsPage,
];
