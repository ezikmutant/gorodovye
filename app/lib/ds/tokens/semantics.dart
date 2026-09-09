// Слой 2 — смысловые токены. Зеркало `ds/foundation.md`.
//
// Компоненты ссылаются только сюда. Каждое значение — алиас к примитиву, а не
// собственный литерал: это та же двухуровневость, что в Figma, и она нужна,
// чтобы правка палитры доходила до экранов в одном месте.

import 'dart:ui' show Color;

import 'primitives.dart';

/// Чернильный контекст узла.
///
/// **Это не тема.** Режим говорит одно: «всё, что внутри этого узла, рисуется
/// на тёмном» или «выключено». Включается точечно, на конкретном узле — не на
/// странице и не на экране (`ds/foundation.md`, «Три режима»).
///
/// Из 58 смысловых токенов режим меняет ровно три текстовых — они и лежат
/// прямо на вариантах перечисления. Остальные 54 одинаковы везде и живут
/// статикой в [S].
enum InkMode {
  light(
    textDefault: P.gray900,
    textSubtle: P.gray700,
    textMuted: P.gray500,
  ),
  onDark(
    textDefault: P.gray00,
    textSubtle: P.gray00,
    textMuted: P.gray300,
  ),
  disabled(
    textDefault: P.gray300,
    textSubtle: P.gray300,
    textMuted: P.gray300,
  );

  const InkMode({
    required this.textDefault,
    required this.textSubtle,
    required this.textMuted,
  });

  final Color textDefault;
  final Color textSubtle;
  final Color textMuted;
}

/// Смысловые токены, одинаковые во всех трёх режимах.
abstract final class S {
  // --- Поверхности ---------------------------------------------------------
  static const surfaceDefault = P.gray00;
  static const surfaceSubtle = P.gray50;
  static const surfaceSunken = P.paper100;
  static const surfaceActionPrimary = P.gray950;
  static const surfaceActionSecondary = P.paper200;
  static const surfaceActionPressed = P.accent500;
  static const surfaceActionDisabled = P.paper100;
  static const surfaceAccent = P.accent500;
  static const surfaceAccentSubtle = P.accent100;
  static const surfaceOverlay = P.gray950;
  static const surfaceGlass = P.whiteA50;
  static const surfaceGlassPressed = P.whiteA80;
  static const surfaceDim = P.inkA30;
  static const surfacePaper = P.paper00;
  static const surfacePaperEdge = P.paper100;
  static const surfaceTileSage = P.tileSage;
  static const surfaceTileBlush = P.tileBlush;
  static const surfaceTileSky = P.tileSky;
  static const surfaceTileSun = P.tileSun;

  // --- Текст ---------------------------------------------------------------
  // text-default / -subtle / -muted живут на InkMode: они зависят от режима.
  static const textOnAction = P.gray00;
  static const textAccent = P.accent700;
  static const textError = P.error500;
  static const textDisabled = P.gray300;
  static const textOnStatus = P.gray00;
  static const textOnWarning = P.gray950;
  static const textOnSoft = P.gray950;

  /// Единственное место, где в интерфейсе появляется синий. Подчёркивание
  /// обязательно: цвет один опознавательный признак не тянет.
  static const textLink = P.blue600;

  // --- Обводки -------------------------------------------------------------
  static const borderDefault = P.gray200;
  static const borderStrong = P.gray300;
  static const borderAccent = P.accent500;
  static const borderError = P.error500;
  static const borderFocusRing = P.accent500;
  static const borderPaperRule = P.paper200;

  // --- Состояния -----------------------------------------------------------
  static const bgSuccess = P.success500;
  static const bgWarning = P.warning500;
  static const bgError = P.error500;
  static const bgInfo = P.info500;

  // --- Значки --------------------------------------------------------------

  /// Терракотовый значок: раскрытый спойлер. Закрытый красится [inkNeutral],
  /// переход между ними идёт вместе с раскрытием.
  ///
  /// Заведён отдельным именем, потому что акцент значка и акцент текста —
  /// разные ступени: `text-accent` это `accent-700`, на ступень темнее.
  /// До 08.09.2026 макет красил значок прямо примитивом `accent-500`, минуя
  /// смысловой слой; теперь в Figma есть переменная `icon-accent` с тем же
  /// значением, и привязка идёт через неё (`296:745`, `296:767`).
  static const iconAccent = P.accent500;

  // --- Чернила -------------------------------------------------------------
  static const inkPrimary = P.inkRed;
  static const inkSecondary = P.inkBlue;
  static const inkTertiary = P.inkGreen;
  static const inkNeutral = P.inkGraphite;

  /// Все смысловые цвета по именам из Figma — для каталога и сверки.
  ///
  /// `text-default` / `-subtle` / `-muted` сюда не входят: они зависят от
  /// режима и живут на [InkMode]. Каталог показывает их отдельным блоком.
  static const all = <String, Color>{
    'surface-default': surfaceDefault,
    'surface-subtle': surfaceSubtle,
    'surface-sunken': surfaceSunken,
    'surface-action-primary': surfaceActionPrimary,
    'surface-action-secondary': surfaceActionSecondary,
    'surface-action-pressed': surfaceActionPressed,
    'surface-action-disabled': surfaceActionDisabled,
    'surface-accent': surfaceAccent,
    'surface-accent-subtle': surfaceAccentSubtle,
    'surface-overlay': surfaceOverlay,
    'surface-glass': surfaceGlass,
    'surface-glass-pressed': surfaceGlassPressed,
    'surface-dim': surfaceDim,
    'surface-paper': surfacePaper,
    'surface-paper-edge': surfacePaperEdge,
    'surface-tile-sage': surfaceTileSage,
    'surface-tile-blush': surfaceTileBlush,
    'surface-tile-sky': surfaceTileSky,
    'surface-tile-sun': surfaceTileSun,
    'text-on-action': textOnAction,
    'text-accent': textAccent,
    'text-error': textError,
    'text-disabled': textDisabled,
    'text-on-status': textOnStatus,
    'text-on-warning': textOnWarning,
    'text-on-soft': textOnSoft,
    'text-link': textLink,
    'border-default': borderDefault,
    'border-strong': borderStrong,
    'border-accent': borderAccent,
    'border-error': borderError,
    'border-focus-ring': borderFocusRing,
    'border-paper-rule': borderPaperRule,
    'bg-success': bgSuccess,
    'bg-warning': bgWarning,
    'bg-error': bgError,
    'bg-info': bgInfo,
    'icon-accent': iconAccent,
    'ink-primary': inkPrimary,
    'ink-secondary': inkSecondary,
    'ink-tertiary': inkTertiary,
    'ink-neutral': inkNeutral,
  };

  /// Имя примитива, на который ссылается смысловой токен. В Figma это видно
  /// в панели переменных; в коде связь есть в исходнике, но не в рантайме —
  /// поэтому здесь она записана отдельной картой.
  static const aliases = <String, String>{
    'surface-default': 'gray-00',
    'surface-subtle': 'gray-50',
    'surface-sunken': 'paper-100',
    'surface-action-primary': 'gray-950',
    'surface-action-secondary': 'paper-200',
    'surface-action-pressed': 'accent-500',
    'surface-action-disabled': 'paper-100',
    'surface-accent': 'accent-500',
    'surface-accent-subtle': 'accent-100',
    'surface-overlay': 'gray-950',
    'surface-glass': 'white-a50',
    'surface-glass-pressed': 'white-a80',
    'surface-dim': 'ink-a30',
    'surface-paper': 'paper-00',
    'surface-paper-edge': 'paper-100',
    'surface-tile-sage': 'tile-sage',
    'surface-tile-blush': 'tile-blush',
    'surface-tile-sky': 'tile-sky',
    'surface-tile-sun': 'tile-sun',
    'text-on-action': 'gray-00',
    'text-accent': 'accent-700',
    'text-error': 'error-500',
    'text-disabled': 'gray-300',
    'text-on-status': 'gray-00',
    'text-on-warning': 'gray-950',
    'text-on-soft': 'gray-950',
    'text-link': 'blue-600',
    'border-default': 'gray-200',
    'border-strong': 'gray-300',
    'border-accent': 'accent-500',
    'border-error': 'error-500',
    'border-focus-ring': 'accent-500',
    'border-paper-rule': 'paper-200',
    'bg-success': 'success-500',
    'bg-warning': 'warning-500',
    'bg-error': 'error-500',
    'bg-info': 'info-500',
    'icon-accent': 'accent-500',
    'ink-primary': 'ink-red',
    'ink-secondary': 'ink-blue',
    'ink-tertiary': 'ink-green',
    'ink-neutral': 'ink-graphite',
  };
}
