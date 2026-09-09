// Модель каталога.
//
// Каталог — это Storybook из курсовой директивы `directive_storybook.md`,
// переложенный на Flutter. Storybook к виджетам не прикручивается: он живёт в
// вебе и знает про React. Переносится не инструмент, а его смысл — страница на
// каждый компонент, где выложены все варианты, крутятся пропсы и берётся
// готовый кусок кода.
//
// Соответствие понятий:
//
// | Storybook            | здесь                                  |
// |----------------------|----------------------------------------|
// | `*.stories.tsx`      | [ComponentPage] в `pages/`             |
// | `argTypes`           | [Prop] с [ControlKind]                 |
// | `args`               | [Prop.initial]                         |
// | именованная story    | [Preset]                               |
// | story `AllVariants`  | [ComponentPage.matrix]                  |
// | autodocs + Copy code | таблица пропсов и сниппет, оба из [Prop] |
//
// Главное правило директивы: каталог собирается **из настоящих компонентов
// базы**, а не перерисовывается заново. Поэтому здесь нет ни одного своего
// виджета продукта — только `Ds*` из `lib/ds/`.

import 'package:flutter/widgets.dart';

/// Чем крутится проп в панели.
enum ControlKind {
  /// Перечисление: все значения кнопками в ряд.
  radio,

  /// Булево.
  toggle,

  /// Строка.
  text,

  /// Контрола нет: проп есть у конструктора, но крутить его на стенде нечем —
  /// `controller`, `onChanged`, `onTap`. В таблице он остаётся: разработчику
  /// нужен полный список, а не только то, что показалось интерактивным.
  none,
}

/// Фон стенда. Белое на белом не видно, поэтому фон — свойство страницы,
/// а не общее решение: стеклянная кнопка живёт поверх карты, `StatusBar` —
/// поверх тёмного, остальное — на бумаге.
enum Stage { plain, sunken, dark, map }

/// Один проп компонента: строка таблицы и контрол в панели одновременно.
///
/// Две сущности намеренно сведены в одну. В Storybook `argTypes` и таблица
/// пропсов расходятся руками, и таблица устаревает первой; здесь расходиться
/// нечему.
class Prop {
  const Prop({
    required this.name,
    required this.type,
    required this.initial,
    this.doc = '',
    this.options = const <Object?>[],
    this.kind = ControlKind.radio,
    this.optionLabel,
    this.inCode = true,
  });

  /// Имя параметра конструктора: `type`, `size`, `label`.
  final String name;

  /// Тип, как он написан в Dart: `DsButtonType`, `String?`, `bool`.
  final String type;

  /// Значение по умолчанию — оно же стартовое в панели.
  final Object? initial;

  /// Что делает проп. Попадает в таблицу.
  final String doc;

  /// Варианты для [ControlKind.radio].
  final List<Object?> options;

  final ControlKind kind;

  /// Подпись варианта, если имя значения само по себе непонятно.
  final String Function(Object? value)? optionLabel;

  /// Показывать ли проп в сниппете кода. Витринные приёмы вроде `forceState`
  /// в продуктовый код не попадают — и в сниппете их быть не должно.
  final bool inCode;

  String show(Object? value) {
    if (optionLabel != null) return optionLabel!(value);
    if (value == null) return '—';
    if (value is Enum) return value.name;
    if (value is String) return value.isEmpty ? '«пусто»' : value;
    return '$value';
  }
}

/// Значения пропсов на стенде.
class Args {
  const Args(this.values);

  final Map<String, Object?> values;

  T get<T>(String name) => values[name] as T;

  Object? raw(String name) => values[name];
}

/// Именованная стори: набор значений с осмысленным именем.
///
/// В Storybook это `export const Primary: Story = {...}`. Здесь пресет не
/// отдельная страница, а кнопка, которая переставляет стенд, — так варианты
/// видно рядом, а не по одному.
class Preset {
  const Preset(this.name, this.args, {this.doc = ''});

  final String name;
  final Map<String, Object?> args;
  final String doc;
}

/// Страница компонента.
class ComponentPage {
  const ComponentPage({
    required this.name,
    required this.figma,
    required this.doc,
    required this.props,
    required this.build,
    required this.code,
    this.presets = const [],
    this.matrix,
    this.matrixTitle = 'Все варианты',
    this.matrixDoc = '',
    this.stage = Stage.plain,
    this.notes = const [],
  });

  /// Имя в коде: `DsButton`.
  final String name;

  /// Имя и узел в Figma: `Button · 29:11`.
  final String figma;

  /// Что это и зачем.
  final String doc;

  final List<Prop> props;
  final List<Preset> presets;

  /// Стенд. [set] позволяет компоненту менять собственные пропсы —
  /// так `Navbar`, `Chip` и `FilterRow` на стенде живые, а не приколоченные.
  final Widget Function(BuildContext context, Args args, ArgSetter set) build;

  /// Сниппет для передачи разработчику.
  final String Function(Args args) code;

  /// Матрица вариантов целиком — сверка с Figma одним взглядом.
  final WidgetBuilder? matrix;
  final String matrixTitle;
  final String matrixDoc;

  final Stage stage;

  /// Оговорки: что снято замером, что выведено, чего в переносе нет.
  final List<String> notes;
}

typedef ArgSetter = void Function(String name, Object? value);

/// Страница без компонента: токены, правила, песочница.
class DocPage {
  const DocPage({required this.title, required this.doc, required this.body});

  final String title;
  final String doc;
  final WidgetBuilder body;
}

/// Элемент навигации.
sealed class Entry {
  const Entry();

  String get title;
  String get subtitle;
}

class ComponentEntry extends Entry {
  const ComponentEntry(this.page);

  final ComponentPage page;

  @override
  String get title => page.name;

  @override
  String get subtitle => page.figma;
}

class DocEntry extends Entry {
  const DocEntry(this.page);

  final DocPage page;

  @override
  String get title => page.title;

  @override
  String get subtitle => '';
}

/// Раздел навигации.
class Section {
  const Section(this.title, this.entries);

  final String title;
  final List<Entry> entries;
}
