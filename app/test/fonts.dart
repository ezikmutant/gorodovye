// Настоящие гарнитуры в тестах.
//
// По умолчанию тест рисует каждый глиф полным кегельным квадратом, и любая
// длинная подпись «переполняет» строку, которой в жизни хватает с запасом:
// «Показать на карте» — 306 пикселей вместо 165. Ложное переполнение ловится
// как ошибка раскладки, поэтому там, где меряется ширина, шрифты грузятся.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gorodovye/ds/ds.dart';

Future<void> loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(
        Future.value(File(path).readAsBytesSync().buffer.asByteData()));
  await loader.load();
}

/// Обе гарнитуры ДС.
Future<void> loadDsFonts() async {
  await loadFont(FontFamily.display, 'assets/fonts/DelaGothicOne-Regular.ttf');
  await loadFont(FontFamily.sans, 'assets/fonts/Onest-Variable.ttf');
}
