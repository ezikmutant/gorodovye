// Точка входа каталога.
//
// Отдельная от `main.dart` намеренно. В Storybook каталог поднимается своей
// командой и живёт на своём адресе — здесь так же:
//
//     flutter run -d chrome -t lib/catalog_main.dart
//
// `main.dart` остаётся приложением: сейчас в нём витрина, дальше появятся
// экраны продукта. Каталог в продуктовую сборку не попадает.

import 'package:flutter/widgets.dart';

import 'catalog/catalog.dart';

void main() => runApp(CatalogApp(sections: catalogSections));
