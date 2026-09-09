// Раздел «Компоненты», секция Foundation: Button, IconButton, Input, Badge,
// Navbar, StatusBar, Handle, Icon.
//
// Матрицы повторяют `ds/components.md` один в один — по ним и сверяют с Figma.

import 'package:flutter/widgets.dart';

import '../../ds/ds.dart';
import '../chrome.dart';
import '../code.dart';
import '../model.dart';

Widget _group(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: Space.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Mono(label),
          const SizedBox(height: Space.s2),
          child,
        ],
      ),
    );

Widget _wrap(List<Widget> children) => Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );

/// Иконки, которые имеет смысл гонять на стенде кнопки.
const _iconChoices = <DsIconName?>[
  null,
  DsIconName.camera,
  DsIconName.mapPin,
  DsIconName.check,
  DsIconName.share2,
];

String _iconLabel(Object? value) =>
    value == null ? 'нет' : (value as DsIconName).name;

String _stateLabel(Object? value) =>
    value == null ? 'живое' : (value as DsState).name;

// ---------------------------------------------------------------------------
// Button
// ---------------------------------------------------------------------------

final buttonPage = ComponentPage(
  name: 'DsButton',
  figma: 'Button · 29:11',
  doc: 'Текстовое действие, 27 ячеек. Нажатое состояние у всех трёх типов '
      'одинаковое — терракота и белый текст. Это и есть правило «цвет приходит '
      'в момент действия»: в покое интерфейс почти монохромный, акцент '
      'вспыхивает только под пальцем.',
  props: [
    Prop(
      name: 'label',
      type: 'String',
      initial: L.found,
      kind: ControlKind.text,
      doc: 'Подпись. В продукте приходит переменной из L, а не набирается.',
    ),
    Prop(
      name: 'type',
      type: 'DsButtonType',
      initial: DsButtonType.primary,
      options: DsButtonType.values,
      doc: 'primary — главное действие, secondary — рядом с ним, ghost — уход.',
    ),
    Prop(
      name: 'size',
      type: 'DsButtonSize',
      initial: DsButtonSize.lg,
      options: DsButtonSize.values,
      doc: 'Высоты 56 / 48 / 44, поля 24 / 20 / 16 — сняты с Figma.',
    ),
    Prop(
      name: 'forceState',
      type: 'DsState?',
      initial: null,
      options: const [null, DsState.pressed, DsState.disabled],
      optionLabel: _stateLabel,
      inCode: false,
      doc: 'Витринный приём: показать ячейку матрицы, не трогая палец. '
          'В продукте состояние решают палец и наличие onPressed.',
    ),
    Prop(
      name: 'subtitle',
      type: 'String?',
      initial: '',
      kind: ControlKind.text,
      doc: 'Вторая строка на самой кнопке: условие объясняется тут, '
          'а не отдельным сообщением.',
    ),
    Prop(
      name: 'icon',
      type: 'DsIconName?',
      initial: null,
      options: _iconChoices,
      optionLabel: _iconLabel,
      doc: 'Глиф слева от подписи.',
    ),
    Prop(
      name: 'expand',
      type: 'bool',
      initial: false,
      kind: ControlKind.toggle,
      doc: 'Занять всю ширину. В Figma это решает раскладка экрана, тут — флаг.',
    ),
    const Prop(
      name: 'onPressed',
      type: 'VoidCallback?',
      initial: null,
      kind: ControlKind.none,
      doc: 'Обработчик. null — кнопка выключена: отдельного пропа для '
          'disabled нет.',
    ),
  ],
  presets: [
    Preset('Primary', {'type': DsButtonType.primary}),
    Preset('Secondary', {'type': DsButtonType.secondary}),
    Preset('Ghost', {'type': DsButtonType.ghost}),
    Preset('Выключена', {'forceState': DsState.disabled},
        doc: 'В продукте это просто onPressed: null.'),
    Preset(
      'Поверить мне',
      {
        'label': L.trustMe,
        'subtitle': L.gpsFar,
        'type': DsButtonType.primary,
      },
      doc: 'Гео не блокирует находку: кнопка подменяется и объясняет причину '
          'на себе. В макете экрана она основная, чёрная — подмена не '
          'понижает действие в правах.',
    ),
    Preset('С иконкой', {'icon': DsIconName.camera}),
    Preset('Во всю ширину', {'expand': true}),
  ],
  build: (context, a, set) {
    final subtitle = a.get<String>('subtitle');
    return DsButton(
      label: a.get<String>('label'),
      subtitle: subtitle.isEmpty ? null : subtitle,
      type: a.get<DsButtonType>('type'),
      size: a.get<DsButtonSize>('size'),
      icon: a.raw('icon') as DsIconName?,
      forceState: a.raw('forceState') as DsState?,
      expand: a.get<bool>('expand'),
      onPressed: () {},
    );
  },
  code: (a) {
    final state = a.raw('forceState') as DsState?;
    final subtitle = a.get<String>('subtitle');
    final icon = a.raw('icon') as DsIconName?;
    final type = a.get<DsButtonType>('type');
    final size = a.get<DsButtonSize>('size');
    final disabled = state == DsState.disabled;
    final label = a.get<String>('label');

    return snippet(
      'DsButton',
      [
        'label: ${text(label)}',
        if (subtitle.isNotEmpty) 'subtitle: ${text(subtitle)}',
        if (icon != null) 'icon: DsIconName.${icon.name}',
        if (type != DsButtonType.primary) 'type: DsButtonType.${type.name}',
        if (size != DsButtonSize.lg) 'size: DsButtonSize.${size.name}',
        if (a.get<bool>('expand')) 'expand: true',
        if (disabled) 'onPressed: null' else 'onPressed: () => collect(id)',
      ],
      note: disabled
          ? 'выключено — это отсутствие onPressed, отдельного пропа нет'
          : null,
    );
  },
  matrixTitle: 'Матрица Type × Size × State — 27 ячеек',
  matrixDoc: 'Тот самый экран, который кладут рядом с Figma. Нажатая колонка '
      'одинаковая у всех трёх типов — так и задумано.',
  matrix: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final size in DsButtonSize.values)
        _group(
          'Size=${size.name}',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final type in DsButtonType.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.s2),
                  child: _wrap([
                    for (final state in DsState.values)
                      DsButton(
                        label: L.found,
                        type: type,
                        size: size,
                        forceState: state,
                        onPressed: () {},
                      ),
                  ]),
                ),
            ],
          ),
        ),
    ],
  ),
  notes: const [
    'Высоты, поля, радиус и стиль подписи сняты замером с Figma '
        '(узлы 29:4 / 328:2084 / 77:16).',
    'ghost в состоянии disabled прозрачный, а не серый: у него и в покое '
        'нет заливки.',
  ],
);

// ---------------------------------------------------------------------------
// IconButton
// ---------------------------------------------------------------------------

final iconButtonPage = ComponentPage(
  name: 'DsIconButton',
  figma: 'IconButton · 77:49',
  doc: 'Действие без текста, 22 ячейки. Четвёртый тип — glass, '
      'полупрозрачная белая заливка для карты и камеры: такие кнопки рядом '
      'с главным действием, но не должны закрывать содержимое.',
  stage: Stage.map,
  props: [
    Prop(
      name: 'icon',
      type: 'DsIconName',
      initial: DsIconName.camera,
      options: const [
        DsIconName.camera,
        DsIconName.slidersHorizontal,
        DsIconName.arrowLeft,
        DsIconName.share2,
        DsIconName.x,
      ],
      doc: 'Глиф.',
    ),
    Prop(
      name: 'type',
      type: 'DsIconButtonType',
      initial: DsIconButtonType.glass,
      options: DsIconButtonType.values,
      doc: 'glass — поверх карты и камеры, остальные три как у кнопки.',
    ),
    Prop(
      name: 'size',
      type: 'DsIconButtonSize',
      initial: DsIconButtonSize.lg,
      options: DsIconButtonSize.values,
      doc: 'Сторона 52 (size-control-md) и 44 (size-touch-min).',
    ),
    Prop(
      name: 'forceState',
      type: 'DsState?',
      initial: null,
      options: const [null, DsState.pressed, DsState.disabled],
      optionLabel: _stateLabel,
      inCode: false,
      doc: 'Ячейка матрицы для витрины.',
    ),
    const Prop(
      name: 'onPressed',
      type: 'VoidCallback?',
      initial: null,
      kind: ControlKind.none,
      doc: 'У glass обязателен: стеклянные кнопки не выключаются.',
    ),
  ],
  presets: [
    Preset('Стекло на карте', {'type': DsIconButtonType.glass}),
    Preset('Затвор', {
      'type': DsIconButtonType.primary,
      'icon': DsIconName.camera,
    }, doc: 'Главные кнопки на камере остаются плотными — их ищут не глядя.'),
    Preset('Фильтры', {
      'type': DsIconButtonType.ghost,
      'icon': DsIconName.slidersHorizontal,
    }),
    Preset('Маленькая', {'size': DsIconButtonSize.sm}),
  ],
  build: (context, a, set) {
    final type = a.get<DsIconButtonType>('type');
    final state = a.raw('forceState') as DsState?;

    // Ячейки glass × disabled в матрице нет, и компонент не даёт её изобразить:
    // конструктор падает на assert. Каталог показывает правило, а не падение.
    if (type == DsIconButtonType.glass && state == DsState.disabled) {
      return SizedBox(
        width: 320,
        child: Text(
          'У glass нет состояния disabled: стеклянные кнопки в продукте '
          'не выключаются. Конструктор такую пару не собирает.',
          textAlign: TextAlign.center,
          style: T.bodySm.copyWith(color: S.textError),
        ),
      );
    }

    return DsIconButton(
      icon: a.get<DsIconName>('icon'),
      type: type,
      size: a.get<DsIconButtonSize>('size'),
      forceState: state,
      onPressed: () {},
    );
  },
  code: (a) {
    final type = a.get<DsIconButtonType>('type');
    final size = a.get<DsIconButtonSize>('size');
    final disabled = a.raw('forceState') == DsState.disabled;
    return snippet('DsIconButton', [
      'icon: DsIconName.${a.get<DsIconName>('icon').name}',
      if (type != DsIconButtonType.primary)
        'type: DsIconButtonType.${type.name}',
      if (size != DsIconButtonSize.lg) 'size: DsIconButtonSize.${size.name}',
      if (disabled) 'onPressed: null' else 'onPressed: () => openCamera()',
    ]);
  },
  matrixTitle: 'Матрица Type × Size × State — 22 ячейки',
  matrixDoc: 'У glass ячеек шесть, а не восемь: состояния disabled у него нет.',
  matrix: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final size in DsIconButtonSize.values)
        _group(
          'Size=${size.name}',
          _wrap([
            for (final type in DsIconButtonType.values)
              for (final state in DsState.values)
                if (!(type == DsIconButtonType.glass &&
                    state == DsState.disabled))
                  DsIconButton(
                    icon: DsIconName.camera,
                    type: type,
                    size: size,
                    forceState: state,
                    onPressed: () {},
                  ),
          ]),
        ),
    ],
  ),
  notes: const [
    'Фон стенда — намёк на карту: на белом surface-glass неотличим от '
        'surface-default, и весь смысл типа теряется.',
    'Альфа лежит внутри значения токена, а не на заливке. Заданная поверх '
        'привязки, она не переживает копирования компонента — так в августе '
        '2026 стеклянные кнопки в Figma теряли прозрачность.',
  ],
);

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

final inputPage = ComponentPage(
  name: 'DsInput',
  figma: 'Input · 29:18',
  doc: 'Поле формы. Матрица State=default/focus/error/disabled. '
      'Фокус на стенде живой — кликните в поле и посмотрите, как обводка '
      'переезжает в кольцо.',
  props: [
    const Prop(
      name: 'placeholder',
      type: 'String?',
      initial: 'Поле ввода',
      kind: ControlKind.text,
      doc: 'Подсказка, пока поле пустое.',
    ),
    Prop(
      name: 'state',
      type: 'DsState',
      initial: DsState.normal,
      options: const [DsState.normal, DsState.disabled],
      doc: 'normal ↔ Figma default. Состояния focus и error задаются не тут: '
          'focus приходит от фокуса, error — отдельным флагом.',
    ),
    const Prop(
      name: 'error',
      type: 'bool',
      initial: false,
      kind: ControlKind.toggle,
      doc: 'Красная обводка. Отдельно от state, потому что ошибка может '
          'случиться и в фокусе, и вне его.',
    ),
    const Prop(
      name: 'controller',
      type: 'TextEditingController?',
      initial: null,
      kind: ControlKind.none,
      doc: 'Не передан — компонент заводит свой и сам же освобождает.',
    ),
    const Prop(
      name: 'onChanged',
      type: 'ValueChanged<String>?',
      initial: null,
      kind: ControlKind.none,
      doc: 'Каждое изменение текста.',
    ),
  ],
  presets: [
    const Preset('Обычное', {'error': false, 'state': DsState.normal}),
    const Preset('Ошибка', {'error': true}),
    const Preset('Выключено', {'state': DsState.disabled}),
  ],
  build: (context, a, set) => SizedBox(
    width: 360,
    child: DsInput(
      placeholder: a.get<String>('placeholder'),
      state: a.get<DsState>('state'),
      error: a.get<bool>('error'),
    ),
  ),
  code: (a) {
    final state = a.get<DsState>('state');
    return snippet('DsInput', [
      'placeholder: ${literal(a.get<String>('placeholder'))}',
      if (a.get<bool>('error')) 'error: true',
      if (state != DsState.normal) 'state: DsState.${state.name}',
      'onChanged: (value) => setState(() => query = value)',
    ]);
  },
  matrixTitle: 'Четыре состояния',
  matrix: (context) => SizedBox(
    width: 360,
    child: Column(
      children: const [
        DsInput(placeholder: 'default'),
        SizedBox(height: Space.s2),
        DsInput(placeholder: 'focus — кликните сюда'),
        SizedBox(height: Space.s2),
        DsInput(placeholder: 'error', error: true),
        SizedBox(height: Space.s2),
        DsInput(placeholder: 'disabled', state: DsState.disabled),
      ],
    ),
  ),
  notes: const [
    'Контроллер и фокус компонент заводит сам, если их не передали, и сам же '
        'освобождает: поле, создающее их в build, течёт при каждой '
        'перерисовке.',
  ],
);

// ---------------------------------------------------------------------------
// Badge
// ---------------------------------------------------------------------------

final badgePage = ComponentPage(
  name: 'DsBadge',
  figma: 'Badge · 29:31',
  doc: 'Статус. Четыре варианта, подпись приходит снаружи.',
  props: [
    const Prop(
      name: 'label',
      type: 'String',
      initial: 'Готово',
      kind: ControlKind.text,
      doc: 'Текст плашки.',
    ),
    Prop(
      name: 'variant',
      type: 'DsBadgeVariant',
      initial: DsBadgeVariant.success,
      options: DsBadgeVariant.values,
      doc: 'Цвет фона: bg-success / warning / error / info.',
    ),
  ],
  build: (context, a, set) => DsBadge(
    label: a.get<String>('label'),
    variant: a.get<DsBadgeVariant>('variant'),
  ),
  code: (a) => snippet('DsBadge', [
    'label: ${literal(a.get<String>('label'))}',
    'variant: DsBadgeVariant.${a.get<DsBadgeVariant>('variant').name}',
  ]),
  matrixTitle: 'Четыре варианта',
  matrix: (context) => _wrap([
    for (final variant in DsBadgeVariant.values)
      DsBadge(label: variant.name, variant: variant),
  ]),
  notes: const [
    'У warning своя пара цветов: жёлтый под белым текстом не читается, '
        'поэтому там text-on-warning, а не text-on-status.',
    'Вертикальные поля приведены к шкале 2026-08-11: 6 → 8 (space-2).',
  ],
);

// ---------------------------------------------------------------------------
// Navbar
// ---------------------------------------------------------------------------

final navbarPage = ComponentPage(
  name: 'DsNavbar',
  figma: 'Navbar · 84:122',
  doc: 'Нижний таб-бар, две вкладки. На стенде живой: нажмите вкладку — '
      'значение пропа active переключится, как в приложении.',
  stage: Stage.sunken,
  props: [
    Prop(
      name: 'active',
      type: 'DsTab',
      initial: DsTab.map,
      options: DsTab.values,
      doc: 'Активная вкладка. Компонент её не хранит — состояние снаружи.',
    ),
    const Prop(
      name: 'onChanged',
      type: 'ValueChanged<DsTab>?',
      initial: null,
      kind: ControlKind.none,
      doc: 'Просьба переключиться. Решает экран, а не таб-бар.',
    ),
  ],
  build: (context, a, set) => DsNavbar(
    active: a.get<DsTab>('active'),
    onChanged: (tab) => set('active', tab),
  ),
  code: (a) => snippet('DsNavbar', [
    'active: DsTab.${a.get<DsTab>('active').name}',
    'onChanged: (tab) => setState(() => _tab = tab)',
  ]),
  matrixTitle: 'Обе вкладки',
  matrix: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final tab in DsTab.values)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.s3),
          child: DsNavbar(active: tab, onChanged: (_) {}),
        ),
    ],
  ),
  notes: const [
    'Тень DS/Shadow/lg — таб-бар плавает над содержимым, а не лежит в потоке.',
  ],
);

// ---------------------------------------------------------------------------
// StatusBar
// ---------------------------------------------------------------------------

final statusBarPage = ComponentPage(
  name: 'DsStatusBar',
  figma: 'StatusBar · 113:166',
  doc: 'Системная строка. В продукте её рисует система; компонент нужен, '
      'чтобы витрина и макеты экранов совпадали по высоте и по цвету '
      'содержимого.',
  stage: Stage.sunken,
  props: [
    Prop(
      name: 'theme',
      type: 'DsStatusBarTheme',
      initial: DsStatusBarTheme.light,
      options: DsStatusBarTheme.values,
      doc: 'light — тёмное содержимое на светлом экране, dark — наоборот.',
    ),
  ],
  build: (context, a, set) {
    final theme = a.get<DsStatusBarTheme>('theme');
    return Container(
      width: 320,
      color: theme == DsStatusBarTheme.light
          ? S.surfaceDefault
          : S.surfaceOverlay,
      child: DsStatusBar(theme: theme),
    );
  },
  code: (a) => snippet('DsStatusBar', [
    'theme: DsStatusBarTheme.${a.get<DsStatusBarTheme>('theme').name}',
  ]),
);

// ---------------------------------------------------------------------------
// Handle
// ---------------------------------------------------------------------------

final handlePage = ComponentPage(
  name: 'DsHandle',
  figma: 'Handle · 301:741',
  doc: 'Ручка шторки. Пропсов нет: это единственная деталь, которая говорит '
      '«меня можно тянуть».',
  stage: Stage.sunken,
  props: const [],
  build: (context, a, set) => Container(
    width: 320,
    decoration: BoxDecoration(
      color: S.surfaceDefault,
      borderRadius: BorderRadius.circular(Radii.card),
      boxShadow: Shadows.sheet,
    ),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [DsHandle(), SizedBox(height: Space.s5)],
    ),
  ),
  code: (a) => snippet('DsHandle', const []),
);

// ---------------------------------------------------------------------------
// Icon
// ---------------------------------------------------------------------------

final iconPage = ComponentPage(
  name: 'DsIcon',
  figma: 'Icon · 68:14',
  doc: 'Заглушка глифа. Настоящие контуры Lucide в перенос ДС не входят — '
      'это отдельная задача про ассеты. Заглушка держит размер и цвет, чтобы '
      'раскладка была правдивой, и намеренно выглядит как заглушка: иначе её '
      'забудут заменить.',
  props: [
    Prop(
      name: 'name',
      type: 'DsIconName',
      initial: DsIconName.camera,
      options: DsIconName.values,
      doc: 'Один из 19 глифов.',
    ),
    const Prop(
      name: 'size',
      type: 'double',
      initial: 20.0,
      options: [16.0, 20.0, 24.0],
      doc: 'Сторона. По умолчанию 16.',
    ),
    const Prop(
      name: 'color',
      type: 'Color?',
      initial: null,
      kind: ControlKind.none,
      doc: 'Не передан — берётся из чернильного режима поддерева (DsInk).',
    ),
  ],
  build: (context, a, set) => DsIcon(
    a.get<DsIconName>('name'),
    size: a.get<double>('size'),
  ),
  code: (a) => snippet('DsIcon', [
    'DsIconName.${a.get<DsIconName>('name').name}',
    'size: ${a.get<double>('size').toStringAsFixed(0)}',
  ]),
  matrixTitle: 'Все 19 глифов',
  matrix: (context) => Wrap(
    spacing: Space.s5,
    runSpacing: Space.s4,
    children: [
      for (final name in DsIconName.values)
        SizedBox(
          width: 96,
          child: Column(
            children: [
              DsIcon(name, size: 20),
              const SizedBox(height: Space.s1),
              Mono(name.name),
            ],
          ),
        ),
    ],
  ),
  notes: const [
    'Иконки на тёмном и выключенные красятся режимом, а не поимённо: '
        'у разных глифов разное число кусков, и подмена оставила бы половину '
        'прежнего цвета.',
  ],
);

final foundationPages = <ComponentPage>[
  buttonPage,
  iconButtonPage,
  inputPage,
  badgePage,
  navbarPage,
  statusBarPage,
  handlePage,
  iconPage,
];
