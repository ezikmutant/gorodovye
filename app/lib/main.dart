import 'package:flutter/widgets.dart';

import 'ds/ds.dart';
import 'showcase.dart';

void main() => runApp(const GorodovyeApp());

/// Корень приложения.
///
/// `WidgetsApp`, а не `MaterialApp`: продукт почти монохромный, со своей
/// палитрой, шкалой и компонентами, и материаловская тема здесь только мешала
/// бы — её пришлось бы перекрывать в каждом месте. `uses-material-design` в
/// pubspec выключен по той же причине.
///
/// Пока корневой экран — витрина ДС. Экраны продукта появятся позже, и тогда
/// витрина уедет за отдельный вход.
class GorodovyeApp extends StatelessWidget {
  const GorodovyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Городовые',
      color: S.surfaceDefault,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      builder: (context, child) => const Directionality(
        textDirection: TextDirection.ltr,
        child: Showcase(),
      ),
    );
  }
}
