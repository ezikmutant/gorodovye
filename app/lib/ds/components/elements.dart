// Секция UI Kit elements — продуктовые блоки, которые остаются частью ДС:
// Chip, FilterRow, Spoiler, FoundBadge, ToastError, InkStamp.
//
// Блоки, привязанные к карте, камере и альбому (MapMarker, You, MapFilters,
// TopControls, BottomControls, BottomAction, founded_object, My photos,
// Collection*), в этот перенос не вошли — см. `ds/flutter.md`.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../ink_mode.dart';
import '../tokens/motion.dart';
import '../tokens/primitives.dart';
import '../tokens/semantics.dart';
import '../tokens/shadows.dart';
import '../tokens/strings.dart';
import '../tokens/typography.dart';
import 'foundation.dart';

/// Множественный выбор. Figma `Chip` (`55:69`).
///
/// Форма кодирует тип выбора: чип-переключатель читается как «сколько угодно»,
/// галочка в списке — как «один из». Отдельной кнопки «сбросить» нет, выбор
/// снимается повторным тапом.
class DsChip extends StatefulWidget {
  const DsChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<DsChip> createState() => _DsChipState();
}

/// Состояние здесь только ради нажатия: чип — третий элемент, который
/// проседает под пальцем (`ds/motion.md`). Сам выбор компонент не хранит,
/// он приходит снаружи через [DsChip.selected].
class _DsChipState extends State<DsChip> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    // Невыбранный чип носит text-subtle, а не text-default: в панели фильтров
    // он спорил бы по весу со строками статуса, которые выше по смыслу.
    final ink = widget.selected ? InkMode.onDark : InkMode.light;
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? Motion.pressScale : 1,
        duration: _down ? Motion.pressIn : Motion.pressOut,
        curve: Motion.easeOut,
        child: AnimatedContainer(
          duration: _down ? Motion.pressIn : Motion.pressOut,
          curve: Motion.easeOut,
          // Высота не задана числом: 8 + строка 21 + 8 = 37, как в макете.
          // Прибитая высота разъехалась бы с подписью при другом кегле.
          padding: const EdgeInsets.symmetric(
              horizontal: Space.s4, vertical: Space.s2),
          decoration: BoxDecoration(
            color: widget.selected ? S.surfaceActionPrimary : S.surfaceSubtle,
            borderRadius: BorderRadius.circular(Radii.full),
          ),
          // Обводка рисуется поверх, а не рамкой: в Figma она внутренняя
          // (`strokeAlign: INSIDE`) и высоту не меняет — оба варианта ровно
          // 37. Border в decoration прибавился бы к размеру, и чип прыгал бы
          // на два пикселя при каждом тапе.
          foregroundDecoration: widget.selected
              ? null
              : BoxDecoration(
                  border: Border.all(color: S.borderDefault),
                  borderRadius: BorderRadius.circular(Radii.full),
                ),
          // Row вместо голого Text: он центрует подпись по высоте и сжимает
          // чип до содержимого. Container с alignment вместо этого растянул бы
          // его на всю строку.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label,
                  style: T.bodySmMedium.copyWith(
                      color: widget.selected
                          ? ink.textDefault
                          : InkMode.light.textSubtle)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Строка списка с галочкой. Figma `FilterRow` (`474:3542`), высота 44.
class DsFilterRow extends StatelessWidget {
  const DsFilterRow({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: Sizes.touchMin,
        padding: const EdgeInsets.symmetric(horizontal: Space.s4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                // Невыбранная строка приглушена (`text-subtle`), выбранная
                // чёрная: в макете это единственное, чем они отличаются
                // помимо галочки.
                style: T.bodyBase.copyWith(
                    color: selected
                        ? InkMode.light.textDefault
                        : InkMode.light.textSubtle),
              ),
            ),
            // Галочка тёмная, не акцентная: в макете у неё text-default.
            // Собственный зелёный цвет глифа тут перебивается явно — строка
            // отмечает выбор, а не сообщает об успехе.
            //
            // Зазор уезжает вместе с галочкой: он часть появляющегося куска,
            // иначе строка держала бы под неё пустое место.
            DsPop(
              visible: selected,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: Space.s3),
                  DsIcon(DsIconName.check, color: InkMode.light.textDefault),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum DsSpoilerKind { text, photo }

/// Скрытый блок. Figma `Spoiler` (`296:781`), строка 49 высотой.
///
/// Спойлер — ядро механики: он прячет то, что человек должен найти глазами,
/// а не прочитать заранее. Раскрытие обратимо: подсказку сворачивают, чтобы
/// она не мешала смотреть по сторонам, и открывают снова, когда нужна.
///
/// Это строка списка, а не карточка: значок в светлом кружке, подпись
/// `DS/Heading/lg` и линии `border-strong` сверху и снизу. Рамка вокруг
/// каждого спойлера спорила бы с карточкой находки, внутри которой он живёт.
///
/// **Шеврона нет.** В Figma (`296:740`) он остался булевым свойством,
/// выключенным по умолчанию, — в код не переносим. Управление показывает сам
/// значок: он меняет цвет вместе с раскрытием — графитовый у закрытого
/// (`296:734`, `ink-neutral`), терракотовый у раскрытого (`296:745`,
/// `icon-accent`).
class DsSpoiler extends StatefulWidget {
  const DsSpoiler({
    super.key,
    required this.title,
    this.kind = DsSpoilerKind.text,
    this.child,
    this.revealed = false,
    this.onToggle,
  });

  /// Подпись целиком, вместе со счётчиком: «Как выглядит · 3». Считать
  /// снимки — забота экрана, компонент печатает то, что дали.
  final String title;

  final DsSpoilerKind kind;

  /// Содержимое. Для [DsSpoilerKind.photo] сюда кладётся слот `Photos`.
  final Widget? child;

  final bool revealed;

  /// Открыли или закрыли. Экрану это нужно: содержимое спойлера бывает
  /// тяжёлым — снимки, — и появляться оно должно в момент раскрытия,
  /// а не заранее и не в закрытом виде.
  final ValueChanged<bool>? onToggle;

  @override
  State<DsSpoiler> createState() => _DsSpoilerState();
}

class _DsSpoilerState extends State<DsSpoiler>
    with SingleTickerProviderStateMixin {
  /// Всё раскрытие идёт от одного контроллера: высота, прозрачность и оборот
  /// значка — три взгляда на одну величину. Раздельные таймеры расходятся,
  /// это уже ловила проба (`test/motion_probe.dart`).
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.reveal,
    value: widget.revealed ? 1 : 0,
  );

  /// [FlippedCurve] на возврате — не украшение, а точность переноса.
  /// В motion-primitives закрытие проигрывает ту же кривую заново, от
  /// текущего значения к нулю: `1 − ease(t)`. Штатный `reverseCurve` во
  /// Flutter считает `ease(1 − t)` — то же уравнение задом наперёд, и
  /// закрытие начинается рывком. `FlippedCurve` возвращает первое.
  late final CurvedAnimation _t = CurvedAnimation(
    parent: _c,
    curve: Motion.easeReveal,
    reverseCurve: FlippedCurve(Motion.easeReveal),
  );

  bool get _open =>
      _c.status == AnimationStatus.forward ||
      _c.status == AnimationStatus.completed;

  void _toggle() {
    final next = !_open;
    next ? _c.forward() : _c.reverse();
    widget.onToggle?.call(next);
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  /// Значок говорит, что под спойлером: указатель — «где искать», глаз —
  /// «как выглядит». Глиф меняется целиком, режимом.
  DsIconName get _badge => switch (widget.kind) {
        DsSpoilerKind.text => DsIconName.sign,
        DsSpoilerKind.photo => DsIconName.eye,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DsRule(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: S.surfaceSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: Space.s6,
                        height: Space.s6,
                        child: Center(
                          // Цвет — часть перехода, а не отдельное событие:
                          // закрытый значок графитовый, раскрытый
                          // терракотовый, и терракота набирается ровно за то
                          // же время, что раскрывается содержимое. Это
                          // «цвет живёт в движении» (`ds/motion.md`), только
                          // здесь он не гаснет: раскрытый спойлер —
                          // состояние, а не вспышка.
                          //
                          // Оборота значка вокруг вертикальной оси здесь
                          // больше нет: собран 08.09.2026 и снят в тот же
                          // день — «микроанимации должны быть
                          // минималистичны, а тут бесячи». Спойлер
                          // открывают по нескольку раз на каждую находку,
                          // и заметный приём на такой частоте мешает.
                          child: AnimatedBuilder(
                            animation: _t,
                            builder: (context, _) => DsIcon(_badge,
                                color: Color.lerp(
                                    S.inkNeutral, S.iconAccent, _t.value)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.s2),
                    Expanded(
                      child: Text(widget.title,
                          style: T.headingLg
                              .copyWith(color: InkMode.light.textDefault)),
                    ),
                  ],
                ),
                // Раскрытие как в аккордеоне motion-primitives: высота от
                // нуля до собственной и прозрачность идут одной кривой и
                // одной длительностью. Одной высоты мало — содержимое
                // выезжает готовым и читается как рывок.
                //
                // Это переход, а не keyframes: анимацию можно прервать
                // в любой момент, и она продолжится с текущей высоты.
                if (widget.child != null)
                  SizeTransition(
                    sizeFactor: _t,
                    alignment: AlignmentDirectional.topStart,
                    child: FadeTransition(
                      opacity: _t,
                      child: Padding(
                        padding: const EdgeInsets.only(top: Space.s2),
                        child: widget.child,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Появление и исчезновение мелкого элемента внутри строки — галочки
/// в списке, крестика сброса.
///
/// Место под элемент открывается вместе с ним, а не появляется скачком:
/// `widthFactor` растёт от нуля, и соседи разъезжаются плавно. Ради этого
/// ширину знать не нужно — [Align] берёт её у ребёнка.
///
/// На входе — лёгкий перелёт (`ease-out-back`), на выходе его нет: перелёт
/// при исчезновении читается как сбой, а не как живость.
class DsPop extends StatelessWidget {
  /// Элемент всё время в дереве и прячется сам. Так стоит галочка в строке
  /// фильтра: место под неё есть всегда, меняется только ширина.
  const DsPop({
    super.key,
    required bool visible,
    required this.child,
    this.alignment = Alignment.centerRight,
  })  : _visible = visible,
        _animation = null;

  /// Анимацией управляет вызывающий. Нужен там, где элемент приходится
  /// держать в дереве руками — например в [Wrap], который ставит зазор
  /// между детьми независимо от их ширины и выкинутый элемент отдаёт
  /// скачком.
  ///
  /// Своим твином здесь не обойтись: элемент монтируется заново, а
  /// [TweenAnimationBuilder] без `begin` на первой сборке стартует сразу
  /// со значения `end` — то есть появляется мгновенно, целиком.
  const DsPop.driven({
    super.key,
    required Animation<double> animation,
    required this.child,
    this.alignment = Alignment.centerRight,
  })  : _visible = false,
        _animation = animation;

  final bool _visible;
  final Animation<double>? _animation;
  final Widget child;
  final Alignment alignment;

  Widget _frame(double t) => Align(
        alignment: alignment,
        // Перелёт кривой уводит t выше единицы — место под элемент от этого
        // дёргаться не должно, поэтому ширина зажата, а масштаб нет.
        widthFactor: t.clamp(0.0, 1.0),
        child: Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final animation = _animation;
    if (animation != null) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) => _frame(animation.value),
      );
    }
    // `begin` не задаём намеренно. С ним первая сборка проигрывает 1 → 0,
    // то есть элемент мелькает и исчезает, а следующее переключение
    // стартует уже с единицы и не двигается вовсе — проба поймала это
    // как «масштаб 1.000 → 1.000». Без `begin` первая сборка встаёт сразу
    // в нужное значение, а меняется только при смене состояния.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _visible ? 1.0 : 0.0),
      duration: _visible ? Motion.popIn : Motion.popOut,
      curve: _visible ? Motion.easeOutBack : Motion.easeOut,
      builder: (context, t, _) => _frame(t),
    );
  }
}

/// Разделитель списка. Отдельным именем, потому что его рисует и спойлер,
/// и контейнер под последним из них.
class DsRule extends StatelessWidget {
  const DsRule({super.key});

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: S.borderStrong, child: SizedBox(height: 1));
}

/// Контейнер на два спойлера подряд. Figma `Spoilers` (`296:782`).
class DsSpoilers extends StatelessWidget {
  const DsSpoilers({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Вплотную, без зазора: каждый спойлер несёт линию сверху, и промежуток
    // превратил бы список в стопку отдельных плашек. Последняя линия —
    // здесь: спойлер не знает, что он последний.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [...children, const DsRule()],
    );
  }
}

/// «НАЙДЕНО · 12.06.26». Figma `FoundBadge` (`308:2102`).
///
/// Отметка украшает факт, а не обозначает его: в альбоме лежит только
/// собранное, поэтому значок не кодирует статус (`ds/CONTRACT.md`).
///
/// Это оттиск, а не плашка статуса: рамка и текст одной краской, скругление
/// `radius-sm`. Заливная пилюля читалась бы как системный бейдж — тот же
/// жанр, что `DsBadge`, — и факт находки превратился бы в служебную пометку.
class DsFoundBadge extends StatelessWidget {
  const DsFoundBadge({
    super.key,
    required this.date,
    this.ink = S.inkPrimary,
    this.labelInk = S.inkSecondary,
  });

  /// Дата находки в виде «12.06.26». Форматирование — забота вызывающего:
  /// компонент ДС не знает про локали и часовые пояса.
  final String date;

  /// Краска рамки. Та же палитра, что у [DsInkStamp].
  final Color ink;

  /// Краска подписи. В макете (`308:2102`) она **другая**: рамка `ink-primary`,
  /// буквы `ink-secondary`. Так штампуют по-настоящему — рамка и текст стоят
  /// разными оттисками, и совпадение цветов выдало бы печать одной кнопкой.
  final Color labelInk;

  @override
  Widget build(BuildContext context) {
    // Прозрачность 85 % — из макета. Оттиск не ложится плашмя: краска
    // подсаживается, и сквозь неё видно, на чём он стоит.
    return Opacity(
      opacity: 0.85,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.s4, vertical: Space.s2),
        // Рамка поверх, а не в декорации: в Figma обводка внутренняя
        // и размер не меняет (247×44 при тексте 215×28 и полях по 16),
        // а `Border` в `decoration` во Flutter прибавляется к габариту.
        // Та же ловушка, что была у чипа.
        foregroundDecoration: BoxDecoration(
          // Рамка в два пикселя, а не в один: штамп прижимают, и линия
          // у него плотнее, чем у любой обводки интерфейса.
          border: Border.all(color: ink, width: 2),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child:
            Text('НАЙДЕНО · $date', style: T.labelXl.copyWith(color: labelInk)),
      ),
    );
  }
}

/// Только системные сбои. Figma `ToastError` (`434:6256`).
///
/// Успехи в продукте подтверждаются формой — штампом в шторке, снимком,
/// улетающим в кнопку альбома, — поэтому варианта `success` здесь нет и не
/// будет. Одна сущность на один сценарий.
class DsToastError extends StatefulWidget {
  const DsToastError({
    super.key,
    required this.message,
    this.actionLabel = L.retry,
    this.onAction,
    this.onDismiss,
    this.persistent = false,
  });

  /// Берётся из [M]: тексты сообщений живут переменными, а не набираются.
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  /// Как убрать плашку. Зовут её и таймер, и свайп вниз; экран по этому
  /// вызову убирает плашку из дерева. Не передали — плашка стоит вечно
  /// и не свайпается: так она живёт на витрине и в каталоге.
  final VoidCallback? onDismiss;

  /// Плашка о **состоянии**, а не о событии: сама не гаснет.
  ///
  /// «Нет сети» по таймеру исчезло бы, а сеть не появилась бы — человек
  /// остался бы с пустой картой без объяснения. Свайп при этом работает:
  /// убрать сообщение с глаз можно всегда.
  final bool persistent;

  @override
  State<DsToastError> createState() => _DsToastErrorState();
}

class _DsToastErrorState extends State<DsToastError>
    with SingleTickerProviderStateMixin {
  /// Высота первой строки сообщения — по ней равняются иконка и действие.
  static final _lineHeight = T.bodySm.fontSize! * T.bodySm.height!;

  Timer? _life;

  /// Приход и уход. Плашка приезжает снизу на свою высоту и проявляется;
  /// уходит тем же путём. Уходит **сама**, а не исчезает из дерева: экран
  /// узнаёт об этом из [DsToastError.onDismiss], который зовётся уже после
  /// движения. Иначе таймер срезал бы плашку кадром, притом что свайп её
  /// доводит плавно — один элемент уходил бы двумя разными способами.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: Motion.toastIn,
    reverseDuration: Motion.toastOut,
  );

  /// Сдвиг под пальцем. Только вниз: плашка приходит снизу, туда же и уходит,
  /// иначе свайп-закрытие перестаёт быть очевидным (`ds/motion.md`).
  double _drag = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _enter.forward();
    _arm();
  }

  @override
  void didUpdateWidget(DsToastError old) {
    super.didUpdateWidget(old);
    if (widget.persistent != old.persistent ||
        (widget.onDismiss == null) != (old.onDismiss == null) ||
        (widget.onAction == null) != (old.onAction == null) ||
        widget.message != old.message) {
      // Плашка уже уехала, а её не сняли с экрана, только поменяли повод —
      // значит показываем заново. Иначе она осталась бы в дереве невидимой
      // и неощупываемой: прозрачность ноль, сдвиг на всю высоту.
      if (_enter.status == AnimationStatus.dismissed) _enter.forward();
      _arm();
    }
  }

  /// Таймер заводится только если плашку есть кому убрать и она про событие.
  void _arm() {
    _life?.cancel();
    if (widget.onDismiss == null || widget.persistent) return;
    _life = Timer(
      widget.onAction == null ? Motion.toastLife : Motion.toastLifeAction,
      _leave,
    );
  }

  /// Уход по таймеру: сначала движение, потом сообщение экрану.
  void _leave() {
    _life?.cancel();
    if (!mounted) return;
    _enter.reverse().whenComplete(() {
      if (mounted) widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _life?.cancel();
    _enter.dispose();
    super.dispose();
  }

  /// Палец на плашке — отсчёт стоит. Пока это не было сделано, пять секунд
  /// могли истечь посреди жеста, и плашка исчезала из-под пальца.
  void _hold() {
    _life?.cancel();
    setState(() => _dragging = true);
  }

  void _end(DragEndDetails d) {
    setState(() => _dragging = false);
    final flick = (d.primaryVelocity ?? 0) > 300;
    if (_drag > 24 || flick) {
      // Палец уже вынес плашку — доводим её тем же движением и только потом
      // сообщаем экрану. Обратный ход `_enter` тут не нужен: он поехал бы
      // против жеста.
      _life?.cancel();
      setState(() => _drag = _outDistance);
    } else {
      // Не хватило: плашка возвращается на место, отсчёт начинается заново.
      setState(() => _drag = 0);
      _arm();
    }
  }

  /// Сдвиг, на котором плашка считается ушедшей: прозрачность к этому моменту
  /// уже ноль.
  static const _outDistance = 120.0;

  /// Приход и уход: плашка едет на свою высоту снизу и проявляется.
  /// Долей, а не пикселями, — сообщение бывает в одну строку и в две,
  /// и путь обязан считаться от того, что приехало.
  Widget _appear(Widget child) => AnimatedBuilder(
        animation: _shift,
        builder: (context, child) => FractionalTranslation(
          translation: Offset(0, 1 - _shift.value),
          child: Opacity(opacity: _shift.value.clamp(0.0, 1.0), child: child),
        ),
        child: child,
      );

  /// Уход проигрывает ту же кривую заново, а не её же задом наперёд:
  /// то же правило, что у спойлера.
  late final Animation<double> _shift = CurvedAnimation(
    parent: _enter,
    curve: Motion.easeOut,
    reverseCurve: FlippedCurve(Motion.easeOut),
  );

  @override
  Widget build(BuildContext context) {
    final plate = _appear(_plate());
    if (widget.onDismiss == null) return plate;
    return GestureDetector(
      onVerticalDragStart: (_) => _hold(),
      onVerticalDragUpdate: (d) =>
          setState(() => _drag = math.max(0, _drag + d.delta.dy)),
      onVerticalDragEnd: _end,
      // Пока палец ведёт — без задержки, плашка идёт след в след.
      // Отпустили и не хватило — возврат за 200 мс, как у любого отката.
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _drag),
        duration: _dragging ? Duration.zero : Motion.toastOut,
        curve: Motion.easeOut,
        // Довели до конца — только теперь экран убирает плашку из дерева.
        onEnd: () {
          if (_drag >= _outDistance) widget.onDismiss?.call();
        },
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: (1 - value / _outDistance).clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: plate,
      ),
    );
  }

  Widget _plate() {
    return DsInk(
      mode: InkMode.onDark,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.s4, vertical: Space.s3),
        decoration: BoxDecoration(
          color: S.bgError,
          borderRadius: BorderRadius.circular(Radii.base),
          boxShadow: Shadows.md,
        ),
        // Сообщение переносится на две строки, поэтому иконка и действие
        // равняются по верху, а не по середине блока: в макете значок стоит
        // против первой строки. Высота коробки под иконку — высота строки,
        // внутри неё глиф центрован, и на однострочном сообщении это
        // выглядит так же, как раньше.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Цвет глифу не задаём: `warning` носит свой, жёлтый, и на
            // красной плашке он таким и остаётся — как в макете.
            SizedBox(
              height: _lineHeight,
              child: const Center(child: DsIcon(DsIconName.warning)),
            ),
            const SizedBox(width: Space.s2),
            Expanded(
              child: Text(widget.message,
                  style: T.bodySm.copyWith(color: InkMode.onDark.textDefault)),
            ),
            if (widget.onAction != null) ...[
              // Зазор до действия 12, а не 8: в макете внешний gap плашки
              // больше внутреннего, которым значок отбит от текста.
              const SizedBox(width: Space.s3),
              _ToastAction(
                label: widget.actionLabel,
                onTap: widget.onAction!,
                height: _lineHeight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum DsStampForm { round, signature, block }

/// Оттиск с датой находки. Figma `InkStamp` (`29:72`).
///
/// Здесь только форма и краска. Постановка штампа — событие с анимацией, и
/// живёт она в `ds/motion.md`: это единственная награда продукта, и её нельзя
/// собирать по месту.
/// Действие на плашке сбоя — «Повторить».
///
/// Отвечает на палец, как и всё остальное в системе: просадка `scale(0.97)`,
/// 120 мс на вход и 180 на возврат. Заливки нет по той же причине, что
/// у призрачной кнопки: плашка уже цветная, и терракота на красном —
/// не акцент, а грязь. Вместо неё подпись притухает.
///
/// Область нажатия — вся коробка подписи (`HitTestBehavior.opaque`),
/// а не буквы: попадать надо в действие, а не в глиф.
class _ToastAction extends StatefulWidget {
  const _ToastAction({
    required this.label,
    required this.onTap,
    required this.height,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  State<_ToastAction> createState() => _ToastActionState();
}

class _ToastActionState extends State<_ToastAction> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final duration = _down ? Motion.pressIn : Motion.pressOut;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? Motion.pressScale : 1,
        duration: duration,
        curve: Motion.easeOut,
        child: AnimatedOpacity(
          opacity: _down ? 0.7 : 1,
          duration: duration,
          curve: Motion.easeOut,
          child: SizedBox(
            height: widget.height,
            child: Center(
              child: Text(widget.label,
                  style: T.bodySmMedium
                      .copyWith(color: InkMode.onDark.textDefault)),
            ),
          ),
        ),
      ),
    );
  }
}

class DsInkStamp extends StatelessWidget {
  const DsInkStamp({
    super.key,
    required this.date,
    this.form = DsStampForm.round,
    this.ink = S.inkPrimary,
  });

  final String date;
  final DsStampForm form;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final label = Text(date, style: T.labelSm.copyWith(color: ink));

    return switch (form) {
      DsStampForm.round => Container(
          width: Space.s20,
          height: Space.s20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ink, width: 2),
          ),
          child: label,
        ),
      DsStampForm.block => Container(
          // Поля 16/8 и радиус `sm`: в макете этот оттиск — инстанс
          // `FoundBadge`, а не самостоятельная рамка (`29:72`).
          padding: const EdgeInsets.symmetric(
              horizontal: Space.s4, vertical: Space.s2),
          decoration: BoxDecoration(
            border: Border.all(color: ink, width: 2),
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: label,
        ),
      DsStampForm.signature => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Росчерк **над** датой, а не подчёркивание под ней: скруглённая
            // полоска 3 пикселя во всю ширину оттиска, зазор 4 (`29:72`).
            // Так штампуют — сначала мазок, потом число.
            Container(
              width: 88,
              height: 3,
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(Radii.full),
              ),
            ),
            const SizedBox(height: Space.s1),
            label,
          ],
        ),
    };
  }
}
