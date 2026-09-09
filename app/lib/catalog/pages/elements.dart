// Раздел «Компоненты», секция UI Kit elements: Chip, FilterRow, Spoiler,
// Spoilers, FoundBadge, ToastError, InkStamp.
//
// Это уже не нейтральные кирпичи, а продуктовые блоки: каждый несёт правило
// из PRD, и правило записано рядом с ним.

import 'package:flutter/widgets.dart';

import '../../ds/ds.dart';
import '../chrome.dart';
import '../code.dart';
import '../model.dart';

/// Краски штампа по именам смысловых токенов.
const _inks = <String, Color>{
  'ink-primary': S.inkPrimary,
  'ink-secondary': S.inkSecondary,
  'ink-tertiary': S.inkTertiary,
  'ink-neutral': S.inkNeutral,
};

String _inkName(Object? value) => _inks.entries
    .firstWhere((e) => e.value == value, orElse: () => _inks.entries.first)
    .key;

String _inkExpr(Object? value) {
  final name = _inkName(value).substring('ink-'.length);
  return 'S.ink${name[0].toUpperCase()}${name.substring(1)}';
}

// ---------------------------------------------------------------------------
// Chip
// ---------------------------------------------------------------------------

final chipPage = ComponentPage(
  name: 'DsChip',
  figma: 'Chip · 55:69',
  doc: 'Множественный выбор: коллекции в фильтрах карты, вкладки альбома. '
      'Форма кодирует тип выбора — чип-переключатель читается как «сколько '
      'угодно», галочка в списке (DsFilterRow) как «один из». Отдельной '
      'кнопки «сбросить» нет: выбор снимается повторным тапом.',
  stage: Stage.sunken,
  props: [
    const Prop(
      name: 'label',
      type: 'String',
      initial: 'Без коллекции',
      kind: ControlKind.text,
      doc: 'Подпись.',
    ),
    const Prop(
      name: 'selected',
      type: 'bool',
      initial: false,
      kind: ControlKind.toggle,
      doc: 'Выбран. Компонент это не хранит — состояние приходит снаружи.',
    ),
    const Prop(
      name: 'onTap',
      type: 'VoidCallback?',
      initial: null,
      kind: ControlKind.none,
      doc: 'Тап. Повторный снимает выбор.',
    ),
  ],
  build: (context, a, set) => DsChip(
    label: a.get<String>('label'),
    selected: a.get<bool>('selected'),
    onTap: () => set('selected', !a.get<bool>('selected')),
  ),
  code: (a) => snippet('DsChip', [
    'label: ${literal(a.get<String>('label'))}',
    if (a.get<bool>('selected')) 'selected: true',
    'onTap: () => toggle(collection)',
  ]),
  matrixTitle: 'Два состояния',
  matrix: (context) => Wrap(
    spacing: Space.s2,
    children: [
      DsChip(label: 'default', onTap: () {}),
      DsChip(label: 'selected', selected: true, onTap: () {}),
    ],
  ),
  notes: const [
    '«Без коллекции» — полноценный фильтр, а не отсутствие фильтра: городовой '
        'может не входить ни в одну коллекцию, и это состояние надо уметь '
        'показать.',
    'Проседает под пальцем на 3% — то же нажатие, что у кнопки '
        '(ds/motion.md).',
  ],
);

// ---------------------------------------------------------------------------
// FilterRow
// ---------------------------------------------------------------------------

final filterRowPage = ComponentPage(
  name: 'DsFilterRow',
  figma: 'FilterRow · 474:3542',
  doc: 'Строка списка с галочкой, высота 44. Живёт в выпадающей панели '
      'фильтров карты. Галочка читается как «один из» — этим она и отличается '
      'от чипа.',
  stage: Stage.sunken,
  props: [
    const Prop(
      name: 'label',
      type: 'String',
      initial: 'Все',
      kind: ControlKind.text,
      doc: 'Подпись строки.',
    ),
    const Prop(
      name: 'selected',
      type: 'bool',
      initial: true,
      kind: ControlKind.toggle,
      doc: 'Показать галочку.',
    ),
    const Prop(
      name: 'onTap',
      type: 'VoidCallback?',
      initial: null,
      kind: ControlKind.none,
      doc: 'Тап по всей строке, а не по галочке: цель размером 44.',
    ),
  ],
  build: (context, a, set) => Container(
    width: 240,
    padding: const EdgeInsets.symmetric(vertical: Space.s2),
    decoration: BoxDecoration(
      color: S.surfaceDefault,
      borderRadius: BorderRadius.circular(Radii.md),
      boxShadow: Shadows.lg,
    ),
    child: DsFilterRow(
      label: a.get<String>('label'),
      selected: a.get<bool>('selected'),
      onTap: () => set('selected', !a.get<bool>('selected')),
    ),
  ),
  code: (a) => snippet('DsFilterRow', [
    'label: ${literal(a.get<String>('label'))}',
    if (a.get<bool>('selected')) 'selected: true',
    'onTap: () => setState(() => _status = status)',
  ]),
  matrixTitle: 'Список целиком',
  matrix: (context) => SizedBox(
    width: 240,
    child: Column(
      children: [
        DsFilterRow(label: 'Все', selected: true, onTap: () {}),
        DsFilterRow(label: 'Найденные', onTap: () {}),
        DsFilterRow(label: 'Не найденные', onTap: () {}),
      ],
    ),
  ),
);

// ---------------------------------------------------------------------------
// Spoiler
// ---------------------------------------------------------------------------

final spoilerPage = ComponentPage(
  name: 'DsSpoiler',
  figma: 'Spoiler · 296:781',
  doc: 'Ядро механики: прячет то, что человек должен найти глазами, а не '
      'прочитать заранее. Раскрытие необратимо в пределах экрана — свернуть '
      'обратно нельзя, потому что подсмотренное уже подсмотрено. '
      'На стенде живой: нажмите и посмотрите на раскрытие за 200 мс.',
  stage: Stage.sunken,
  props: [
    const Prop(
      name: 'title',
      type: 'String',
      initial: 'Где искать',
      kind: ControlKind.text,
      doc: 'Заголовок — единственное, что видно закрытым.',
    ),
    Prop(
      name: 'kind',
      type: 'DsSpoilerKind',
      initial: DsSpoilerKind.text,
      options: DsSpoilerKind.values,
      doc: 'text — подсказка словами, photo — слот Photos.',
    ),
    const Prop(
      name: 'revealed',
      type: 'bool',
      initial: false,
      kind: ControlKind.toggle,
      doc: 'Стартовое состояние. Дальше спойлер живёт сам.',
    ),
    const Prop(
      name: 'child',
      type: 'Widget?',
      initial: null,
      kind: ControlKind.none,
      doc: 'Содержимое. Для kind=photo сюда кладётся слот Photos.',
    ),
  ],
  build: (context, a, set) => SizedBox(
    width: 420,
    child: DsSpoiler(
      title: a.get<String>('title'),
      kind: a.get<DsSpoilerKind>('kind'),
      revealed: a.get<bool>('revealed'),
      child: a.get<DsSpoilerKind>('kind') == DsSpoilerKind.photo
          ? _photoSlot()
          : Text(
              'На фасаде, между вторым и третьим этажом. Смотрите выше '
              'вывески.',
              style: T.bodySm.copyWith(color: InkMode.light.textSubtle),
            ),
    ),
  ),
  code: (a) => snippet('DsSpoiler', [
    'title: ${literal(a.get<String>('title'))}',
    if (a.get<DsSpoilerKind>('kind') != DsSpoilerKind.text)
      'kind: DsSpoilerKind.${a.get<DsSpoilerKind>('kind').name}',
    if (a.get<bool>('revealed')) 'revealed: true',
    'child: Text(find.hint)',
  ]),
  matrixTitle: 'Kind × State',
  matrix: (context) => SizedBox(
    width: 420,
    child: Column(
      children: [
        DsSpoiler(
          title: 'text · hidden',
          child: Text('Подсказка',
              style: T.bodySm.copyWith(color: InkMode.light.textSubtle)),
        ),
        const SizedBox(height: Space.s2),
        DsSpoiler(
          title: 'text · revealed',
          revealed: true,
          child: Text('Подсказка',
              style: T.bodySm.copyWith(color: InkMode.light.textSubtle)),
        ),
        const SizedBox(height: Space.s2),
        DsSpoiler(
            title: 'photo · hidden',
            kind: DsSpoilerKind.photo,
            child: _photoSlot()),
        const SizedBox(height: Space.s2),
        DsSpoiler(
          title: 'photo · revealed',
          kind: DsSpoilerKind.photo,
          revealed: true,
          child: _photoSlot(),
        ),
      ],
    ),
  ),
  notes: const [
    'Это строка списка, а не карточка: значок в светлом кружке и подпись '
        'DS/Heading/lg, разделённые линиями border-strong. Рамка вокруг '
        'каждого спойлера спорила бы с карточкой находки, внутри которой '
        'он живёт.',
    'Значок говорит, что под спойлером: указатель — «где искать», глаз — '
        '«как выглядит». Шеврона нет: в макете он остался выключенным '
        'свойством. Состояние показывает цвет значка — закрытый графитовый '
        'ink-neutral, раскрытый терракотовый icon-accent, и переход идёт '
        'вместе с раскрытием.',
    'Раскрытие взято с аккордеона motion-primitives: высота и прозрачность '
        'одной кривой, 300 мс ease-reveal — cubic-bezier(0.25, 0.1, 0.35, 1). '
        'Закрытие проигрывает ту же кривую заново, а не задом наперёд.',
    'Раскрытие обратимо: тап по заголовку и открывает, и сворачивает. '
        'Подсказка мешает смотреть по сторонам, и убрать её нужно тем же '
        'движением, которым достали.',
    'Счётчик — часть подписи: «Как выглядит · 3». Считать снимки — забота '
        'экрана, компонент печатает то, что дали.',
  ],
);

/// Заглушка слота `Photos`: сам слот в ДС не входит, содержимое кладёт экран.
///
/// Снимки стоят друг под другом во всю ширину. В спойлере «Как выглядит» их
/// разглядывают, а не пересчитывают: с мелкого превью не понять, ту ли
/// фигурку ищешь, а ради этого спойлер и открывают.
Widget _photoSlot() => Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: Space.s2),
          Container(
            width: double.infinity,
            height: Space.s40,
            decoration: BoxDecoration(
              color: const [
                S.surfaceTileSage,
                S.surfaceTileBlush,
                S.surfaceTileSky
              ][i],
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
          ),
        ],
      ],
    );

final spoilersPage = ComponentPage(
  name: 'DsSpoilers',
  figma: 'Spoilers · 296:782',
  doc: 'Контейнер на два спойлера подряд. Отдельный компонент, а не отступ '
      'по месту: пара «Где искать» + «Как выглядит» встречается на каждой '
      'карточке находки, и расстояние между ними — часть системы.',
  stage: Stage.sunken,
  props: const [
    Prop(
      name: 'children',
      type: 'List<Widget>',
      initial: null,
      kind: ControlKind.none,
      doc: 'Спойлеры. Гэп между ними ставит контейнер.',
    ),
  ],
  build: (context, a, set) => SizedBox(
    width: 420,
    child: DsSpoilers(children: [
      DsSpoiler(
        title: 'Где искать',
        child: Text('На фасаде, между вторым и третьим этажом.',
            style: T.bodySm.copyWith(color: InkMode.light.textSubtle)),
      ),
      DsSpoiler(
          title: 'Как выглядит',
          kind: DsSpoilerKind.photo,
          child: _photoSlot()),
    ]),
  ),
  code: (a) => snippet('DsSpoilers', const [
    'children: [\n    DsSpoiler(title: \'Где искать\', child: hint),\n'
        '    DsSpoiler(title: \'Как выглядит\', kind: DsSpoilerKind.photo, '
        'child: photos),\n  ]',
  ]),
);

// ---------------------------------------------------------------------------
// FoundBadge
// ---------------------------------------------------------------------------

final foundBadgePage = ComponentPage(
  name: 'DsFoundBadge',
  figma: 'FoundBadge · 308:2102',
  doc: 'Отметка «НАЙДЕНО · дата». Украшает факт, а не обозначает его: '
      'в альбоме лежит только собранное, поэтому значок не кодирует статус.',
  props: const [
    Prop(
      name: 'date',
      type: 'String',
      initial: '12.06.26',
      kind: ControlKind.text,
      doc: 'Дата находки. Форматирование — забота вызывающего: компонент ДС '
          'не знает про локали и часовые пояса.',
    ),
  ],
  build: (context, a, set) => DsFoundBadge(date: a.get<String>('date')),
  code: (a) => snippet('DsFoundBadge', [
    'date: formatFindDate(find.foundAt)',
  ]),
);

// ---------------------------------------------------------------------------
// ToastError
// ---------------------------------------------------------------------------

final toastPage = ComponentPage(
  name: 'DsToastError',
  figma: 'ToastError · 434:6256',
  doc: 'Только системные сбои: нет сети, не удалось сохранить. Варианта '
      'success здесь нет и не будет — успехи в продукте подтверждаются '
      'формой: штампом в шторке, снимком, улетающим в кнопку альбома. '
      'Одна сущность на один сценарий.',
  stage: Stage.sunken,
  props: [
    Prop(
      name: 'message',
      type: 'String',
      initial: M.offlineMap,
      options: M.all.values.toList(),
      optionLabel: (v) => M.all.entries
          .firstWhere((e) => e.value == v)
          .key
          .substring('msg-'.length),
      doc: 'Текст сбоя. Берётся из M: сообщения живут переменными.',
    ),
    Prop(
      name: 'actionLabel',
      type: 'String',
      initial: L.retry,
      options: const [L.retry, L.showMap],
      doc: 'Подпись действия. По умолчанию L.retry.',
    ),
    const Prop(
      name: 'onAction',
      type: 'VoidCallback?',
      initial: true,
      kind: ControlKind.toggle,
      doc: 'В Figma это свойство «Кнопка». Нет обработчика — нет и кнопки.',
    ),
  ],
  build: (context, a, set) => SizedBox(
    width: 420,
    child: DsToastError(
      message: a.get<String>('message'),
      actionLabel: a.get<String>('actionLabel'),
      onAction: a.get<bool>('onAction') ? () {} : null,
    ),
  ),
  code: (a) => snippet('DsToastError', [
    'message: ${text(a.get<String>('message'))}',
    if (a.get<String>('actionLabel') != L.retry)
      'actionLabel: ${text(a.get<String>('actionLabel'))}',
    if (a.get<bool>('onAction')) 'onAction: () => retry()',
  ]),
  matrixTitle: 'С кнопкой и без',
  matrix: (context) => SizedBox(
    width: 420,
    child: Column(
      children: [
        DsToastError(message: M.offlineMap, onAction: () {}),
        const SizedBox(height: Space.s2),
        const DsToastError(message: M.offlineAlbum),
        const SizedBox(height: Space.s2),
        DsToastError(message: M.saveFailed, onAction: () {}),
      ],
    ),
  ),
);

// ---------------------------------------------------------------------------
// InkStamp
// ---------------------------------------------------------------------------

final inkStampPage = ComponentPage(
  name: 'DsInkStamp',
  figma: 'InkStamp · 29:72',
  doc: 'Оттиск с датой находки. Здесь только форма и краска. Постановка '
      'штампа — событие с анимацией на 600–700 мс, и живёт она в ds/motion.md: '
      'это единственная награда продукта, и собирать её по месту нельзя.',
  stage: Stage.sunken,
  props: [
    const Prop(
      name: 'date',
      type: 'String',
      initial: '12.06.26',
      kind: ControlKind.text,
      doc: 'Дата находки.',
    ),
    Prop(
      name: 'form',
      type: 'DsStampForm',
      initial: DsStampForm.round,
      options: DsStampForm.values,
      doc: 'round — круглая печать, signature — росчерк, block — прямоугольник.',
    ),
    Prop(
      name: 'ink',
      type: 'Color',
      initial: S.inkPrimary,
      options: _inks.values.toList(),
      optionLabel: _inkName,
      doc: 'Краска. Четыре чернильных токена — чтобы оттиски не повторялись.',
    ),
  ],
  build: (context, a, set) => DsInkStamp(
    date: a.get<String>('date'),
    form: a.get<DsStampForm>('form'),
    ink: a.get<Color>('ink'),
  ),
  code: (a) => snippet('DsInkStamp', [
    'date: formatFindDate(find.foundAt)',
    if (a.get<DsStampForm>('form') != DsStampForm.round)
      'form: DsStampForm.${a.get<DsStampForm>('form').name}',
    if (a.raw('ink') != S.inkPrimary) 'ink: ${_inkExpr(a.raw('ink'))}',
  ]),
  matrixTitle: 'Три формы × четыре краски',
  matrix: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final ink in _inks.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Mono(ink.key),
              const SizedBox(height: Space.s2),
              Wrap(
                spacing: Space.s5,
                runSpacing: Space.s5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final form in DsStampForm.values)
                    DsInkStamp(date: '12.06.26', form: form, ink: ink.value),
                ],
              ),
            ],
          ),
        ),
    ],
  ),
  notes: const [
    'Формы условны и требуют сверки глазами: настоящий оттиск — про рисунок '
        'и поворот, а не про рамку.',
    'Анимация проигрывается один раз, при первой постановке. Открывая находку '
        'заново, человек видит готовый штамп — повтор превратил бы награду '
        'в заставку.',
  ],
);

final elementPages = <ComponentPage>[
  chipPage,
  filterRowPage,
  spoilerPage,
  spoilersPage,
  foundBadgePage,
  toastPage,
  inkStampPage,
];
