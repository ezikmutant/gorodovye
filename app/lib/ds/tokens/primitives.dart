// Слой 1 — примитивы. Зеркало `ds/foundation.md`, имя в имя.
//
// Примитив — сырое значение. В компонентах он не используется напрямую
// никогда: компонент ссылается на смысловой токен, смысловой — на примитив
// (`ds/CONTRACT.md`, правило 2). Единственное место, где примитивы видны
// снаружи, — витрина палитры.

import 'dart:ui' show Color;

/// Цвета-примитивы.
abstract final class P {
  // Нейтралы
  static const gray00 = Color(0xFFFFFFFF);
  static const gray50 = Color(0xFFF6F5F3);
  static const gray100 = Color(0xFFEEEDEA);
  static const gray200 = Color(0xFFE2E1DD);
  static const gray300 = Color(0xFFC7C6C1);
  static const gray500 = Color(0xFF74736E);
  static const gray700 = Color(0xFF454440);
  static const gray900 = Color(0xFF1C1B19);
  static const gray950 = Color(0xFF0E0D0C);

  // Акцент — терракота
  static const accent100 = Color(0xFFFCE8DC);
  static const accent300 = Color(0xFFDE8A62);
  static const accent500 = Color(0xFFC6522D);
  static const accent700 = Color(0xFF983A22);
  static const accent900 = Color(0xFF622414);

  // Бумага — тёплые спокойные поверхности
  static const paper00 = Color(0xFFFDFBF4);
  static const paper100 = Color(0xFFF3EEE0);
  static const paper200 = Color(0xFFE7DFCB);

  // Функциональные
  static const success500 = Color(0xFF7E9E6B);
  static const warning500 = Color(0xFFEBC94C);
  static const error500 = Color(0xFF9C2542);
  static const info500 = Color(0xFF8E90D8);

  /// Совпадает по значению с [inkBlue], но заведён отдельно намеренно:
  /// один — цвет ссылки, другой — краска штампа. Общий hex сегодня не повод
  /// связать их навсегда.
  static const blue600 = Color(0xFF2B4B8C);

  // Чернила — оттиски штампов
  static const inkRed = Color(0xFFB64626);
  static const inkBlue = Color(0xFF2B4B8C);
  static const inkGreen = Color(0xFF2F6B4F);
  static const inkGraphite = Color(0xFF3A3733);

  // Полупрозрачные. Альфа лежит внутри значения, а не задаётся поверх:
  // в Figma прозрачность на заливке не переживает копирования компонента,
  // и то же правило держим в коде — никаких Opacity поверх токена.
  static const whiteA50 = Color(0x80FFFFFF);
  static const whiteA80 = Color(0xCCFFFFFF);
  static const inkA30 = Color(0x4D0E0D0C);

  // Пастельные подложки
  static const tileSage = Color(0xFFDCE5D2);
  static const tileBlush = Color(0xFFF5E2DA);
  static const tileSky = Color(0xFFDDE0F5);
  static const tileSun = Color(0xFFF7E9B8);

  /// Все примитивы по именам из Figma — для каталога и сверки.
  ///
  /// Компоненты этой картой не пользуются: примитив в компоненте запрещён
  /// (`ds/CONTRACT.md`, правило 2). Она нужна там, где палитра сама является
  /// содержимым, — на странице «Цвет» в каталоге.
  static const all = <String, Color>{
    'gray-00': gray00,
    'gray-50': gray50,
    'gray-100': gray100,
    'gray-200': gray200,
    'gray-300': gray300,
    'gray-500': gray500,
    'gray-700': gray700,
    'gray-900': gray900,
    'gray-950': gray950,
    'accent-100': accent100,
    'accent-300': accent300,
    'accent-500': accent500,
    'accent-700': accent700,
    'accent-900': accent900,
    'paper-00': paper00,
    'paper-100': paper100,
    'paper-200': paper200,
    'success-500': success500,
    'warning-500': warning500,
    'error-500': error500,
    'info-500': info500,
    'blue-600': blue600,
    'ink-red': inkRed,
    'ink-blue': inkBlue,
    'ink-green': inkGreen,
    'ink-graphite': inkGraphite,
    'white-a50': whiteA50,
    'white-a80': whiteA80,
    'ink-a30': inkA30,
    'tile-sage': tileSage,
    'tile-blush': tileBlush,
    'tile-sky': tileSky,
    'tile-sun': tileSun,
  };
}

/// Гарнитуры.
abstract final class FontFamily {
  /// Только Display и Heading 3xl/2xl.
  static const display = 'Dela Gothic One';

  /// Всё остальное.
  static const sans = 'Onest';
}

/// Шкала кегля.
abstract final class FontSize {
  static const xs = 12.0;
  static const sm = 14.0;
  static const base = 16.0;
  static const lg = 18.0;
  static const xl = 20.0;
  static const xl2 = 24.0;
  static const xl3 = 32.0;
  static const xl4 = 40.0;
  static const xl5 = 56.0;

  static const all = <String, double>{
    'font-size-xs': xs,
    'font-size-sm': sm,
    'font-size-base': base,
    'font-size-lg': lg,
    'font-size-xl': xl,
    'font-size-2xl': xl2,
    'font-size-3xl': xl3,
    'font-size-4xl': xl4,
    'font-size-5xl': xl5,
  };
}

/// Радиусы.
abstract final class Radii {
  static const none = 0.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const base = 16.0;
  static const lg = 20.0;
  static const card = 24.0;
  static const xl = 38.0;

  /// Пилюли и маркеры. 999 из Figma; в Dart достаточно любого числа больше
  /// половины стороны, но значение держим тем же, чтобы имя оставалось якорем.
  static const full = 999.0;

  static const all = <String, double>{
    'radius-none': none,
    'radius-sm': sm,
    'radius-md': md,
    'radius-base': base,
    'radius-lg': lg,
    'radius-card': card,
    'radius-xl': xl,
    'radius-full': full,
  };
}

/// Отступы. Имена — как в Figma (`space-0` … `space-40`), значения в логических
/// пикселях.
abstract final class Space {
  static const s0 = 0.0;
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s12 = 48.0;
  static const s16 = 64.0;
  static const s20 = 80.0;
  static const s40 = 160.0;

  static const all = <String, double>{
    'space-0': s0,
    'space-1': s1,
    'space-2': s2,
    'space-3': s3,
    'space-4': s4,
    'space-5': s5,
    'space-6': s6,
    'space-8': s8,
    'space-12': s12,
    'space-16': s16,
    'space-20': s20,
    'space-40': s40,
  };
}

/// Размеры.
abstract final class Sizes {
  /// Минимальный тач-таргет.
  static const touchMin = 44.0;

  /// Высота контрола.
  static const controlMd = 52.0;

  static const all = <String, double>{
    'size-touch-min': touchMin,
    'size-control-md': controlMd,
  };
}
