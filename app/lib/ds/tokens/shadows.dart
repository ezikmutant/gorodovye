// Пять теней. Зеркало таблицы из `ds/foundation.md`.

import 'package:flutter/widgets.dart';

abstract final class Shadows {
  /// Мелкие плашки.
  static const sm = <BoxShadow>[
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Затвор в AR.
  static const md = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 6), blurRadius: 16),
  ];

  /// Navbar и крупные плавающие блоки.
  static const lg = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 16), blurRadius: 40),
  ];

  /// Шторка. **Светит вверх, и это не опечатка:** шторка приходит снизу, тень
  /// должна лежать на карте над её краем, а не под ним. [lg] смещена вниз и
  /// для шторки не годится.
  static const sheet = <BoxShadow>[
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, -10), blurRadius: 36),
  ];

  /// Объекты поверх карты: MapMarker, You.
  ///
  /// Теней две: короткая даёт контакт с поверхностью, широкая — равномерный
  /// ореол вокруг. На карте фон под маркером меняется каждые несколько
  /// пикселей, и односторонняя тень там читается как грязь, а не как объём.
  static const glow = <BoxShadow>[
    BoxShadow(color: Color(0x38000000), offset: Offset(0, 2), blurRadius: 14),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 0),
      blurRadius: 28,
      spreadRadius: 2,
    ),
  ];

  /// Насколько тень поджимается, когда предмет прижали к поверхности:
  /// смещение и размытие сходятся к этой доле.
  static const _pressNear = 0.4;

  /// Во столько раз тень плотнеет при полном нажатии. Контактная тень
  /// не только короче — она темнее: рассеиваться свету стало негде.
  static const _pressInk = 1.4;

  /// На сколько пикселей тень уезжает к поднятому краю при полном нажатии.
  static const _pressLean = 6.0;

  /// Тень предмета, который вдавливают в поверхность.
  ///
  /// **Зачем вообще:** наклон сам по себе не говорит, куда поехала карточка.
  /// Один и тот же угол читается и как «нажали сюда», и как «приподняли
  /// оттуда» — глазу не за что зацепиться. Цепляется он за тень: пока она
  /// не меняется, предмет висит в воздухе, и никакой поворот этого не
  /// исправит. Отсюда правило: наклон без ответа тени не делаем.
  ///
  /// [depth] — 0 предмет лежит свободно, 1 прижат пальцем.
  /// [lean] — палец относительно центра, −0.5…0.5 по каждой оси. Прижатый
  /// угол ближе к поверхности, противоположный поднят, и тень уходит
  /// **от** пальца, под поднятый край.
  static List<BoxShadow> press(
    List<BoxShadow> base, {
    required double depth,
    Offset lean = Offset.zero,
  }) {
    final d = depth.clamp(0.0, 1.0);
    if (d == 0) return base;
    final near = 1 - (1 - _pressNear) * d;
    final shift = -lean * _pressLean * d;
    return [
      for (final s in base)
        BoxShadow(
          color: s.color.withValues(
              alpha: (s.color.a * (1 + (_pressInk - 1) * d)).clamp(0.0, 1.0)),
          offset: s.offset * near + shift,
          blurRadius: s.blurRadius * near,
          spreadRadius: s.spreadRadius * near,
        ),
    ];
  }

  /// По именам из Figma — для витрины и сверки.
  static const all = <String, List<BoxShadow>>{
    'DS/Shadow/sm': sm,
    'DS/Shadow/md': md,
    'DS/Shadow/lg': lg,
    'DS/Shadow/sheet': sheet,
    'DS/Shadow/glow': glow,
  };
}
