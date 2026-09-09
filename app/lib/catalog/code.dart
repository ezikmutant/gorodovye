// Сборка сниппета для страницы компонента.
//
// Сниппет — не украшение: это то, что копируют и вставляют в экран. Поэтому он
// показывает не «как выглядит стенд», а **как это пишется в продукте**:
// витринные приёмы (`forceState`) из него выброшены, а строки, у которых есть
// переменная, подставляются переменной, а не текстом. Подпись, набранная
// руками, — уже нарушение контракта (`ds/CONTRACT.md`, правило 5).

import '../ds/ds.dart';

/// Собрать вызов конструктора.
String snippet(String name, List<String> args, {String? note}) {
  final buffer = StringBuffer();
  if (note != null) buffer.writeln('// $note');
  if (args.isEmpty) {
    buffer.write('const $name()');
    return buffer.toString();
  }
  buffer.writeln('$name(');
  for (final arg in args) {
    buffer.writeln('  $arg,');
  }
  buffer.write(')');
  return buffer.toString();
}

/// Строковый литерал Dart.
String literal(String value) => "'${value.replaceAll("'", r"\'")}'";

/// Строка так, как её положено писать: переменной, если такая есть.
///
/// `L.found` вместо `'Нашёл!'` — не педантизм. Формулировка меняется в одном
/// месте и расходится по всем экранам, и это же готовый ключ локализации.
String text(String value) {
  for (final entry in L.all.entries) {
    if (entry.value == value) {
      return 'L.${_camel(entry.key.substring('label-'.length))}';
    }
  }
  for (final entry in M.all.entries) {
    if (entry.value == value) {
      return 'M.${_camel(entry.key.substring('msg-'.length))}';
    }
  }
  return literal(value);
}

/// `trust-me` → `trustMe`.
String _camel(String kebab) {
  final parts = kebab.split('-');
  return [
    parts.first,
    for (final part in parts.skip(1))
      part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1),
  ].join();
}
