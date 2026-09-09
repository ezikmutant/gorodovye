// Строковые переменные из `ds/foundation.md`.
//
// Тексты кнопок и сообщений живут здесь, а не набираются на экране:
// формулировка меняется в одном месте и расходится по всем экранам. Это же
// готовый ключ для локализации.
//
// `L` и `M` различаются по роли и разведены намеренно: `label-` — надпись на
// управляющем элементе, `msg-` — сообщение системы о её собственном состоянии.
// Подписи короткие и почти не меняются, сообщения переписываются чаще всего и
// правятся редактурой отдельно от интерфейса.

/// Подписи управляющих элементов.
abstract final class L {
  static const found = 'Нашёл!';
  static const trustMe = 'Я на месте, поверить мне';
  static const gpsFar = 'По GPS городовой далеко';
  static const showMap = 'Показать на карте';
  static const retry = 'Повторить';
  static const removeFind = 'Убрать из находок';
  static const undoWindow = 'Ещё 5 секунд';
  static const next = 'Дальше';
  static const start = 'Начать';
  static const skip = 'Пропустить';

  static const all = <String, String>{
    'label-found': found,
    'label-trust-me': trustMe,
    'label-gps-far': gpsFar,
    'label-show-map': showMap,
    'label-retry': retry,
    'label-remove-find': removeFind,
    'label-undo-window': undoWindow,
    'label-next': next,
    'label-start': start,
    'label-skip': skip,
  };
}

/// Сообщения системы о собственном состоянии.
abstract final class M {
  static const offlineMap = 'Нет сети. Показываем, что успели загрузить';
  static const offlineAlbum =
      'Нет сети. Находки на месте — они хранятся на телефоне';
  static const saveFailed = 'Не удалось сохранить';

  static const all = <String, String>{
    'msg-offline-map': offlineMap,
    'msg-offline-album': offlineAlbum,
    'msg-save-failed': saveFailed,
  };
}
