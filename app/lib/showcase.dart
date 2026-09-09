// Витрина: всё, что перенеслось из Figma, на одной прокручиваемой странице.
//
// Нужна для сверки глазами рядом с макетом. Экранов продукта здесь нет —
// только токены и компоненты.

import 'package:flutter/widgets.dart';

import 'ds/ds.dart';

class Showcase extends StatelessWidget {
  const Showcase({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: S.surfaceDefault,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.s5),
          children: const [
            _Title('Дизайн-система «Городовых»'),
            _Note('Зеркало Figma-файла, страница UI. Имена — те же.'),
            SizedBox(height: Space.s8),
            _Palette(),
            SizedBox(height: Space.s8),
            _TypeScale(),
            SizedBox(height: Space.s8),
            _ShadowRow(),
            SizedBox(height: Space.s8),
            _Buttons(),
            SizedBox(height: Space.s8),
            _IconButtons(),
            SizedBox(height: Space.s8),
            _Elements(),
            SizedBox(height: Space.s20),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Служебное оформление самой витрины
// --------------------------------------------------------------------------

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: T.heading2xl.copyWith(color: InkMode.light.textDefault));
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: T.headingXl.copyWith(color: InkMode.light.textDefault)),
        const SizedBox(height: Space.s4),
        child,
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Space.s1),
        child: Text(text,
            style: T.bodySm.copyWith(color: InkMode.light.textMuted)),
      );
}

// --------------------------------------------------------------------------
// Палитра
// --------------------------------------------------------------------------

class _Palette extends StatelessWidget {
  const _Palette();

  static const _surfaces = <String, Color>{
    'surface-default': S.surfaceDefault,
    'surface-subtle': S.surfaceSubtle,
    'surface-sunken': S.surfaceSunken,
    'surface-action-primary': S.surfaceActionPrimary,
    'surface-action-secondary': S.surfaceActionSecondary,
    'surface-action-pressed': S.surfaceActionPressed,
    'surface-action-disabled': S.surfaceActionDisabled,
    'surface-accent': S.surfaceAccent,
    'surface-accent-subtle': S.surfaceAccentSubtle,
    'surface-overlay': S.surfaceOverlay,
    'surface-glass': S.surfaceGlass,
    'surface-glass-pressed': S.surfaceGlassPressed,
    'surface-dim': S.surfaceDim,
    'surface-paper': S.surfacePaper,
    'surface-paper-edge': S.surfacePaperEdge,
    'surface-tile-sage': S.surfaceTileSage,
    'surface-tile-blush': S.surfaceTileBlush,
    'surface-tile-sky': S.surfaceTileSky,
    'surface-tile-sun': S.surfaceTileSun,
  };

  static const _rest = <String, Color>{
    'text-on-action': S.textOnAction,
    'text-accent': S.textAccent,
    'text-error': S.textError,
    'text-disabled': S.textDisabled,
    'text-link': S.textLink,
    'border-default': S.borderDefault,
    'border-strong': S.borderStrong,
    'border-accent': S.borderAccent,
    'border-error': S.borderError,
    'border-paper-rule': S.borderPaperRule,
    'bg-success': S.bgSuccess,
    'bg-warning': S.bgWarning,
    'bg-error': S.bgError,
    'bg-info': S.bgInfo,
    'ink-primary': S.inkPrimary,
    'ink-secondary': S.inkSecondary,
    'ink-tertiary': S.inkTertiary,
    'ink-neutral': S.inkNeutral,
  };

  @override
  Widget build(BuildContext context) {
    return _Section(
      'Смысловые цвета',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.s2,
            runSpacing: Space.s2,
            children: [
              for (final e in _surfaces.entries) _Swatch(e.key, e.value),
              for (final e in _rest.entries) _Swatch(e.key, e.value),
            ],
          ),
          const SizedBox(height: Space.s5),
          const _Note('Три чернильных режима меняют ровно три токена:'),
          const SizedBox(height: Space.s2),
          Row(
            children: [
              for (final m in InkMode.values) ...[
                Expanded(child: _InkModeCard(m)),
                const SizedBox(width: Space.s2),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
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
              style: T.bodyXs.copyWith(color: InkMode.light.textMuted)),
        ],
      ),
    );
  }
}

class _InkModeCard extends StatelessWidget {
  const _InkModeCard(this.mode);
  final InkMode mode;

  @override
  Widget build(BuildContext context) {
    final onDark = mode == InkMode.onDark;
    return Container(
      padding: const EdgeInsets.all(Space.s3),
      decoration: BoxDecoration(
        color: onDark ? S.surfaceOverlay : S.surfaceSubtle,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mode.name, style: T.labelXs.copyWith(color: mode.textMuted)),
          const SizedBox(height: Space.s2),
          Text('default', style: T.bodySm.copyWith(color: mode.textDefault)),
          Text('subtle', style: T.bodySm.copyWith(color: mode.textSubtle)),
          Text('muted', style: T.bodySm.copyWith(color: mode.textMuted)),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Шкала текста и тени
// --------------------------------------------------------------------------

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    return _Section(
      'Текстовые стили (15)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in T.all.entries) ...[
            Text('Городовые ходят по крышам',
                style: e.value.copyWith(color: InkMode.light.textDefault)),
            Text(e.key,
                style: T.bodyXs.copyWith(color: InkMode.light.textMuted)),
            const SizedBox(height: Space.s3),
          ],
        ],
      ),
    );
  }
}

class _ShadowRow extends StatelessWidget {
  const _ShadowRow();

  @override
  Widget build(BuildContext context) {
    return _Section(
      'Тени (5)',
      child: Wrap(
        spacing: Space.s5,
        runSpacing: Space.s5,
        children: [
          for (final e in Shadows.all.entries)
            Column(
              children: [
                Container(
                  width: Space.s16,
                  height: Space.s16,
                  decoration: BoxDecoration(
                    color: S.surfaceDefault,
                    borderRadius: BorderRadius.circular(Radii.md),
                    boxShadow: e.value,
                  ),
                ),
                const SizedBox(height: Space.s2),
                Text(e.key.split('/').last,
                    style: T.bodyXs.copyWith(color: InkMode.light.textMuted)),
              ],
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Компоненты
// --------------------------------------------------------------------------

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    return _Section(
      'Button — 27 ячеек',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final size in DsButtonSize.values) ...[
            Text(size.name,
                style: T.labelXs.copyWith(color: InkMode.light.textMuted)),
            const SizedBox(height: Space.s2),
            for (final type in DsButtonType.values) ...[
              Wrap(
                spacing: Space.s2,
                runSpacing: Space.s2,
                children: [
                  for (final st in DsState.values)
                    DsButton(
                      label: L.found,
                      type: type,
                      size: size,
                      forceState: st,
                      onPressed: () {},
                    ),
                ],
              ),
              const SizedBox(height: Space.s2),
            ],
            const SizedBox(height: Space.s4),
          ],
          const _Note('Свойство Subtitle — вторая строка на самой кнопке:'),
          const SizedBox(height: Space.s2),
          DsButton(
            label: L.trustMe,
            subtitle: L.gpsFar,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _IconButtons extends StatelessWidget {
  const _IconButtons();

  @override
  Widget build(BuildContext context) {
    return _Section(
      'IconButton — 22 ячейки',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final size in DsIconButtonSize.values) ...[
            Text(size.name,
                style: T.labelXs.copyWith(color: InkMode.light.textMuted)),
            const SizedBox(height: Space.s2),
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s2,
              children: [
                for (final type in DsIconButtonType.values)
                  for (final st in DsState.values)
                    // У glass состояния disabled нет — ячейки в матрице тоже.
                    if (!(type == DsIconButtonType.glass &&
                        st == DsState.disabled))
                      DsIconButton(
                        icon: DsIconName.camera,
                        type: type,
                        size: size,
                        forceState: st,
                        onPressed: () {},
                      ),
              ],
            ),
            const SizedBox(height: Space.s4),
          ],
        ],
      ),
    );
  }
}

class _Elements extends StatelessWidget {
  const _Elements();

  @override
  Widget build(BuildContext context) {
    return _Section(
      'Элементы',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DsInput(placeholder: 'Поле ввода'),
          const SizedBox(height: Space.s2),
          const DsInput(placeholder: 'Ошибка', error: true),
          const SizedBox(height: Space.s2),
          const DsInput(placeholder: 'Выключено', state: DsState.disabled),
          const SizedBox(height: Space.s5),
          Wrap(
            spacing: Space.s2,
            children: [
              for (final v in DsBadgeVariant.values)
                DsBadge(label: v.name, variant: v),
            ],
          ),
          const SizedBox(height: Space.s5),
          Wrap(
            spacing: Space.s2,
            children: [
              DsChip(label: 'Без коллекции', onTap: () {}),
              DsChip(label: 'Выбрано', selected: true, onTap: () {}),
            ],
          ),
          const SizedBox(height: Space.s5),
          DsFilterRow(label: 'Все', selected: true, onTap: () {}),
          DsFilterRow(label: 'Не найденные', onTap: () {}),
          const SizedBox(height: Space.s5),
          const DsSpoilers(children: [
            DsSpoiler(title: 'Где искать'),
            DsSpoiler(title: 'Как выглядит', kind: DsSpoilerKind.photo),
          ]),
          const SizedBox(height: Space.s5),
          const DsFoundBadge(date: '12.06.26'),
          const SizedBox(height: Space.s5),
          DsToastError(message: M.offlineMap, onAction: () {}),
          const SizedBox(height: Space.s5),
          Wrap(
            spacing: Space.s5,
            runSpacing: Space.s5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final f in DsStampForm.values)
                DsInkStamp(date: '12.06.26', form: f),
            ],
          ),
          const SizedBox(height: Space.s5),
          const DsHandle(),
          const SizedBox(height: Space.s5),
          Align(
            alignment: Alignment.center,
            child: DsNavbar(active: DsTab.map, onChanged: (_) {}),
          ),
        ],
      ),
    );
  }
}
