import 'package:flutter/widgets.dart';

import 'tokens/semantics.dart';

/// Переносит чернильный контекст вниз по дереву.
///
/// В Figma режим включается точечно, на конкретном узле, — здесь так же:
/// [DsInk] оборачивает поддерево, а не приложение. Обёртки нет — значит
/// [InkMode.light], как и в макете по умолчанию.
///
/// Тема Flutter для этого не годится принципиально: тема глобальна и
/// переключается на всё приложение, а режим — локальное заявление «дальше
/// рисуем на тёмном». Продукт почти монохромный и тёмной темы не имеет.
class DsInk extends InheritedWidget {
  const DsInk({super.key, required this.mode, required super.child});

  final InkMode mode;

  static InkMode of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DsInk>()?.mode ??
      InkMode.light;

  @override
  bool updateShouldNotify(DsInk oldWidget) => oldWidget.mode != mode;
}
