// Оформление каталога: навигация, стенд, панель контролов, таблица пропсов,
// сниппет кода.
//
// Само оформление — служебное, продуктом оно не является. Но собрано оно на
// тех же токенах: каталог, нарисованный мимо своей же системы, выглядит как
// чужой инструмент, в который систему положили.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../ds/ds.dart';
import 'model.dart';

/// Ширина, ниже которой навигация уезжает в выдвижную панель.
const double _narrow = 900;
const double _navWidth = 264;

/// Моноширинный текст для сниппетов.
///
/// В проекте моноширинной гарнитуры нет: обе свои — пропорциональные, а
/// системные шрифты веб-сборке недоступны, там рисует только то, что загружено.
/// Поэтому цепочка заканчивается на Onest: где системный моноширинный найдётся
/// (десктоп, мобильная сборка) — код будет моноширинным, где нет — он останется
/// читаемым, а не превратится в квадраты. Ставить ради этого третий шрифт
/// в сборку не стали.
const _mono = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: [
    'Menlo',
    'Consolas',
    'Courier New',
    FontFamily.sans,
  ],
  fontSize: 13,
  height: 1.55,
);

class CatalogApp extends StatelessWidget {
  const CatalogApp({super.key, required this.sections});

  final List<Section> sections;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Каталог ДС «Городовые»',
      color: S.surfaceDefault,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.ltr,
        child: CatalogShell(sections: sections),
      ),
    );
  }
}

class CatalogShell extends StatefulWidget {
  const CatalogShell({super.key, required this.sections});

  final List<Section> sections;

  @override
  State<CatalogShell> createState() => _CatalogShellState();
}

class _CatalogShellState extends State<CatalogShell> {
  late Entry _selected = widget.sections.first.entries.first;
  bool _navOpen = false;

  void _select(Entry e) => setState(() {
        _selected = e;
        _navOpen = false;
      });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: S.surfaceDefault,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _narrow;
            final body = _EntryView(key: ValueKey(_selected), entry: _selected);

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: _navWidth,
                    child: _Nav(
                      sections: widget.sections,
                      selected: _selected,
                      onSelect: _select,
                    ),
                  ),
                  Expanded(child: body),
                ],
              );
            }

            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(
                      title: _selected.title,
                      onMenu: () => setState(() => _navOpen = !_navOpen),
                    ),
                    Expanded(child: body),
                  ],
                ),
                if (_navOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _navOpen = false),
                      child: ColoredBox(
                        color: S.surfaceDim,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: _navWidth,
                            child: _Nav(
                              sections: widget.sections,
                              selected: _selected,
                              onSelect: _select,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onMenu});

  final String title;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.s4, vertical: Space.s2),
      decoration: const BoxDecoration(
        color: S.surfaceSubtle,
        border: Border(bottom: BorderSide(color: S.borderDefault)),
      ),
      child: Row(
        children: [
          DsIconButton(
            icon: DsIconName.slidersHorizontal,
            type: DsIconButtonType.ghost,
            size: DsIconButtonSize.sm,
            onPressed: onMenu,
          ),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Text(title,
                style: T.labelBase.copyWith(color: InkMode.light.textDefault)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Навигация
// ---------------------------------------------------------------------------

class _Nav extends StatelessWidget {
  const _Nav({
    required this.sections,
    required this.selected,
    required this.onSelect,
  });

  final List<Section> sections;
  final Entry selected;
  final ValueChanged<Entry> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: S.surfaceSubtle,
        border: Border(right: BorderSide(color: S.borderDefault)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.s3, vertical: Space.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: Space.s2, right: Space.s2, bottom: Space.s1),
              child: Text('Каталог ДС',
                  style: T.headingLg
                      .copyWith(color: InkMode.light.textDefault)),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: Space.s2, right: Space.s2, bottom: Space.s4),
              child: Text('«Городовые» · зеркало Figma',
                  style: T.bodyXs.copyWith(color: InkMode.light.textMuted)),
            ),
            for (final section in sections) ...[
              Padding(
                padding: const EdgeInsets.only(
                    left: Space.s2, top: Space.s3, bottom: Space.s2),
                child: Text(section.title.toUpperCase(),
                    style: T.labelXs.copyWith(color: InkMode.light.textMuted)),
              ),
              for (final entry in section.entries)
                _NavItem(
                  entry: entry,
                  active: identical(entry, selected),
                  onTap: () => onSelect(entry),
                ),
            ],
            const SizedBox(height: Space.s8),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.entry,
    required this.active,
    required this.onTap,
  });

  final Entry entry;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ink = widget.active ? InkMode.onDark : InkMode.light;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Motion.pressIn,
          curve: Motion.easeOut,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(
              horizontal: Space.s2, vertical: Space.s2),
          decoration: BoxDecoration(
            color: widget.active
                ? S.surfaceActionPrimary
                : _hover
                    ? S.surfaceSunken
                    : const Color(0x00000000),
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.entry.title,
                  style: T.bodySmMedium.copyWith(color: ink.textDefault)),
              if (widget.entry.subtitle.isNotEmpty)
                Text(widget.entry.subtitle,
                    style: T.bodyXs.copyWith(color: ink.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Страница
// ---------------------------------------------------------------------------

class _EntryView extends StatelessWidget {
  const _EntryView({super.key, required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
    return switch (entry) {
      ComponentEntry(:final page) => ComponentView(page: page),
      DocEntry(:final page) => ListView(
          padding: const EdgeInsets.all(Space.s6),
          children: [
            CatalogHeading(page.title, doc: page.doc),
            const SizedBox(height: Space.s6),
            Builder(builder: page.body),
            const SizedBox(height: Space.s20),
          ],
        ),
    };
  }
}

/// Страница компонента: стенд, пресеты, контролы, сниппет, таблица пропсов,
/// матрица вариантов.
class ComponentView extends StatefulWidget {
  const ComponentView({super.key, required this.page});

  final ComponentPage page;

  @override
  State<ComponentView> createState() => _ComponentViewState();
}

class _ComponentViewState extends State<ComponentView> {
  late Map<String, Object?> _values = {
    for (final p in widget.page.props) p.name: p.initial,
  };
  String? _preset;

  void _set(String name, Object? value) => setState(() {
        _values[name] = value;
        _preset = null;
      });

  void _apply(Preset preset) => setState(() {
        _values = {
          for (final p in widget.page.props) p.name: p.initial,
          ...preset.args,
        };
        _preset = preset.name;
      });

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final args = Args(_values);

    return ListView(
      padding: const EdgeInsets.all(Space.s6),
      children: [
        CatalogHeading(page.name, doc: page.doc, tag: page.figma),
        const SizedBox(height: Space.s6),
        StageBox(
          stage: page.stage,
          // Ключ по значениям: компоненты, которые держат состояние внутри
          // (спойлер), должны пересобираться, когда проп в панели меняют.
          child: KeyedSubtree(
            key: ValueKey(_values.toString()),
            child: page.build(context, args, _set),
          ),
        ),
        if (page.presets.isNotEmpty) ...[
          const SizedBox(height: Space.s4),
          Wrap(
            spacing: Space.s2,
            runSpacing: Space.s2,
            children: [
              for (final preset in page.presets)
                DsChip(
                  label: preset.name,
                  selected: preset.name == _preset,
                  onTap: () => _apply(preset),
                ),
            ],
          ),
          if (_preset != null)
            for (final preset in page.presets)
              if (preset.name == _preset && preset.doc.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.s2),
                  child: CatalogNote(preset.doc),
                ),
        ],
        if (page.props.isNotEmpty) ...[
          const SizedBox(height: Space.s6),
          CatalogBlock(
            'Контролы',
            doc: 'Крутятся живьём — стенд перерисовывается сразу.',
            child: _Controls(props: page.props, values: _values, onSet: _set),
          ),
        ],
        const SizedBox(height: Space.s6),
        CatalogBlock(
          'Код',
          doc: 'То, что вставляют в экран. Меняется вместе с контролами.',
          child: CodeBlock(page.code(args)),
        ),
        if (page.props.isNotEmpty) ...[
          const SizedBox(height: Space.s6),
          CatalogBlock('Пропсы', child: _PropsTable(page.props)),
        ],
        if (page.notes.isNotEmpty) ...[
          const SizedBox(height: Space.s6),
          CatalogBlock(
            'Оговорки',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final note in page.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s2),
                    child: CatalogNote('· $note'),
                  ),
              ],
            ),
          ),
        ],
        if (page.matrix != null) ...[
          const SizedBox(height: Space.s6),
          CatalogBlock(
            page.matrixTitle,
            doc: page.matrixDoc,
            child: Builder(builder: page.matrix!),
          ),
        ],
        const SizedBox(height: Space.s20),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Контролы
// ---------------------------------------------------------------------------

class _Controls extends StatelessWidget {
  const _Controls({
    required this.props,
    required this.values,
    required this.onSet,
  });

  final List<Prop> props;
  final Map<String, Object?> values;
  final ArgSetter onSet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final prop in props)
          if (prop.kind != ControlKind.none)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 132,
                    child: Padding(
                      padding: const EdgeInsets.only(top: Space.s1),
                      child: Text(prop.name,
                          style: _mono.copyWith(
                              color: InkMode.light.textDefault)),
                    ),
                  ),
                  Expanded(
                    child: switch (prop.kind) {
                      ControlKind.radio => _RadioControl(
                          prop: prop,
                          value: values[prop.name],
                          onSet: onSet,
                        ),
                      ControlKind.toggle => _ToggleControl(
                          prop: prop,
                          value: values[prop.name] as bool,
                          onSet: onSet,
                        ),
                      ControlKind.text => _TextControl(
                          prop: prop,
                          value: values[prop.name] as String,
                          onSet: onSet,
                        ),
                      ControlKind.none => const SizedBox.shrink(),
                    },
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _RadioControl extends StatelessWidget {
  const _RadioControl({
    required this.prop,
    required this.value,
    required this.onSet,
  });

  final Prop prop;
  final Object? value;
  final ArgSetter onSet;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      children: [
        for (final option in prop.options)
          DsChip(
            label: prop.show(option),
            selected: option == value,
            onTap: () => onSet(prop.name, option),
          ),
      ],
    );
  }
}

class _ToggleControl extends StatelessWidget {
  const _ToggleControl({
    required this.prop,
    required this.value,
    required this.onSet,
  });

  final Prop prop;
  final bool value;
  final ArgSetter onSet;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DsChip(
        label: value ? 'true' : 'false',
        selected: value,
        onTap: () => onSet(prop.name, !value),
      ),
    );
  }
}

class _TextControl extends StatefulWidget {
  const _TextControl({
    required this.prop,
    required this.value,
    required this.onSet,
  });

  final Prop prop;
  final String value;
  final ArgSetter onSet;

  @override
  State<_TextControl> createState() => _TextControlState();
}

class _TextControlState extends State<_TextControl> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  late final FocusNode _focus = FocusNode()..addListener(_repaint);

  void _repaint() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_repaint);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.pressIn,
      curve: Motion.easeOut,
      height: Sizes.touchMin,
      padding: const EdgeInsets.symmetric(horizontal: Space.s3),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: S.surfaceDefault,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(
            color: _focus.hasFocus ? S.borderFocusRing : S.borderDefault),
      ),
      child: EditableText(
        controller: _controller,
        focusNode: _focus,
        style: _mono.copyWith(color: InkMode.light.textDefault),
        cursorColor: S.borderFocusRing,
        backgroundCursorColor: S.borderDefault,
        selectionColor: S.surfaceAccentSubtle,
        onChanged: (v) => widget.onSet(widget.prop.name, v),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Таблица пропсов и сниппет
// ---------------------------------------------------------------------------

class _PropsTable extends StatelessWidget {
  const _PropsTable(this.props);

  final List<Prop> props;

  @override
  Widget build(BuildContext context) {
    return CatalogTable(
      columns: const ['Проп', 'Тип', 'По умолчанию', 'Что делает'],
      flex: const [3, 4, 3, 8],
      rows: [
        for (final prop in props)
          [
            Text(prop.name,
                style: _mono.copyWith(color: InkMode.light.textDefault)),
            Text(prop.type,
                style: _mono.copyWith(color: S.textAccent)),
            Text(prop.show(prop.initial),
                style: T.bodyXs.copyWith(color: InkMode.light.textSubtle)),
            Text(prop.doc,
                style: T.bodyXs.copyWith(color: InkMode.light.textMuted)),
          ],
      ],
    );
  }
}

/// Сниппет с кнопкой «Копировать» — то, ради чего в директиве стоит autodocs.
class CodeBlock extends StatefulWidget {
  const CodeBlock(this.code, {super.key});

  final String code;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: S.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: S.borderPaperRule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Space.s4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(widget.code,
                  style: _mono.copyWith(color: InkMode.light.textDefault)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: Space.s4, right: Space.s4, bottom: Space.s4),
            child: Row(
              children: [
                DsButton(
                  label: _copied ? 'Скопировано' : 'Копировать',
                  type: DsButtonType.secondary,
                  size: DsButtonSize.sm,
                  icon: _copied ? DsIconName.check : DsIconName.download,
                  onPressed: _copy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Общие детали оформления — ими же пользуются страницы токенов
// ---------------------------------------------------------------------------

class CatalogHeading extends StatelessWidget {
  const CatalogHeading(this.title, {super.key, this.doc = '', this.tag = ''});

  final String title;
  final String doc;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: T.heading2xl.copyWith(color: InkMode.light.textDefault)),
        if (tag.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.s1),
            child: Text('Figma · $tag',
                style: _mono.copyWith(color: S.textAccent)),
          ),
        if (doc.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.s3),
            child: SizedBox(
              width: 720,
              child: Text(doc,
                  style: T.bodyBase.copyWith(color: InkMode.light.textSubtle)),
            ),
          ),
      ],
    );
  }
}

class CatalogBlock extends StatelessWidget {
  const CatalogBlock(this.title,
      {super.key, this.doc = '', required this.child});

  final String title;
  final String doc;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: T.headingLg.copyWith(color: InkMode.light.textDefault)),
        if (doc.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.s1),
            child: CatalogNote(doc),
          ),
        const SizedBox(height: Space.s3),
        child,
      ],
    );
  }
}

class CatalogNote extends StatelessWidget {
  const CatalogNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 720,
        child: Text(text,
            style: T.bodySm.copyWith(color: InkMode.light.textMuted)),
      );
}

/// Моноширинная подпись — имена токенов, значения, куски кода в строке.
class Mono extends StatelessWidget {
  const Mono(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(text,
      style: _mono.copyWith(
          fontSize: 12, color: color ?? InkMode.light.textMuted));
}

class CatalogTable extends StatelessWidget {
  const CatalogTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.flex,
  });

  final List<String> columns;
  final List<List<Widget>> rows;
  final List<int> flex;

  @override
  Widget build(BuildContext context) {
    Widget cells(List<Widget> row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < row.length; i++)
                Expanded(
                  flex: flex[i],
                  child: Padding(
                    padding: const EdgeInsets.only(right: Space.s3),
                    child: row[i],
                  ),
                ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: S.borderStrong)),
          ),
          child: cells([
            for (final c in columns)
              Text(c, style: T.labelXs.copyWith(color: InkMode.light.textMuted))
          ]),
        ),
        for (final row in rows)
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: S.borderDefault)),
            ),
            child: cells(row),
          ),
      ],
    );
  }
}

/// Стенд с фоном под задачу.
class StageBox extends StatelessWidget {
  const StageBox({super.key, required this.child, this.stage = Stage.plain});

  final Widget child;
  final Stage stage;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.all(Space.s6),
      alignment: Alignment.center,
      child: child,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: switch (stage) {
            Stage.plain => S.surfaceDefault,
            Stage.sunken => S.surfaceSunken,
            Stage.dark => S.surfaceOverlay,
            Stage.map => S.surfaceTileSage,
          },
          border: Border.all(color: S.borderDefault),
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: stage == Stage.map
            ? Stack(children: [const Positioned.fill(child: _MapHint()), content])
            : content,
      ),
    );
  }
}

/// Намёк на карту под стеклянными кнопками: без пёстрого фона `surface-glass`
/// неотличим от белого, и весь смысл типа теряется.
class _MapHint extends StatelessWidget {
  const _MapHint();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MapHintPainter());
  }
}

class _MapHintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = S.surfacePaper
      ..strokeWidth = 14;
    final thin = Paint()
      ..color = S.surfaceTileSun
      ..strokeWidth = 6;

    canvas.drawLine(
        Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.3), road);
    canvas.drawLine(
        Offset(size.width * 0.25, 0), Offset(size.width * 0.4, size.height), road);
    canvas.drawLine(Offset(size.width * 0.6, 0),
        Offset(size.width * 0.75, size.height), thin);
  }

  @override
  bool shouldRepaint(_MapHintPainter oldDelegate) => false;
}
