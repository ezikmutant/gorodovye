// Сборка каталога: что в каком разделе.
//
// Каталог — курсовая директива `directives/directive_storybook.md`,
// переложенная на Flutter. Разделов три, как там: Foundation (все переменные),
// компоненты (каждый со своими вариантами и состояниями) и песочницы
// (компоненты в связке).

import 'package:flutter/widgets.dart';

import '../ds/ds.dart';
import 'chrome.dart';
import 'model.dart';
import 'pages/elements.dart';
import 'pages/foundation.dart';
import 'pages/sandboxes.dart';
import 'pages/tokens.dart';

export 'chrome.dart' show CatalogApp;
export 'model.dart';

/// Первая страница: что это и как читать.
final aboutPage = DocPage(
  title: 'О каталоге',
  doc: 'Каталог компонентов «Городовых» — зеркало Figma-файла '
      'eK3JWxVILnuTJc2B8Zqx8Z, страница UI. Собран из настоящих компонентов '
      'базы (lib/ds/), а не перерисован заново: что в базе, то и здесь. '
      'Это инструмент сверки и форма передачи разработке.',
  body: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CatalogBlock(
        'Как читать страницу компонента',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Line('Стенд', 'живой компонент, а не картинка: нажимается, '
                'фокусируется, проседает под пальцем'),
            _Line('Пресеты', 'именованные состояния — переставляют стенд '
                'целиком'),
            _Line('Контролы', 'каждый проп крутится живьём'),
            _Line('Код', 'то, что вставляют в экран. Собирается из значений '
                'на стенде, копируется кнопкой'),
            _Line('Пропсы', 'полный список параметров конструктора с типами '
                'и значениями по умолчанию'),
            _Line('Матрица', 'все варианты × состояния рядом — для сверки '
                'с Figma одним взглядом'),
          ],
        ),
      ),
      const SizedBox(height: Space.s6),
      CatalogBlock(
        'Чего здесь нет',
        doc: 'Каталог не богаче базы, и это честно.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Line('15 компонентов из 38', 'экраны (Screen/*, Sheet), блоки '
                'карты, камеры и альбома, фигурки городовых. Экраны '
                'собираются из ДС, а не входят в неё; остальному нужны карта, '
                'слоты и данные снапшота'),
            _Line('Иконки', 'DsIcon держит размер и цвет, но рисует рамку '
                'вместо глифа. Настоящие контуры Lucide — отдельная задача '
                'про ассеты; заглушка намеренно выглядит заглушкой'),
            _Line('Постановка штампа', 'сцена на 600–700 мс из шести шагов '
                'живёт в ds/motion.md. В компонент она не входит: это не '
                'переход между состояниями, а единственная награда продукта'),
          ],
        ),
      ),
      const SizedBox(height: Space.s6),
      CatalogBlock(
        'Как запустить',
        child: CodeBlock('cd app\n'
            'flutter run -d chrome -t lib/catalog_main.dart   # каталог\n'
            'flutter run -d chrome                            # витрина\n'
            'flutter test                                     # тесты и снимок'),
      ),
    ],
  ),
);

class _Line extends StatelessWidget {
  const _Line(this.term, this.text);

  final String term;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s2),
      child: SizedBox(
        width: 760,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 200,
              child: Text(term,
                  style: T.bodySmMedium
                      .copyWith(color: InkMode.light.textDefault)),
            ),
            Expanded(
              child: Text(text,
                  style: T.bodySm.copyWith(color: InkMode.light.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Все компоненты базы, представленные в каталоге.
final catalogComponents = <ComponentPage>[...foundationPages, ...elementPages];

final catalogSections = <Section>[
  Section('Каталог', [DocEntry(aboutPage)]),
  Section('Foundation', [for (final page in tokenPages) DocEntry(page)]),
  Section('Компоненты', [
    for (final page in catalogComponents) ComponentEntry(page),
  ]),
  Section('Песочницы', [for (final page in sandboxPages) DocEntry(page)]),
];
