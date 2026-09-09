/// Дизайн-система «Городовых» в коде.
///
/// Зеркало Figma-файла `eK3JWxVILnuTJc2B8Zqx8Z`, страница **UI**. Имена
/// токенов и компонентов те же, что в `ds/foundation.md` и `ds/components.md`;
/// меняется только носитель.
///
/// Компоненты названы с приставкой `Ds` (`DsButton` ↔ Figma `Button`).
/// Приставка нужна из-за одного столкновения: `IconButton` уже занят Flutter.
/// Разнобой — половина с приставкой, половина без — читался бы хуже, поэтому
/// приставку носят все.
///
/// Соответствие имён и то, что осталось за пределами переноса, — в
/// `ds/flutter.md`.
library;

export 'components/elements.dart';
export 'components/foundation.dart';
export 'ink_mode.dart';
export 'tokens/motion.dart';
export 'tokens/primitives.dart';
export 'tokens/semantics.dart';
export 'tokens/shadows.dart';
export 'tokens/strings.dart';
export 'tokens/typography.dart';
