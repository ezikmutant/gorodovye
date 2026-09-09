// Секция Foundation каталога: Button, IconButton, Input, Badge, Navbar,
// StatusBar, Handle. Плюс Icon-заглушка.
//
// Матрицы вариантов повторяют Figma один в один. Прибитых значений нет:
// всё через токены (`ds/CONTRACT.md`, главное правило).

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../ink_mode.dart';
import '../tokens/motion.dart';
import '../tokens/primitives.dart';
import '../tokens/semantics.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';
import 'icon_names.dart';
import 'icon_paths.dart';

export 'icon_names.dart';

/// Состояние управляющего элемента.
///
/// Figma называет первое `default`; в Dart это ключевое слово, поэтому здесь
/// [normal]. Остальные имена совпадают.
enum DsState { normal, pressed, disabled }

enum DsButtonType { primary, secondary, ghost }

enum DsButtonSize { lg, md, sm }

/// Геометрия размеров — снята с Figma по узлам `29:4` / `328:2084` / `77:16`.
extension on DsButtonSize {
  double get height => switch (this) {
        DsButtonSize.lg => 56,
        DsButtonSize.md => 48,
        DsButtonSize.sm => Sizes.touchMin,
      };

  double get padH => switch (this) {
        DsButtonSize.lg => Space.s6,
        DsButtonSize.md => Space.s5,
        DsButtonSize.sm => Space.s4,
      };

  TextStyle get labelStyle => switch (this) {
        DsButtonSize.lg => T.labelLg,
        DsButtonSize.md => T.labelSm,
        DsButtonSize.sm => T.labelSm,
      };
}

/// Заливка от точки нажатия.
///
/// Нажатое состояние приходит не вспышкой по всей кнопке, а пятном, которое
/// расходится из-под пальца и накрывает кнопку целиком. Пятно доходит до
/// дальнего угла, поэтому у края оно идёт быстрее — и это правильно:
/// расстояние, а не время, говорит, откуда началось.
///
/// **Край жёсткий, рост равномерный.** Первая сборка читалась не пятном,
/// а резкой протиркой поперёк кнопки — но виновата была кривая, а не край:
/// `ease-out` здесь почти экспонента и проходит четыре пятых пути за первую
/// пятую времени. Размытую кайму пробовали и отказались: край границы
/// оставлен чётким, а читаемость дало равномерное движение и 280 мс.
///
/// Собрано двумя слоями одного и того же содержимого: нижний нарисован
/// в покое, верхний — в нажатом виде и обрезан кругом. Подпись из-за этого
/// не мигает: она белая ровно там, где под ней уже терракота, а не по всей
/// кнопке сразу. Тот же приём держит подписи навбара внутри пилюли.
///
/// Отпускание — гашение на месте. Круг не втягивается обратно в палец:
/// обратный ход привлекал бы внимание к отпусканию, а внимание тут не нужно.
class DsPressWash extends StatefulWidget {
  const DsPressWash({
    super.key,
    required this.pressed,
    required this.origin,
    required this.resting,
    required this.washed,
    required this.borderRadius,
  });

  final bool pressed;

  /// Точка касания в координатах кнопки. `null` — из центра: так рисуются
  /// витринные ячейки с `forceState`, где пальца не было вовсе.
  final Offset? origin;

  /// Один и тот же ребёнок в двух видах: в покое и под пальцем.
  final Widget resting;
  final Widget washed;

  final BorderRadius borderRadius;

  @override
  State<DsPressWash> createState() => _DsPressWashState();
}

class _DsPressWashState extends State<DsPressWash>
    with TickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: Motion.washIn,
    value: widget.pressed ? 1 : 0,
  );

  /// Гашение отдельным контроллером, а не обратным ходом того же: пятно
  /// продолжает расходиться, пока гаснет.
  late final AnimationController _out =
      AnimationController(vsync: this, duration: Motion.pressOut);

  @override
  void didUpdateWidget(DsPressWash old) {
    super.didUpdateWidget(old);
    if (widget.pressed == old.pressed) return;
    if (widget.pressed) {
      _out.value = 0;
      _grow.forward(from: 0);
    } else {
      _out.forward(from: 0).then((_) {
        // Сброс только если за время гашения не нажали снова.
        if (mounted && !widget.pressed) _grow.value = 0;
      });
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          widget.resting,
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_grow, _out]),
              builder: (context, child) {
                final t = Motion.washGrowth.transform(_grow.value);
                final opacity = 1 - Motion.easeOut.transform(_out.value);
                if (t == 0 || opacity == 0) return const SizedBox.shrink();
                return ClipPath(
                  clipper: _WashClipper(origin: widget.origin, t: t),
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: widget.washed,
            ),
          ),
        ],
      ),
    );
  }
}

class _WashClipper extends CustomClipper<Path> {
  const _WashClipper({required this.origin, required this.t});

  final Offset? origin;
  final double t;

  @override
  Path getClip(Size size) {
    final o = origin ?? size.center(Offset.zero);
    // До самого дальнего угла: пятно обязано накрыть кнопку целиком,
    // из какого бы места его ни начали.
    final dx = math.max(o.dx, size.width - o.dx);
    final dy = math.max(o.dy, size.height - o.dy);
    return Path()
      ..addOval(
          Rect.fromCircle(center: o, radius: math.sqrt(dx * dx + dy * dy) * t));
  }

  @override
  bool shouldReclip(_WashClipper old) => old.t != t || old.origin != origin;
}

/// Где палец и насколько глубоко вдавлен предмет. Наружу — для того,
/// кто рисует под ним тень: без её ответа наклон читается как «висит».
@immutable
class DsTiltPress {
  const DsTiltPress(this.lean, this.depth);

  /// Палец относительно центра, −0.5…0.5 по каждой оси.
  final Offset lean;

  /// 0 — предмет лежит, 1 — прижат пальцем.
  final double depth;
}

class _TiltScope extends InheritedWidget {
  const _TiltScope({required this.press, required super.child});

  final ValueListenable<DsTiltPress> press;

  @override
  bool updateShouldNotify(_TiltScope old) => press != old.press;
}

/// Тень, которая отвечает на нажатие: палец давит — предмет идёт
/// к поверхности, тень поджимается и уходит под поднятый край.
///
/// Вне [DsTilt] рисует покой, то есть [shadow] как есть: класть её
/// в общие раскладки безопасно.
class DsPressShadow extends StatelessWidget {
  const DsPressShadow({super.key, required this.shadow, required this.builder});

  /// Тень в покое. Под пальцем считается из неё, а не задаётся отдельно:
  /// у предмета одна тень, у нажатия — только её состояние.
  final List<BoxShadow> shadow;

  final Widget Function(BuildContext context, List<BoxShadow> shadow) builder;

  @override
  Widget build(BuildContext context) {
    final press =
        context.dependOnInheritedWidgetOfExactType<_TiltScope>()?.press;
    if (press == null) return builder(context, shadow);
    return ValueListenableBuilder<DsTiltPress>(
      valueListenable: press,
      builder: (context, p, _) => builder(
        context,
        Shadows.press(shadow, depth: p.depth, lean: p.lean),
      ),
    );
  }
}

/// Нажатие карточки, лежащей на поверхности. Начато как порт `Tilt`
/// из motion-primitives (Basic Tilt Card) и от образца отошло.
///
/// Карточка не меняет цвет, а проседает: точка касания переводится в долю
/// от центра (−0.5…+0.5), вся карточка уходит вниз на общую просадку
/// [Motion.pressScale], а нажатый угол — ещё на [Motion.tiltDegrees]
/// глубже соседних. Перспектива 1000 пикселей — как в образце.
///
/// **Чем отличается от образца.** У Basic Tilt Card поворот живёт один,
/// и карточка качается вокруг центра: угол под пальцем вниз,
/// противоположный вверх. Так ведёт себя предмет, подвешенный в воздухе, —
/// а рядом с кнопкой, которая просто вжимается, это спорит: предметы одной
/// поверхности не могут вести себя по-разному. Сказано 09.09.2026:
/// «как будто они висят в воздухе, а кнопка — лежит».
///
/// Поэтому поворот оставлен как есть, но к нему добавлена общая просадка,
/// и она перевешивает подъём: ниже плоскости покоя уходят **оба** края,
/// просто под пальцем — вдвое с лишним глубже. Плюс тень отвечает на
/// нажатие ([DsPressShadow]): без неё наклон одинаково читается и как
/// «нажали сюда», и как «приподняли оттуда», и «висит» возвращается.
///
/// Палец ловится [Listener], а не жестом: `Listener` не участвует в арене
/// жестов и не отнимает тап у того, на чём лежит. Карточку по-прежнему можно
/// нажать, наклон живёт поверх.
///
/// Возврат — пружиной, от текущего положения и с текущей скоростью: палец
/// можно вести, наклон следует за ним без рывков. Пружин две: наклон идёт
/// упругой из образца ([Motion.tiltSpring]), просадка — критической
/// ([Motion.tiltSinkSpring]), чтобы карточка не отпрыгивала от стола.
class DsTilt extends StatefulWidget {
  const DsTilt(
      {super.key, required this.child, this.degrees = Motion.tiltDegrees});

  final Widget child;

  /// Наибольший угол по каждой оси.
  final double degrees;

  @override
  State<DsTilt> createState() => _DsTiltState();
}

class _DsTiltState extends State<DsTilt>
    with TickerProviderStateMixin
    implements ValueListenable<DsTiltPress> {
  late final AnimationController _x =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _y =
      AnimationController.unbounded(vsync: this);

  /// Просадка: 0 лежит, 1 прижата. Отдельно от наклона, потому что живёт
  /// по другой пружине — наклону упругость идёт, просадке нет.
  late final AnimationController _down =
      AnimationController.unbounded(vsync: this);

  late final Listenable _all = Listenable.merge([_x, _y, _down]);

  // Состояние наружу — тени под карточкой. Значение считаем на месте:
  // хранить копию значит держать её в согласии с тремя контроллерами.
  @override
  DsTiltPress get value =>
      DsTiltPress(Offset(_x.value, _y.value), _down.value.clamp(0.0, 1.0));

  @override
  void addListener(VoidCallback listener) => _all.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _all.removeListener(listener);

  void _spring(AnimationController c, double target,
          [SpringDescription? spring]) =>
      c.animateWith(SpringSimulation(
          spring ?? Motion.tiltSpring, c.value, target, c.velocity));

  void _follow(Offset local) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    _spring(_x, local.dx / size.width - 0.5);
    _spring(_y, local.dy / size.height - 0.5);
    _spring(_down, 1, Motion.tiltSinkSpring);
  }

  void _release() {
    _spring(_x, 0);
    _spring(_y, 0);
    _spring(_down, 0, Motion.tiltSinkSpring);
  }

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    _down.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Непрозрачный для хит-теста: по умолчанию `Listener` ждёт попадания
      // в ребёнка, а пустое место карточки хит-тест не проходит — палец
      // в углу не доходил вовсе. Дети события всё равно получают: `opaque`
      // добавляет слушателя к результату, а не отбирает у них.
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _follow(e.localPosition),
      onPointerMove: (e) => _follow(e.localPosition),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: _all,
        builder: (context, child) {
          final rad = widget.degrees * 2 * math.pi / 180;
          // Просадка — общая для всей системы: та же, что у кнопки и чипа.
          // Карточка обязана нажиматься как всё остальное, иначе рядом
          // с лежащей кнопкой она читается как парящая.
          final sink = 1 - (1 - Motion.pressScale) * value.depth;
          return Transform(
            alignment: Alignment.center,
            // Знаки обратны образцу, и это не описка: у CSS перспектива
            // записана как −1/d, у Flutter принято +1/d — ось z смотрит
            // в разные стороны, и один и тот же угол даёт зеркальный
            // наклон. В таком виде нажатый угол уходит от глаза.
            //
            // Поворот один, а смысл ему задаёт просадка. Сам по себе он
            // качает карточку вокруг центра: угол под пальцем вниз,
            // противоположный вверх — так ведёт себя подвешенный предмет.
            // Общая просадка опускает оба края ниже плоскости покоя, и
            // остаётся только разница между ними: под пальцем глубже.
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_y.value * rad)
              ..rotateY(-_x.value * rad)
              ..multiply(Matrix4.diagonal3Values(sink, sink, 1)),
            child: child,
          );
        },
        child: _TiltScope(press: this, child: widget.child),
      ),
    );
  }
}

/// Появление по очереди. Порт `AnimatedGroup` из motion-primitives,
/// пресет `scale`.
///
/// Группой это не оформлено намеренно: раскладку держит тот, кто строит
/// список — колонка, сетка, лента, — а сюда приходит уже готовый ребёнок
/// со своим номером в очереди. Так приём работает в любой раскладке
/// и ничего о ней не знает.
///
/// [play] — не «показать», а «сыграть»: пока false, ребёнок висит
/// невидимым и место не занимает мигая. Так группа внутри спойлера ждёт,
/// пока его откроют, а не проигрывает появление в закрытом виде.
class DsAppear extends StatefulWidget {
  const DsAppear({
    super.key,
    required this.child,
    this.index = 0,
    this.play = true,
  });

  final Widget child;

  /// Номер в очереди: задержка — [Motion.appearStagger] на каждого.
  final int index;

  final bool play;

  @override
  State<DsAppear> createState() => _DsAppearState();
}

class _DsAppearState extends State<DsAppear> with TickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: Motion.reveal,
    value: widget.play ? 0 : 0,
  );

  /// Масштаб идёт пружиной, а прозрачность кривой — как в образце. Это
  /// не прихоть: у Motion разные значения по умолчанию для трансформных
  /// и нетрансформных величин, и на глаз разница как раз заметна.
  late final AnimationController _scale =
      AnimationController.unbounded(vsync: this, value: Motion.appearFrom);

  @override
  void initState() {
    super.initState();
    if (widget.play) _start();
  }

  @override
  void didUpdateWidget(DsAppear old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _start();
    if (!widget.play && old.play) {
      _fade.value = 0;
      _scale.stop();
      _scale.value = Motion.appearFrom;
    }
  }

  void _start() {
    final delay = Motion.appearStagger * widget.index;
    Future<void>.delayed(delay, () {
      if (!mounted || !widget.play) return;
      _fade.forward(from: 0);
      _scale.animateWith(
          SpringSimulation(Motion.appearSpring, _scale.value, 1, 0));
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fade, _scale]),
      builder: (context, child) => Opacity(
        opacity: Motion.easeReveal.transform(_fade.value).clamp(0.0, 1.0),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}

/// Текстовое действие. Figma `Button` (`29:11`), 27 ячеек.
///
/// Нажатое состояние у всех трёх типов одинаковое — терракота и белый текст.
/// Это и есть правило «цвет приходит в момент действия»: в покое интерфейс
/// почти монохромный, акцент вспыхивает только под пальцем.
class DsButton extends StatefulWidget {
  const DsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = DsButtonType.primary,
    this.size = DsButtonSize.lg,
    this.subtitle,
    this.icon,
    this.forceState,
    this.expand = false,
  });

  final String label;

  /// Вторая строка под подписью. Нужна там, где условие объясняется на самой
  /// кнопке: «Я на месте, поверить мне» + «По GPS городовой далеко».
  final String? subtitle;

  final DsIconName? icon;
  final VoidCallback? onPressed;
  final DsButtonType type;
  final DsButtonSize size;

  /// Занять всю доступную ширину. В Figma это решает раскладка экрана,
  /// в коде — флаг.
  final bool expand;

  /// Показать конкретную ячейку матрицы, не трогая палец. Только для витрины:
  /// в продукте состояние определяется взаимодействием и наличием [onPressed].
  final DsState? forceState;

  @override
  State<DsButton> createState() => _DsButtonState();
}

class _DsButtonState extends State<DsButton> {
  bool _down = false;

  /// Где палец коснулся кнопки. Живёт между нажатиями: после отпускания
  /// заливка ещё гаснет, и точка ей нужна до конца гашения.
  Offset? _origin;

  DsState get _state {
    if (widget.forceState != null) return widget.forceState!;
    if (widget.onPressed == null) return DsState.disabled;
    return _down ? DsState.pressed : DsState.normal;
  }

  /// У ghost фона нет ни в одном состоянии — включая нажатое. Он живёт
  /// поверх содержимого, и вспышка заливки вырезала бы в нём дыру.
  Color _background(DsState s) => switch ((widget.type, s)) {
        (DsButtonType.ghost, _) => const Color(0x00000000),
        (_, DsState.pressed) => S.surfaceActionPressed,
        (_, DsState.disabled) => S.surfaceActionDisabled,
        (DsButtonType.primary, _) => S.surfaceActionPrimary,
        (DsButtonType.secondary, _) => S.surfaceActionSecondary,
      };

  /// Режим, в котором рисуется содержимое кнопки. На чёрной и на терракотовой
  /// заливке — «на тёмном», в выключенном состоянии — «выключено». Это тот же
  /// механизм, что красит глиф иконки целиком, из скольких бы кусков он ни был
  /// собран.
  InkMode _ink(DsState s) => switch ((widget.type, s)) {
        (_, DsState.disabled) => InkMode.disabled,
        (DsButtonType.ghost, _) => InkMode.light,
        (_, DsState.pressed) => InkMode.onDark,
        (DsButtonType.primary, _) => InkMode.onDark,
        _ => InkMode.light,
      };

  /// Цвет подписи и глифа. От чернильного режима отличается ровно в одном
  /// месте: у ghost нажатие красит содержимое терракотой вместо того, чтобы
  /// заливать фон. Правило «цвет приходит в момент действия» остаётся —
  /// меняется только носитель цвета.
  Color _content(DsState s) =>
      widget.type == DsButtonType.ghost && s == DsState.pressed
          ? S.textAccent
          : _ink(s).textDefault;

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final enabled = widget.onPressed != null && widget.forceState == null;

    // Содержимое строится дважды — по разу на слой заливки. Дублирование
    // здесь дешевле полумер: красить подпись усреднённым цветом, пока под
    // ней ползёт граница, значит на полпути получить серый текст.
    Widget content(DsState s) => Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              DsIcon(widget.icon!, size: 16, color: _content(s)),
              const SizedBox(width: Space.s2),
            ],
            Column(
              mainAxisSize: MainAxisSize.min,
              // Обе строки по центру. Подзаголовок объясняет условие на самой
              // кнопке и читается вместе с подписью — прижатый влево, он
              // разваливал бы блок надвое.
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(widget.label,
                    style: widget.size.labelStyle.copyWith(color: _content(s)),
                    textAlign: TextAlign.center),
                // Гэп между строками — space-0: подпись и подзаголовок
                // читаются одним блоком, а не двумя строками.
                // Подзаголовок той же краской, что подпись, и `DS/Body/sm`:
                // так в макете. Приглушённый серый на чёрной кнопке читался
                // хуже, а мельче — вовсе терялся.
                if (widget.subtitle != null)
                  Text(widget.subtitle!,
                      style: T.bodySm.copyWith(color: _content(s)),
                      textAlign: TextAlign.center),
              ],
            ),
          ],
        );

    // Скругление снято с заливки и отдано обрезке: круг, который растёт
    // из-под пальца, обязан подрезаться по форме кнопки.
    Widget layer(DsState s) => DsInk(
          mode: _ink(s),
          child: Container(
            height: widget.subtitle == null ? widget.size.height : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.size.padH,
              vertical: widget.subtitle == null ? 0 : Space.s2,
            ),
            // alignment здесь не ставим: Container с выравниванием
            // растягивается на всю разрешённую ширину, и кнопка «Нашёл!»
            // уезжает во весь экран. Ширину задаёт Row — min по содержимому
            // или max при expand.
            color: _background(s),
            child: content(s),
          ),
        );

    return GestureDetector(
      // Точка касания нужна заливке: цвет расходится оттуда, куда нажали.
      onTapDown: enabled
          ? (d) => setState(() {
                _down = true;
                _origin = d.localPosition;
              })
          : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: enabled ? widget.onPressed : null,
      // Просадка под пальцем — на нажатии, не на отпускании. Вход 120 мс,
      // возврат 180 мс: система отвечает мгновенно, отпускание может быть
      // спокойным (`ds/motion.md`, «Остальные компоненты»).
      //
      // Просадка привязана к пальцу, а не к состоянию: forceState — витринный
      // приём, он показывает ячейку матрицы, а не нажатие. Иначе снимок
      // витрины поехал бы вместе с ней.
      child: AnimatedScale(
        scale: _down ? Motion.pressScale : 1,
        duration: _down ? Motion.pressIn : Motion.pressOut,
        curve: Motion.easeOut,
        child: DsPressWash(
          pressed: state == DsState.pressed,
          origin: _origin,
          borderRadius: BorderRadius.circular(Radii.base),
          resting: layer(state == DsState.pressed ? DsState.normal : state),
          washed: layer(DsState.pressed),
        ),
      ),
    );
  }
}

enum DsIconButtonType { primary, secondary, ghost, glass }

enum DsIconButtonSize { lg, sm }

/// Действие без текста. Figma `IconButton` (`77:49`), 22 ячейки.
///
/// `glass` — полупрозрачная белая заливка для карты и камеры. У него нет
/// состояния `disabled`: стеклянные кнопки в продукте не выключаются, поэтому
/// [onPressed] у него обязателен.
class DsIconButton extends StatefulWidget {
  const DsIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.type = DsIconButtonType.primary,
    this.size = DsIconButtonSize.lg,
    this.forceState,
  }) : assert(
          type != DsIconButtonType.glass || forceState != DsState.disabled,
          'у glass нет состояния disabled: стеклянные кнопки не выключаются',
        );

  final DsIconName icon;
  final VoidCallback? onPressed;
  final DsIconButtonType type;
  final DsIconButtonSize size;
  final DsState? forceState;

  @override
  State<DsIconButton> createState() => _DsIconButtonState();
}

class _DsIconButtonState extends State<DsIconButton> {
  bool _down = false;

  /// Точка касания — заливке. См. [DsPressWash].
  Offset? _origin;

  double get _side =>
      widget.size == DsIconButtonSize.lg ? Sizes.controlMd : Sizes.touchMin;

  DsState get _state {
    if (widget.forceState != null) return widget.forceState!;
    if (widget.onPressed == null) return DsState.disabled;
    return _down ? DsState.pressed : DsState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final glass = widget.type == DsIconButtonType.glass;

    Color background(DsState s) => switch ((widget.type, s)) {
          (DsIconButtonType.glass, DsState.pressed) => S.surfaceGlassPressed,
          (DsIconButtonType.glass, _) => S.surfaceGlass,
          (_, DsState.pressed) => S.surfaceActionPressed,
          (_, DsState.disabled) => S.surfaceActionDisabled,
          (DsIconButtonType.primary, _) => S.surfaceActionPrimary,
          (DsIconButtonType.secondary, _) => S.surfaceActionSecondary,
          (DsIconButtonType.ghost, _) => S.surfaceDefault,
        };

    InkMode ink(DsState s) => switch ((widget.type, s)) {
          (DsIconButtonType.glass, _) => InkMode.light,
          (_, DsState.disabled) => InkMode.disabled,
          (_, DsState.pressed) => InkMode.onDark,
          (DsIconButtonType.primary, _) => InkMode.onDark,
          _ => InkMode.light,
        };

    // Слои заливки: нижний в покое, верхний нажатый. Обводка ghost есть
    // в обоих — она не про состояние, а про форму.
    Widget layer(DsState s) => Container(
          width: _side,
          height: _side,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background(s),
            shape: BoxShape.circle,
            border: widget.type == DsIconButtonType.ghost && !glass
                ? Border.all(color: S.borderDefault)
                : null,
          ),
          // Глиф 16 в любом размере — так во всех 22 ячейках макета.
          // Крупнее он был по недосмотру: у большой кнопки растёт круг,
          // а не значок.
          child: DsIcon(widget.icon, color: ink(s).textDefault),
        );

    final enabled = widget.onPressed != null && widget.forceState == null;

    return GestureDetector(
      onTapDown: enabled
          ? (d) => setState(() {
                _down = true;
                _origin = d.localPosition;
              })
          : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _down ? Motion.pressScale : 1,
        duration: _down ? Motion.pressIn : Motion.pressOut,
        curve: Motion.easeOut,
        child: DsPressWash(
          pressed: state == DsState.pressed,
          origin: _origin,
          borderRadius: BorderRadius.circular(_side / 2),
          resting: layer(state == DsState.pressed ? DsState.normal : state),
          washed: layer(DsState.pressed),
        ),
      ),
    );
  }
}

/// Поле формы. Figma `Input` (`29:18`), матрица `State=default/focus/error/disabled`.
///
/// Контроллер и фокус компонент заводит сам, если их не передали, и сам же
/// освобождает: поле, создающее их в `build`, течёт при каждой перерисовке.
class DsInput extends StatefulWidget {
  const DsInput({
    super.key,
    this.controller,
    this.placeholder,
    this.state = DsState.normal,
    this.error = false,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final DsState state;
  final bool error;
  final ValueChanged<String>? onChanged;

  @override
  State<DsInput> createState() => _DsInputState();
}

class _DsInputState extends State<DsInput> {
  TextEditingController? _ownController;
  late final FocusNode _focus = FocusNode()..addListener(_onFocus);

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.state == DsState.disabled;
    final borderColor = widget.error
        ? S.borderError
        : _focus.hasFocus
            ? S.borderFocusRing
            : disabled
                ? S.borderDefault
                : S.borderStrong;
    final empty = _controller.text.isEmpty;

    // Обводка переезжает в фокусное кольцо и обратно за 120 мс: фокус —
    // такое же событие, как нажатие, и появляться рывком ему незачем.
    return AnimatedContainer(
      duration: Motion.pressIn,
      curve: Motion.easeOut,
      height: Sizes.controlMd,
      padding: const EdgeInsets.symmetric(horizontal: Space.s4),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: disabled ? S.surfaceActionDisabled : S.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (empty && widget.placeholder != null)
            Text(widget.placeholder!,
                style: T.bodyBase.copyWith(color: InkMode.light.textMuted)),
          EditableText(
            controller: _controller,
            focusNode: _focus,
            readOnly: disabled,
            onChanged: (v) {
              setState(() {});
              widget.onChanged?.call(v);
            },
            style: T.bodyBase.copyWith(
                color: disabled ? S.textDisabled : InkMode.light.textDefault),
            cursorColor: S.borderFocusRing,
            backgroundCursorColor: S.borderDefault,
            selectionColor: S.surfaceAccentSubtle,
          ),
        ],
      ),
    );
  }
}

enum DsBadgeVariant { success, warning, error, info }

/// Статус. Figma `Badge` (`29:31`).
///
/// Вертикальные поля приведены к шкале 2026-08-11: 6 → 8 (`space-2`), плашка
/// перестала выглядеть поджатой.
class DsBadge extends StatelessWidget {
  const DsBadge({super.key, required this.label, required this.variant});

  final String label;
  final DsBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final background = switch (variant) {
      DsBadgeVariant.success => S.bgSuccess,
      DsBadgeVariant.warning => S.bgWarning,
      DsBadgeVariant.error => S.bgError,
      DsBadgeVariant.info => S.bgInfo,
    };
    // Жёлтый под белым текстом не читается — у warning своя пара. В макете
    // это `text-on-soft`, а не `text-on-warning`: значения совпадают
    // (gray-950), но токен берём тот, что стоит на узле.
    final color =
        variant == DsBadgeVariant.error ? S.textOnStatus : S.textOnSoft;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Text(label, style: T.labelXs.copyWith(color: color)),
    );
  }
}

enum DsTab { map, finds }

/// Нижний таб-бар. Figma `Navbar` (`84:122`).
class DsNavbar extends StatefulWidget {
  const DsNavbar({super.key, required this.active, this.onChanged});

  final DsTab active;
  final ValueChanged<DsTab>? onChanged;

  @override
  State<DsNavbar> createState() => _DsNavbarState();
}

class _DsNavbarState extends State<DsNavbar>
    with SingleTickerProviderStateMixin {
  /// Снято с Figma (`29:48`): два инстанса `Button` размера md, 120×48,
  /// зазор `space-2`. Ширина одинаковая у обоих — от этого зависит переезд
  /// пилюли, и подгонять её по длине слова нельзя.
  static const _tabW = 120.0;
  static const _tabH = 48.0;
  static const _row = _tabW * 2 + Space.s2;
  static const _shift = _tabW + Space.s2;

  /// Наклона нет: панель проседает ровно, без стороны.
  ///
  /// Было 4° (половина карточного) — «многовато» (09.09.2026). Причина
  /// в размере: те же градусы на объекте 264×64 дают куда больший ход края,
  /// чем на карточке 164×228, и панель начинает качаться, как доска.
  /// Направление нажатия при этом всё равно остаётся — его показывает тень,
  /// а она стоит дешевле поворота.
  static const _lean = 0.0;

  // Контроллер без границ: пружина обязана уметь проскочить за 0 и 1, иначе
  // отскока не получится — обычный AnimationController обрежет перелёт и
  // движение снова станет упором.
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: widget.active == DsTab.map ? 0 : 1,
  );

  @override
  void didUpdateWidget(DsNavbar old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      final target = widget.active == DsTab.map ? 0.0 : 1.0;
      // Текущая скорость передаётся в пружину: если таб перещёлкнули на
      // полпути, пилюля не начинает с нуля, а доворачивает с хода.
      _c.animateWith(
          SpringSimulation(Motion.tabSpring, _c.value, target, _c.velocity));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Навбар — предмет, лежащий на карте, и под пальцем он проседает, как
    // карточка находки: общая просадка, чуть глубже с той стороны, куда
    // нажали, и тень поджимается вслед.
    //
    // Просаживается панель целиком, а не таб. Так вышло не из красоты:
    // у невыбранного таба нет ни заливки, ни рамки — одно слово, и три
    // процента просадки на нём никак не видно. Нажатие по невыбранному
    // табу и есть обычный случай в таб-баре, так что отвечать должно то,
    // у чего есть поверхность. Пилюля лежит на панели и проседает с ней.
    //
    // `DsTilt` ловит палец `Listener`, а тот не участвует в арене жестов —
    // тапы по табам ниже по стеку доходят как доходили.
    return DsTilt(
      degrees: _lean,
      child: DsPressShadow(
        shadow: Shadows.lg,
        builder: (context, shadow) => Container(
          padding: const EdgeInsets.all(Space.s2),
          decoration: BoxDecoration(
            color: S.surfaceDefault,
            borderRadius: BorderRadius.circular(Radii.card),
            boxShadow: shadow,
          ),
          child: SizedBox(
            width: _row,
            height: _tabH,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                // Пилюля просто едет: перелёта нет, деформации нет. Отскок
                // и растяжение здесь были и оказались навязчивыми — микродвижение
                // повторяется десятки раз за сеанс, и то, что в одиночном показе
                // читается как живость, в руках читается как суета.
                final t = _c.value.clamp(0.0, 1.0);
                final dx = t * _shift;

                return Stack(
                  children: [
                    _labels(InkMode.light),
                    // Переезд — трансформацией, не отступом и не шириной:
                    // `ds/motion.md` разрешает в анимации только transform
                    // и opacity.
                    Transform.translate(
                      offset: Offset(dx, 0),
                      child: SizedBox(
                        width: _tabW,
                        height: _tabH,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Radii.base),
                          child: Stack(
                            children: [
                              const Positioned.fill(
                                child:
                                    ColoredBox(color: S.surfaceActionPrimary),
                              ),
                              // Ширина задаётся явно: без неё Stack зажал бы
                              // строку подписей по ширине пилюли, и вторая
                              // подпись не поместилась бы.
                              Positioned(
                                left: 0,
                                top: 0,
                                width: _row,
                                height: _tabH,
                                child: Transform.translate(
                                  offset: Offset(-dx, 0),
                                  child: _labels(InkMode.onDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Нажатия ловим поверх всего: пилюля и обрезка ниже по стеку
                    // до пальца бы их не донесли.
                    Row(
                      children: [
                        _hit(DsTab.map),
                        const SizedBox(width: Space.s2),
                        _hit(DsTab.finds),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Обе подписи разом, одним чернильным режимом. Иконок нет — их нет и в
  /// макете: два слова читаются быстрее, чем слово со значком.
  Widget _labels(InkMode ink) => Row(
        children: [
          _label('Карта', ink),
          const SizedBox(width: Space.s2),
          _label('Находки', ink),
        ],
      );

  Widget _label(String text, InkMode ink) => SizedBox(
        width: _tabW,
        height: _tabH,
        child: Center(
          child: Text(text, style: T.labelSm.copyWith(color: ink.textDefault)),
        ),
      );

  Widget _hit(DsTab tab) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onChanged == null ? null : () => widget.onChanged!(tab),
        child: const SizedBox(width: _tabW, height: _tabH),
      );
}

enum DsStatusBarTheme { light, dark }

/// Системная строка. Figma `StatusBar` (`113:166`).
///
/// В продукте её рисует система; компонент нужен, чтобы витрина и макеты
/// экранов совпадали по высоте и по цвету содержимого.
class DsStatusBar extends StatelessWidget {
  const DsStatusBar({super.key, this.theme = DsStatusBarTheme.light});

  final DsStatusBarTheme theme;

  @override
  Widget build(BuildContext context) {
    final color = theme == DsStatusBarTheme.light
        ? InkMode.light.textDefault
        : InkMode.onDark.textDefault;
    return SizedBox(
      height: Sizes.touchMin,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('9:41', style: T.bodySmMedium.copyWith(color: color)),
            Text('▮▮▮', style: T.labelXs.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Ручка шторки. Figma `Handle` (`301:741`).
class DsHandle extends StatelessWidget {
  const DsHandle({super.key});

  @override
  Widget build(BuildContext context) {
    // Блок 16 высотой: 12 сверху и полоска 44×4 (`301:741`). Снизу поля
    // нет — под ручкой сразу начинается содержимое шторки.
    return Padding(
      padding: const EdgeInsets.only(top: Space.s3),
      child: Container(
        width: Sizes.touchMin,
        height: Space.s1,
        decoration: BoxDecoration(
          color: S.borderStrong,
          borderRadius: BorderRadius.circular(Radii.full),
        ),
      ),
    );
  }
}

/// Имена глифов из Figma `Icon` (`68:14`), 19 штук.
/// Глиф. Figma `Icon` (`68:14`).
///
/// Контуры сняты с макета и лежат в `icon_paths.dart`; здесь только отрисовка.
/// Глиф красится целиком, сколько бы кусков в нём ни было
/// (`ds/CONTRACT.md`, пункт 9). Цвет ищется в три шага:
///
/// 1. переданный [color] — так делают кнопки и строки, где цвет задаёт фон;
/// 2. собственный цвет глифа, если он есть, — `check`, `warning`, `info`
///    носят статусный и не выцветают на чужой плашке;
/// 3. чернильный режим — остальные шестнадцать.
class DsIcon extends StatelessWidget {
  const DsIcon(this.name, {super.key, this.size = 16, this.color});

  final DsIconName name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? glyphTint[name] ?? DsInk.of(context).textDefault;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GlyphPainter(name, resolved)),
    );
  }
}

/// Разбор контура. Команд всего четыре: генератор приводит к ним всё
/// остальное, что встречается в экспорте Figma, — дуги, прямоугольники,
/// окружности и сокращённые H/V.
final _token = RegExp(r'([MLCZ])|(-?\d+(?:\.\d+)?)');

Path _glyphPath(String d) {
  final path = Path();
  final tokens = _token.allMatches(d).toList();
  var i = 0;
  // Порядок вычисления аргументов в Dart слева направо — на этом здесь всё
  // и держится.
  double next() => double.parse(tokens[i++].group(0)!);

  while (i < tokens.length) {
    switch (tokens[i++].group(0)!) {
      case 'M':
        path.moveTo(next(), next());
      case 'L':
        path.lineTo(next(), next());
      case 'C':
        path.cubicTo(next(), next(), next(), next(), next(), next());
      case 'Z':
        path.close();
    }
  }
  return path;
}

/// Разобранные контуры переживают перерисовку: строк много, а меняются они
/// только при пересборке из Figma.
final _parsed = <DsIconName, List<Path>>{};

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.name, this.color);

  final DsIconName name;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final parts = glyphs[name];
    if (parts == null) return;
    final paths = _parsed[name] ??= [for (final p in parts) _glyphPath(p.d)];

    canvas.save();
    // Контуры заданы в системе 16×16; обводка масштабируется вместе с ними,
    // поэтому глиф на любом размере выглядит так же, как в макете.
    canvas.scale(size.width / kGlyphBox);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kGlyphStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fill = Paint()..color = color;

    for (var i = 0; i < paths.length; i++) {
      canvas.drawPath(paths[i], parts[i].filled ? fill : stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.name != name || old.color != color;
}
