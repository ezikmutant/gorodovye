// 15 текстовых стилей. Зеркало таблицы из `ds/foundation.md`.
//
// **Цвет в стиль не зашит.** В Figma TextStyle не несёт цвет, и здесь так же:
// стиль задаёт гарнитуру, кегль, интерлиньяж и трекинг, а красит текст
// отдельный смысловой токен. Иначе весь текст в приложении окажется одного
// цвета, и три чернильных режима перестанут работать.

import 'package:flutter/widgets.dart';

import 'primitives.dart';

/// Трекинг в Figma задан процентом от кегля, в Flutter `letterSpacing` — в
/// логических пикселях. Переводим здесь, чтобы в таблице ниже остались те же
/// проценты, что в макете.
double _tracking(double size, double percent) => size * percent / 100;

/// Onest — вариативный шрифт: в Google Fonts у него нет статических
/// начертаний. Вес задаётся осью `wght`, а не выбором файла, поэтому рядом
/// с `fontWeight` идёт `fontVariations`. `fontWeight` при этом нужен: он
/// сработает, если гарнитура не подгрузилась и текст рисуется системной.
List<FontVariation> _wght(double weight) => [FontVariation('wght', weight)];

abstract final class T {
  // --- Display: только Dela Gothic One, только крупные заголовки -----------
  static const display5xl = TextStyle(
    fontFamily: FontFamily.display,
    fontSize: FontSize.xl5,
    fontWeight: FontWeight.w400,
    height: 1.10,
    letterSpacing: -0.56, // −1%
  );

  static const display4xl = TextStyle(
    fontFamily: FontFamily.display,
    fontSize: FontSize.xl4,
    fontWeight: FontWeight.w400,
    height: 1.10,
    letterSpacing: -0.40, // −1%
  );

  // --- Heading -------------------------------------------------------------
  static const heading3xl = TextStyle(
    fontFamily: FontFamily.display,
    fontSize: FontSize.xl3,
    fontWeight: FontWeight.w400,
    height: 1.15,
    letterSpacing: -0.32, // −1%
  );

  static const heading2xl = TextStyle(
    fontFamily: FontFamily.display,
    fontSize: FontSize.xl2,
    fontWeight: FontWeight.w400,
    height: 1.20,
  );

  static final headingXl = TextStyle(
    fontFamily: FontFamily.sans,
    fontVariations: _wght(600),
    fontSize: FontSize.xl,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static final headingLg = TextStyle(
    fontFamily: FontFamily.sans,
    fontVariations: _wght(500),
    fontSize: FontSize.lg,
    fontWeight: FontWeight.w500,
    height: 1.40,
  );

  // --- Body ----------------------------------------------------------------
  static final bodyBase = TextStyle(
    fontFamily: FontFamily.sans,
    fontVariations: _wght(400),
    fontSize: FontSize.base,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  static final bodySm = TextStyle(
    fontFamily: FontFamily.sans,
    fontVariations: _wght(400),
    fontSize: FontSize.sm,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  static final bodySmMedium = TextStyle(
    fontFamily: FontFamily.sans,
    fontVariations: _wght(500),
    fontSize: FontSize.sm,
    fontWeight: FontWeight.w500,
    height: 1.50,
  );

  static final bodyXs = TextStyle(
    fontFamily: FontFamily.sans,
    fontVariations: _wght(400),
    fontSize: FontSize.xs,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  // --- Label: рабочая лошадь интерфейса ------------------------------------
  // Разрядка +5% отличает лейбл от Body при том же кегле: он читается как
  // ярлык, а не как фраза.
  static final labelXs = _label(FontSize.xs);
  static final labelSm = _label(FontSize.sm);
  static final labelBase = _label(FontSize.base);
  static final labelLg = _label(FontSize.lg);
  static final labelXl = _label(FontSize.xl);

  static TextStyle _label(double size) => TextStyle(
        fontFamily: FontFamily.sans,
        fontVariations: _wght(600),
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.40,
        letterSpacing: _tracking(size, 5),
      );

  /// Все пятнадцать по именам из Figma — для витрины и для сверки.
  static Map<String, TextStyle> get all => {
        'DS/Display/5xl': display5xl,
        'DS/Display/4xl': display4xl,
        'DS/Heading/3xl': heading3xl,
        'DS/Heading/2xl': heading2xl,
        'DS/Heading/xl': headingXl,
        'DS/Heading/lg': headingLg,
        'DS/Body/base': bodyBase,
        'DS/Body/sm': bodySm,
        'DS/Body/sm Medium': bodySmMedium,
        'DS/Body/xs': bodyXs,
        'DS/Label/xs': labelXs,
        'DS/Label/sm': labelSm,
        'DS/Label/base': labelBase,
        'DS/Label/lg': labelLg,
        'DS/Label/xl': labelXl,
      };
}
