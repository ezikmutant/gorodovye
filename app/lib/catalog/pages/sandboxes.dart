// Песочницы: компоненты не по одному, а в связке.
//
// Директива называет блоки чужого продукта — модальное окно, форма, навигация,
// таблица. У нас блоки свои, и взяты они из `ds/patterns.md` и экранов:
// шторка находки, фильтры карты, слой поверх карты, форма. Смысл тот же —
// увидеть, как элементы ведут себя вместе, а не по отдельности.
//
// Собраны песочницы из тех же инстансов ДС. Ни одного своего виджета продукта
// здесь нет: то, что не перенесено (MapMarker, Sheet, BottomAction), честно
// заменено заглушкой и подписано.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../ds/ds.dart';
import '../chrome.dart';
import '../model.dart';

// ---------------------------------------------------------------------------
// Шторка находки
// ---------------------------------------------------------------------------

final sheetSandbox = DocPage(
  title: 'Шторка находки',
  doc: 'Главный экран продукта по макету `Sheet` (`301:1872`). Числа сняты '
      'с узлов: фигурка 300×300, имя `DS/Heading/3xl` — единственное место, '
      'где в интерфейсе появляется Dela Gothic. Отметка находки лежит '
      '**поверх** имени и увеличена: это оттиск, а оттиск ставят по месту, '
      'а не вкладывают в строку. Переключите «найдено» — уйдут отметка и '
      'блок «Мои фото»: своих снимков до находки не бывает.',
  body: (context) => const _FindSheet(),
);

class _FindSheet extends StatefulWidget {
  const _FindSheet();

  @override
  State<_FindSheet> createState() => _FindSheetState();
}

class _FindSheetState extends State<_FindSheet>
    with SingleTickerProviderStateMixin {
  bool _found = true;

  /// Спойлер «Как выглядит» открыт: по этому флагу снимки играют появление.
  bool _looksOpen = false;

  /// Какой снимок открыт во весь экран. `null` — просмотрщик закрыт.
  int? _viewing;

  /// Где показать окно просмотрщика — отступ сверху внутри шторки.
  ///
  /// В продукте просмотрщик занимает экран, и вопроса нет. В песочнице
  /// шторка нарисована во всю длину, метра три, и окно, прибитое к её
  /// верху, открывалось за пределами видимого — выглядело так, будто
  /// снимки не нажимаются. Поэтому окно встаёт вокруг того снимка,
  /// по которому нажали.
  double _viewerTop = 0;

  final _sheetKey = GlobalKey();
  final _photoKeys = [for (var i = 0; i < 3; i++) GlobalKey()];

  static const _viewerHeight = 812.0;

  /// Открытие и закрытие просмотрщика. Своим контроллером, а не появлением
  /// по монтажу: закрытие тоже обязано быть мягким, а `DsAppear` умеет
  /// только приходить.
  late final AnimationController _viewerC =
      AnimationController(vsync: this, duration: Motion.reveal);
  late final CurvedAnimation _viewerT = CurvedAnimation(
    parent: _viewerC,
    curve: Motion.easeReveal,
    reverseCurve: FlippedCurve(Motion.easeReveal),
  );

  void _openViewer(int index) {
    final photo = _photoKeys[index].currentContext?.findRenderObject();
    final sheet = _sheetKey.currentContext?.findRenderObject();
    var top = 0.0;
    if (photo is RenderBox && sheet is RenderBox) {
      final centre = sheet
          .globalToLocal(photo.localToGlobal(photo.size.center(Offset.zero)));
      top = (centre.dy - _viewerHeight / 2)
          .clamp(0.0, math.max(0.0, sheet.size.height - _viewerHeight));
    }
    setState(() {
      _viewing = index;
      _viewerTop = top;
    });
    _viewerC.forward(from: 0);
  }

  void _closeViewer() {
    _viewerC.reverse().whenComplete(() {
      if (mounted) setState(() => _viewing = null);
    });
  }

  @override
  void dispose() {
    _viewerT.dispose();
    _viewerC.dispose();
    super.dispose();
  }

  /// Снимки «Как выглядит»: ширина 300, идут друг под другом.
  static const _looks = [
    S.surfaceTileSage,
    S.surfaceTileSky,
    S.surfaceTileSun,
  ];
  static const _lookWidth = 300.0;
  static const _lookHeight = 225.0;

  static const _screen = 375.0;
  static const _pad = Space.s4;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Stack(
        children: [
          _sheet(),
          // Кнопка плавает поверх содержимого, а не стоит в потоке: под ней
          // градиент, контент уходит вниз и это видно — значит, можно листать
          // (`ds/patterns.md`).
          Positioned(left: 0, bottom: 0, child: _bottomAction()),
          // Просмотрщик накрывает всё: и шторку, и кнопку. Мягко — тем же
          // `ease-reveal`, что раскрывает спойлер.
          if (_viewing != null) _photoViewer(_viewing!),
        ],
      ),
    );
  }

  /// `BottomAction` (`331:1305`), варианты `found` и `showOnMap`.
  ///
  /// В ДС этот блок не перенесён — он привязан к экрану, а не к киту
  /// (`ds/flutter.md`). Здесь собран по месту из `DsButton` и градиента,
  /// числа сняты с узла: полоса 136, кнопка 56 на полях по 20, от низа 24.
  ///
  /// Действие зависит от состояния: не найден — чёрное «Нашёл!», найден —
  /// вторичное «Показать на карте». Убрать из находок отсюда нельзя: это
  /// не действие первого плана.
  Widget _bottomAction() => SizedBox(
        width: _screen,
        height: 136,
        child: Stack(
          children: [
            // Градиент внутри блока, а не отдельным слоем экрана: иначе его
            // приходится повторять руками на каждом экране (`components.md`).
            // Скрим не ловит пальцы: он декорация, а под ним живой текст.
            // Без этого полоса в 136 пикселей глушит нажатия по всему низу
            // экрана — поймано тестом песочницы.
            Positioned.fill(
              child: IgnorePointer(
                  child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      S.surfaceDefault.withValues(alpha: 0),
                      S.surfaceDefault,
                    ],
                  ),
                ),
              )),
            ),
            Positioned(
              left: Space.s5,
              right: Space.s5,
              bottom: Space.s6,
              child: DsButton(
                label: _found ? L.showMap : L.found,
                type: _found ? DsButtonType.secondary : DsButtonType.primary,
                expand: true,
                onPressed: () {},
              ),
            ),
          ],
        ),
      );

  /// Лист шторки: белый, радиус `xl`. Внутри два блока со своими заливками —
  /// серая шапка и белый `Content`, оба со скруглением `card` сверху.
  ///
  /// Заливки не украшение: без них зазор под адресом читается дырой,
  /// а с ними — стыком блоков. Ровно из-за этого сорок восемь пикселей,
  /// честно снятые с макета, выглядели ошибкой.
  Widget _sheet() {
    return Container(
      key: _sheetKey,
      width: _screen,
      decoration: BoxDecoration(
        color: S.surfaceDefault,
        // 38, а не 24: у самой шторки радиус `xl` (`301:1872`), а `card`
        // носят блоки внутри неё.
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        boxShadow: Shadows.sheet,
      ),
      child: Stack(
        children: [
          Column(
            // По содержимому, а не во всю высоту: иначе шторка растягивается
            // на весь холст песочницы, под текстом остаётся пустое поле,
            // а плавающая кнопка уезжает от него на сотни пикселей.
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(),
              // Правого поля у блока нет: «Мои фото» шириной 359 при экране
              // 375 упираются в край, и лента снимков уезжает за него —
              // иначе скроллить было бы нечего. Остальные блоки поле
              // добирают сами.
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: S.surfaceDefault,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(Radii.card)),
                ),
                child: Padding(
                  // Снизу 96, как в макете (`Content` 967 при тексте до 871):
                  // столько нужно, чтобы последний блок ушёл из-под плавающей
                  // кнопки, а не прятался за ней.
                  padding: const EdgeInsets.fromLTRB(
                      _pad, Space.s6, 0, Space.s20 + Space.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_found) ...[
                        _myPhotos(),
                        const SizedBox(height: Space.s8),
                      ],
                      _inset(DsSpoilers(children: [
                        DsSpoiler(
                          title: 'Где искать',
                          child: Text(
                            'На фасаде, между вторым и третьим этажом. '
                            'Смотрите выше вывески.',
                            style: T.bodyBase
                                .copyWith(color: InkMode.light.textSubtle),
                          ),
                        ),
                        DsSpoiler(
                          title: 'Как выглядит · ${_looks.length}',
                          kind: DsSpoilerKind.photo,
                          onToggle: (open) => setState(() => _looksOpen = open),
                          child: _looksLike(),
                        ),
                      ])),
                      const SizedBox(height: Space.s8),
                      _inset(Text(
                        'В 2014 году в Будапеште установили скульптуру '
                        'лейтенанта Коломбо — герою американского '
                        'детективного сериала. А спустя несколько лет рядом '
                        'появилась фигурка белки с пистолетом. Получилось '
                        'так, будто детектив приступает к расследованию '
                        'загадочной гибели животного.',
                        style: T.bodyBase
                            .copyWith(color: InkMode.light.textDefault),
                      )),
                      const SizedBox(height: Space.s6),
                      _inset(DsButton(
                        label: _found ? 'Ненайденный' : 'Найденный',
                        type: DsButtonType.ghost,
                        size: DsButtonSize.sm,
                        onPressed: () => setState(() => _found = !_found),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Ручка лежит поверх шапки, а не в потоке: в макете она абсолютная
          // (`301:1869`), и её шестнадцать пикселей не сдвигают фигурку.
          // В потоке она отодвигала весь блок, и отметка находки вставала
          // на шестнадцать ниже места, снятого с макета.
          const Positioned.fill(
            child: Align(alignment: Alignment.topCenter, child: DsHandle()),
          ),
        ],
      ),
    );
  }

  /// Фигурка, имя и адрес одним блоком на 494. Отметка находки лежит поверх
  /// него, а не в потоке: у оттиска своё место и свой масштаб.
  Widget _hero() => DecoratedBox(
        // Серая шапка (`301:1801`, `surface-subtle`) со своим скруглением.
        decoration: const BoxDecoration(
          color: S.surfaceSubtle,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.card)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Блок собран потоком, а не по абсолютным координатам.
            // В макете имя — «рыба» в две строки и адрес в две, поэтому
            // фигурка, текст и низ блока сходятся в 494. У живого названия
            // строк меньше, и прибитая высота оставляла под адресом дыру.
            // Числа макетные: 36 сверху, фигурка 300, 4 до текста.
            //
            // **Расхождение с макетом.** Снизу у героя там 24, и вместе
            // с верхними 24 у `Content` под адресом выходит 48. На «рыбе»
            // в две строки это не читается, на живом адресе в одну — дыра
            // (сказано дважды). Здесь 8, то есть суммарно 32 — тот же шаг,
            // каким `Content` разделяет свои блоки. В Figma пока 24:
            // правка макета за автором.
            Padding(
              padding: const EdgeInsets.only(top: 36, bottom: Space.s6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Слот: фигурка приходит из снапшота, в ДС её нет.
                  Align(
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: S.surfaceTileBlush,
                        borderRadius: BorderRadius.circular(Radii.full),
                      ),
                      alignment: Alignment.center,
                      child: Mono('городовой'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Белка с пистолетом',
                            style: T.heading3xl
                                .copyWith(color: InkMode.light.textDefault)),
                        const SizedBox(height: Space.s2),
                        Text('Средний Кисловский пер., 12',
                            style: T.bodyBase
                                .copyWith(color: InkMode.light.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_found)
              Positioned(
                left: 115.1,
                // В макете 323.5 — оттиск ложится на имя и закрывает первую
                // строку. Поднят на нижнюю треть фигурки: `patterns.md`
                // говорит, что штамп ставится **на городового**, а не рядом
                // с ним, и лица не закрывает. Габарит повёрнутого 78,
                // фигурка кончается на 336 — значит верх 250.
                // Расхождение с макетом, синхронизировать по слову автора.
                top: 250,
                // Размер натуральный, 247×44. Повёрнута на 8° — оттиск
                // ставят рукой, а рука не держит горизонт. Габарит
                // повёрнутого элемента в метаданных больше самого элемента,
                // и принять его за размер значит растянуть отметку вдвое.
                //
                // Figma считает поворот против часовой, Flutter — по
                // часовой, поэтому знак обратный.
                child: Transform.rotate(
                  angle: -8 * math.pi / 180,
                  child: const DsFoundBadge(date: '12.06.26'),
                ),
              ),
          ],
        ),
      );

  /// Правое поле для тех блоков, которые до края не идут.
  Widget _inset(Widget child) =>
      Padding(padding: const EdgeInsets.only(right: _pad), child: child);

  /// `My photos` (`299:4514`): подпись, кнопка «поделиться» и лента снимков.
  Widget _myPhotos() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inset(Row(
            children: [
              Expanded(
                child: Text('Мои фото',
                    style:
                        T.headingLg.copyWith(color: InkMode.light.textDefault)),
              ),
              // Поделиться, а не «что это»: снимки свои, и первое, что
              // с ними делают, — показывают. Тип secondary — плотная
              // кнопка, а не призрачная.
              DsIconButton(
                icon: DsIconName.share2,
                type: DsIconButtonType.secondary,
                size: DsIconButtonSize.sm,
                onPressed: () {},
              ),
            ],
          )),
          const SizedBox(height: Space.s3),
          _photoStrip(),
        ],
      );

  /// Снимки лентой: 139×269, зазор 12, скролл вбок. Лента уходит за правый
  /// край экрана — так видно, что она продолжается, и её хочется потянуть.
  /// Слот `Photos` в ДС не входит, содержимое кладёт экран.
  /// «Как выглядит»: снимки друг под другом, ширина 300.
  ///
  /// Не лента: этот блок открывают, чтобы **разглядеть**, ту ли фигурку
  /// ищешь. Горизонтальная прокрутка тут заставляла бы листать вслепую,
  /// а вертикальная — та же, которой человек уже читает карточку.
  ///
  /// Появляются по очереди, когда спойлер открыли: порт `AnimatedGroup`
  /// с пресетом `scale` — 100 мс между соседями.
  Widget _looksLike() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _looks.length; i++) ...[
            if (i > 0) const SizedBox(height: Space.s3),
            DsAppear(
              index: i,
              play: _looksOpen,
              child: GestureDetector(
                onTap: () => _openViewer(i),
                child: Container(
                  key: _photoKeys[i],
                  width: _lookWidth,
                  height: _lookHeight,
                  decoration: BoxDecoration(
                    color: _looks[i],
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
              ),
            ),
          ],
        ],
      );

  /// `Screen/PhotoViewer` (`498:5266`): снимок во весь экран на тёмном.
  ///
  /// Числа с макета: фон `surface-overlay`, закрытие — стеклянный круг 44
  /// в левом верхнем углу, счётчик стеклянной пилюлей по центру сверху,
  /// внизу два стеклянных круга с зазором 48 — сохранить и поделиться.
  ///
  /// Снимок вписан по ширине и увеличивается щипком: `InteractiveViewer`
  /// до четырёх крат. Больше не нужно — дальше это уже не снимок, а пиксели.
  Widget _photoViewer(int index) => Positioned(
        left: 0,
        top: _viewerTop,
        width: _screen,
        // Экран, а не вся шторка: просмотрщик в продукте занимает окно
        // телефона (375×812), а песочница показывает шторку во всю длину.
        // Растянуть его на неё значило бы увести кнопки на полкилометра
        // от снимка, а прибить к верху — открывать за пределами видимого.
        height: _viewerHeight,
        child: FadeTransition(
          opacity: _viewerT,
          child: ScaleTransition(
            // Снимок разворачивается, а не подменяет экран: масштаб от 0.92
            // читается как «эта карточка выросла».
            scale: Tween<double>(begin: 0.92, end: 1).animate(_viewerT),
            child: DsInk(
              mode: InkMode.onDark,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: S.surfaceOverlay),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: DsStatusBar(theme: DsStatusBarTheme.dark),
                  ),
                  Positioned.fill(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: SizedBox(
                          width: _screen,
                          height: _screen * _lookHeight / _lookWidth,
                          child: ColoredBox(color: _looks[index]),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _pad,
                    // Числа с макета: закрытие на 56 от верха, счётчик на 64 —
                    // оба ниже строки состояния.
                    top: 56,
                    child: DsIconButton(
                      icon: DsIconName.x,
                      type: DsIconButtonType.glass,
                      size: DsIconButtonSize.sm,
                      onPressed: _closeViewer,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 64,
                    child: Align(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: S.surfaceGlass,
                          borderRadius: BorderRadius.circular(Radii.full),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Space.s3, vertical: Space.s1),
                          child: Text('${index + 1} / ${_looks.length}',
                              style: T.labelSm
                                  .copyWith(color: InkMode.light.textDefault)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: Space.s8,
                    child: Align(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DsIconButton(
                            icon: DsIconName.download,
                            type: DsIconButtonType.glass,
                            size: DsIconButtonSize.sm,
                            onPressed: () {},
                          ),
                          const SizedBox(width: Space.s12),
                          DsIconButton(
                            icon: DsIconName.share2,
                            type: DsIconButtonType.glass,
                            size: DsIconButtonSize.sm,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _photoStrip() => SizedBox(
        height: 269,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: _pad),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: Space.s3),
          itemBuilder: (context, i) => Container(
            width: 139,
            decoration: BoxDecoration(
              color: const [
                S.surfaceTileSage,
                S.surfaceTileSky,
                S.surfaceTileSun,
                S.surfaceTileBlush,
                S.surfaceTileSage,
              ][i],
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Фильтры карты
// ---------------------------------------------------------------------------

final filtersSandbox = DocPage(
  title: 'Фильтры карты',
  doc: 'Выпадающая панель: статус списком с галочкой, коллекции чипами '
      'с переносом. Форма кодирует тип выбора — галочка читается как '
      '«один из», чип как «сколько угодно». Объяснять это текстом не нужно, '
      'если форма уже показывает правило. Один-два чипа снимаются повторным '
      'тапом; с третьего появляется сброс — перещёлкивать их по одному '
      'дольше, чем нажать крестик.',
  body: (context) => const _MapFilters(),
);

class _MapFilters extends StatefulWidget {
  const _MapFilters();

  @override
  State<_MapFilters> createState() => _MapFiltersState();
}

class _MapFiltersState extends State<_MapFilters>
    with SingleTickerProviderStateMixin {
  String _status = 'Все';
  final _collections = <String>{'Звери'};

  /// Сброс держим на своём контроллере, а не на неявной анимации: пока он
  /// уезжает, виджет обязан оставаться в списке, иначе Wrap выкинет его
  /// мгновенно и чипы всё равно прыгнут.
  late final AnimationController _resetC = AnimationController(
    vsync: this,
    duration: Motion.popIn,
    reverseDuration: Motion.popOut,
  );

  /// Кривая живёт здесь, а не внутри DsPop: контроллер один и на монтаж,
  /// и на вид, иначе два таймера расходятся и появление рвётся.
  late final Animation<double> _resetT = CurvedAnimation(
    parent: _resetC,
    curve: Motion.easeOutBack,
    reverseCurve: Motion.easeOut,
  );

  bool get _showReset => _collections.length > 2;

  @override
  void dispose() {
    _resetC.dispose();
    super.dispose();
  }

  void _pick(String collection) {
    setState(() {
      if (!_collections.remove(collection)) _collections.add(collection);
    });
    if (_showReset) {
      _resetC.forward();
    } else {
      _resetC.reverse();
    }
  }

  static const _statuses = ['Все', 'Найдено', 'Не найдено'];
  static const _all = ['Звери', 'Птицы', 'Мифические', 'Без коллекции'];

  /// Заголовок группы. В макете (`474:5190`) это DS/Label/xs цветом
  /// text-muted — он называет, что настраивает группа, и не спорит по весу
  /// со строками выбора.
  Widget _heading(String text) => Padding(
        padding:
            const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s4, Space.s1),
        child: Text(text,
            style: T.labelXs.copyWith(color: InkMode.light.textMuted)),
      );

  /// Сброс коллекций. Появляется с третьего выбранного чипа: два снимаются
  /// повторным тапом быстрее, чем находится отдельная кнопка, а с трёх это
  /// уже перещёлкивание.
  ///
  /// Встаёт первым в ряду чипов: место у него постоянное, и его не надо
  /// искать глазами в конце — а конец ещё и переезжает при переносе строк.
  /// Появляется и исчезает вместе с условием, поэтому в покое ряд выглядит
  /// как раньше.
  Widget _reset() => DsPop.driven(
        animation: _resetT,
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _clear,
          child: Container(
            width: Space.s8,
            height: Space.s8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: S.borderDefault),
            ),
            child: DsIcon(DsIconName.x, color: InkMode.light.textMuted),
          ),
        ),
      );

  /// Сброс снимает выбор целиком, поэтому и уезжает он целиком — вместе
  /// с местом, которое занимал.
  void _clear() {
    setState(_collections.clear);
    _resetC.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return StageBox(
      stage: Stage.map,
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(vertical: Space.s2),
          decoration: BoxDecoration(
            color: S.surfaceDefault,
            borderRadius: BorderRadius.circular(Radii.base),
            boxShadow: Shadows.lg,
          ),
          child: Column(
            // Панель обжимает содержимое: в макете она 346 при потолке 420
            // со скроллом, а не во всю высоту слоя.
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heading('Показывать'),
              for (final status in _statuses)
                DsFilterRow(
                  label: status,
                  selected: _status == status,
                  onTap: () => setState(() => _status = status),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: Space.s4, vertical: Space.s2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: S.borderDefault)),
                  ),
                  child: SizedBox(width: double.infinity),
                ),
              ),
              _heading('Коллекции'),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Space.s4, Space.s1, Space.s4, Space.s2),
                // Перестраиваем сам список, а не одного ребёнка в нём.
                // `Wrap` ставит зазор между детьми независимо от их ширины,
                // поэтому «пустой» крестик — `SizedBox.shrink` на месте —
                // всё равно отодвигал первый чип от края на восемь пикселей.
                // Ушедший должен исчезнуть из списка, а не сжаться в нём.
                child: AnimatedBuilder(
                  animation: _resetC,
                  builder: (context, _) => Wrap(
                    spacing: Space.s2,
                    runSpacing: Space.s2,
                    // Круг сброса ниже чипа: 32 против 37. Ряд равняем по
                    // середине, иначе он повиснет на верхней кромке.
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // В списке, пока не доехал до нуля: выкинутый
                      // на полпути крестик увёл бы чипы скачком.
                      if (_resetC.value != 0) _reset(),
                      for (final collection in _all)
                        DsChip(
                          label: collection,
                          selected: _collections.contains(collection),
                          onTap: () => _pick(collection),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Слой поверх карты
// ---------------------------------------------------------------------------

final overlaySandbox = DocPage(
  title: 'Слой поверх карты',
  doc: 'Стеклянные кнопки, таб-бар и сообщение о сбое на одном слое. '
      'Стеклом делаются второстепенные кнопки: они рядом с главным действием, '
      'но не должны закрывать содержимое. Плашка — только про системный сбой: '
      'успехи подтверждаются формой, а не сообщением.',
  body: (context) => const _MapOverlay(),
);

class _MapOverlay extends StatefulWidget {
  const _MapOverlay();

  @override
  State<_MapOverlay> createState() => _MapOverlayState();
}

class _MapOverlayState extends State<_MapOverlay> {
  DsTab _tab = DsTab.map;
  bool _offline = true;

  @override
  Widget build(BuildContext context) {
    return StageBox(
      stage: Stage.map,
      child: SizedBox(
        height: 320,
        width: 420,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  DsIconButton(
                    icon: DsIconName.question,
                    type: DsIconButtonType.glass,
                    onPressed: () {},
                  ),
                  const SizedBox(width: Space.s2),
                  DsIconButton(
                    icon: DsIconName.camera,
                    type: DsIconButtonType.glass,
                    onPressed: () {},
                  ),
                  const Spacer(),
                  DsIconButton(
                    icon: DsIconName.slidersHorizontal,
                    type: DsIconButtonType.glass,
                    onPressed: () => setState(() => _offline = !_offline),
                  ),
                ],
              ),
            ),
            if (_offline)
              Positioned(
                left: 0,
                right: 0,
                // 64 — высота навбара, 16 — зазор. Плашка не прилипает
                // к кнопке: слипшись, они читаются как один блок, и палец
                // тянется закрыть сообщение, а попадает в таб.
                bottom: Space.s16 + Space.s4,
                child: DsToastError(
                  message: M.offlineMap,
                  // Повтор не выключает сеть обратно: сообщение о сбое
                  // уходит, когда сбой кончился, а не когда о нём напомнили.
                  onAction: () => setState(() {}),
                  // Состояние, а не событие: само не гаснет. Убрать
                  // с глаз можно свайпом вниз.
                  persistent: true,
                  onDismiss: () => setState(() => _offline = false),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Align(
                child: DsNavbar(
                  active: _tab,
                  onChanged: (tab) => setState(() => _tab = tab),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Форма
// ---------------------------------------------------------------------------

final formSandbox = DocPage(
  title: 'Форма',
  doc: 'Поля, статус и пара кнопок вместе. Нажмите «Сохранить» с пустым '
      'первым полем — увидите, как ошибка расходится по форме: обводка поля, '
      'плашка статуса, сообщение о сбое.',
  body: (context) => const _Form(),
);

class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _name = TextEditingController();
  bool _submitted = false;
  bool _saved = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _empty => _name.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final error = _submitted && _empty;

    return StageBox(
      stage: Stage.sunken,
      child: SizedBox(
        width: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Как назвать находку',
                style: T.headingLg.copyWith(color: InkMode.light.textDefault)),
            const SizedBox(height: Space.s3),
            DsInput(
              controller: _name,
              placeholder: 'Название',
              error: error,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.s2),
            const DsInput(placeholder: 'Заметка — необязательно'),
            const SizedBox(height: Space.s2),
            const DsInput(
                placeholder: 'Адрес подставляется сам',
                state: DsState.disabled),
            const SizedBox(height: Space.s3),
            Row(
              children: [
                if (error)
                  const DsBadge(label: 'Ошибка', variant: DsBadgeVariant.error)
                else if (_saved)
                  const DsBadge(
                      label: 'Сохранено', variant: DsBadgeVariant.success)
                else
                  const DsBadge(
                      label: 'Черновик', variant: DsBadgeVariant.info),
              ],
            ),
            if (error) ...[
              const SizedBox(height: Space.s3),
              DsToastError(
                message: M.saveFailed,
                // «Повторить» повторяет попытку, а не прячет сообщение.
                // Попытка в песочнице снова не удаётся — поле как было
                // пустым, так и осталось, — поэтому плашка на месте.
                // Раньше она пряталась, и демо разбирало само себя:
                // нажал кнопку — и показать больше нечего.
                onAction: () => setState(() {}),
                // Событие: гаснет само. С кнопкой — через 10 секунд,
                // столько нужно, чтобы заметить, прочитать и дотянуться.
                onDismiss: () => setState(() => _submitted = false),
              ),
            ],
            const SizedBox(height: Space.s4),
            Row(
              children: [
                DsButton(
                  label: 'Сохранить',
                  size: DsButtonSize.md,
                  onPressed: () => setState(() {
                    _submitted = true;
                    _saved = !_empty;
                  }),
                ),
                const SizedBox(width: Space.s2),
                DsButton(
                  label: 'Отмена',
                  type: DsButtonType.ghost,
                  size: DsButtonSize.md,
                  onPressed: () => setState(() {
                    _name.clear();
                    _submitted = false;
                    _saved = false;
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Альбом находок
// ---------------------------------------------------------------------------

final albumSandbox = DocPage(
  title: 'Альбом находок',
  doc: 'Экран «Находки» по макету `Screen/Collection` (`308:2101`). Числа '
      'сняты с узлов: колонка 163.5, зазор 16, поля 16. Главное здесь — как '
      'устроена карточка: белый блок начинается не сверху, а на y≈83, и '
      'фигурка торчит над ним. Оттиск ставится поверх карточки вразнобой по '
      'месту и размеру и вылезает за её край — он штампован на находке, а не '
      'вложен в неё. Отметки «НАЙДЕНО» в сетке нет: в альбоме лежит только '
      'собранное, и отмечать каждую карточку значило бы повторять очевидное.',
  body: (context) => const _Album(),
);

/// Что выпало оттиску: краска, форма, поворот и место на карточке.
class _Stamp {
  const _Stamp({
    required this.ink,
    required this.form,
    required this.turn,
    required this.x,
    required this.y,
  });

  final Color ink;
  final DsStampForm form;

  /// Радианы. В правилах системы угол задан в градусах, −12…+12.
  final double turn;

  final double x;
  final double y;
}

class _Album extends StatefulWidget {
  const _Album();

  @override
  State<_Album> createState() => _AlbumState();
}

class _AlbumState extends State<_Album> {
  bool _empty = false;
  DsTab _tab = DsTab.finds;

  // Снято с `308:2101`. Ширина экрана 375, поля 16, колонка 163.5,
  // зазор между колонками 16.
  static const _screen = 375.0;
  static const _pad = Space.s4;
  static const _col = 163.5;

  /// Доля карточки, которую занимает белый блок. В макете он задан
  /// процентом (`inset[36.4% 0 0 0]`), а не пикселями: карточка бывает
  /// разной высоты, а фигурка обязана торчать над блоком одинаково.
  static const _cardTop = 0.364;

  /// Находки: имя и дата. Высоту ячейка берёт из содержимого, а соседке
  /// по строке равняется сама — прибивать её к находке нельзя.
  static const _finds = [
    ('Белка с пистолетом', '12.06.26'),
    ('Птица на фонтане', '07.09.26'),
    ('Пегас', '03.05.26'),
    ('Такса', '21.07.26'),
    ('Сова возле Кристалла', '14.08.26'),
    ('Улитка', '26.07.26'),
  ];

  /// Оттиски считаются, а не выставляются руками.
  ///
  /// `ds/patterns.md`, «Что рандомизируется»: поворот −12°…+12°, чернило из
  /// четырёх, форма из трёх, место — ниже середины фигурки со смещением от
  /// центра. В Figma штампы расставлены руками — там это **примерка**,
  /// а поведение живёт здесь.
  ///
  /// **Сид от имени находки**, то есть от её id: выпавшее закрепляется
  /// навсегда. Живость должна быть один раз выпавшей, а дальше постоянной,
  /// иначе коллекция перестаёт ощущаться своей.
  late final List<_Stamp> _stamps = _stampsFor(_finds);

  static List<_Stamp> _stampsFor(List<(String, String)> finds) {
    const inks = [S.inkPrimary, S.inkSecondary, S.inkTertiary, S.inkNeutral];
    const forms = DsStampForm.values;
    final out = <_Stamp>[];
    for (final (name, _) in finds) {
      final rnd = math.Random(_seed(name));
      var ink = rnd.nextInt(inks.length);
      var form = rnd.nextInt(forms.length);
      // Сосед не повторяется ни формой, ни чернилом — берём следующие
      // по кругу, а не гоняем генератор до несовпадения.
      if (out.isNotEmpty) {
        if (inks[ink] == out.last.ink) ink = (ink + 1) % inks.length;
        if (forms[form] == out.last.form) form = (form + 1) % forms.length;
      }
      out.add(_Stamp(
        ink: inks[ink],
        form: forms[form],
        turn: (rnd.nextDouble() * 24 - 12) * math.pi / 180,
        // Полоса снята с шести ячеек макета: оттиск живёт ниже середины
        // и смещён от центра — морду фигурки не закрывает.
        x: 68 + rnd.nextDouble() * 28,
        y: 108 + rnd.nextDouble() * 24,
      ));
    }
    return out;
  }

  /// Стабильный хэш имени (FNV-1a). `String.hashCode` в Dart не обещает
  /// одного и того же значения между запусками, а сид обязан быть вечным.
  static int _seed(String value) {
    var h = 0x811c9dc5;
    for (final c in value.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7fffffff;
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    return StageBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Фон экрана — `surface-subtle` (`308:2101`), а не бумажный
          // «утопленный». Карточки на нём белые, и разницу видно только
          // на правильном сером: на бумаге они сливаются.
          ColoredBox(
            color: S.surfaceSubtle,
            child: SizedBox(
              width: _screen,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DsStatusBar(),
                      _header(),
                      if (_empty) _emptyState() else _grid(),
                      // Место под плавающий таб-бар: 64 его высоты плюс 32
                      // от низа. Последний ряд не должен прятаться под ним.
                      const SizedBox(height: Space.s16 + Space.s8),
                    ],
                  ),
                  // Таб-бар в макете абсолютный (`283:428`, y=716 при экране
                  // 812) — он плавает над сеткой, а не стоит под ней.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: Space.s8,
                    child: Align(
                      child: DsNavbar(
                        active: _tab,
                        onChanged: (t) => setState(() => _tab = t),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.s4),
          // Переключатель — приём песочницы, а не экрана: он живёт снаружи
          // серого поля, чтобы его не путали с продуктом.
          DsButton(
            label: _empty ? 'Показать находки' : 'Показать пустой',
            type: DsButtonType.ghost,
            size: DsButtonSize.sm,
            onPressed: () => setState(() => _empty = !_empty),
          ),
        ],
      ),
    );
  }

  /// `CollectionHeader` (`158:413`): имя экрана крупно и счётчик под ним.
  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(_pad, Space.s2, _pad, Space.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Находки',
                style: T.display4xl.copyWith(color: InkMode.light.textDefault)),
            // Зазор 4: в макете `CollectionHeader` имеет gap 4, а не 12.
            const SizedBox(height: Space.s1),
            Text(_empty ? 'ни одного' : '${_finds.length} городовых',
                style: T.bodySm.copyWith(color: InkMode.light.textMuted)),
          ],
        ),
      );

  /// Сетка: две колонки, ряды равняются по высокой карточке.
  ///
  /// Не `Wrap`: он ставит соседей по их собственной высоте, и карточка
  /// с коротким именем оказывается ниже соседки. Ряд — `Row` с растяжкой
  /// внутри `IntrinsicHeight`: высоту задаёт та, у которой имя в две строки,
  /// вторая её добирает. Белый блок при этом дотягивается до низа ряда,
  /// а не обрывается посередине.
  Widget _grid() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: _pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var row = 0; row * 2 < _finds.length; row++)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var col = 0; col < 2; col++)
                      if (row * 2 + col < _finds.length) ...[
                        if (col > 0) const SizedBox(width: Space.s4),
                        SizedBox(
                          width: _col,
                          child: _cell(
                              _finds[row * 2 + col], _stamps[row * 2 + col]),
                        ),
                      ],
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _cell((String, String) find, _Stamp stamp) {
    final (name, date) = find;
    // Нажатие карточка отыгрывает просадкой, а не цветом: `DsTilt`.
    // Цвет в альбоме занят чернилами оттисков, и подсветка карточки
    // спорила бы с ними. Проседает вся карточка, глубже — под пальцем.
    //
    // Наклоняется вся ячейка вместе с оттиском: он **на** находке,
    // а не рядом, и отставать при наклоне не должен.
    return DsTilt(
      // Оттиск вылезает за карточку — обрезать нельзя, иначе он перестаёт
      // читаться как оттиск и становится картинкой внутри рамки.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Белый блок занимает нижние 63.6 % карточки: фигурка стоит выше
          // и торчит над ним. Долей, а не пикселями, — тогда блок дотягивается
          // до низа ряда, какой бы высоты тот ни вышел.
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: 1 - _cardTop,
              // Тень слушает нажатие: карточка вдавливается — тень
              // поджимается и уезжает под поднятый край. Без этого наклон
              // читается как «висит в воздухе», сколько его ни настраивай.
              child: DsPressShadow(
                shadow: Shadows.md,
                builder: (context, shadow) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: S.surfaceDefault,
                    borderRadius: BorderRadius.circular(Radii.card),
                    boxShadow: shadow,
                  ),
                ),
              ),
            ),
          ),
          // Фигурка и имя идут потоком: 4 сверху, фигурка 163.5, 4 до имени,
          // 16 снизу — числа из `founded_object`. Свободное место, если ряд
          // выше содержимого, остаётся под именем, внутри белого блока.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Space.s1),
              // Слот: фигурка приходит из снапшота, в ДС её нет.
              Container(
                width: _col,
                height: _col,
                decoration: BoxDecoration(
                  color: S.surfaceTileSage,
                  borderRadius: BorderRadius.circular(Radii.full),
                ),
                alignment: Alignment.center,
                child: Mono('городовой'),
              ),
              const SizedBox(height: Space.s1),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(Space.s3, 0, Space.s3, Space.s4),
                child: Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        T.labelSm.copyWith(color: InkMode.light.textDefault)),
              ),
            ],
          ),
          // Поворот −12°…+12° — из правил системы, а не из макета.
          Positioned(
            left: stamp.x,
            top: stamp.y,
            child: Transform.rotate(
              angle: stamp.turn,
              child: DsInkStamp(date: date, form: stamp.form, ink: stamp.ink),
            ),
          ),
        ],
      ),
    );
  }

  /// `EmptyState` (`323:6042`): спящая фигурка, заголовок, объяснение и одна
  /// кнопка. Серой плашки на месте будущей сетки нет — «рыбы в макете нет».
  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s5),
        child: Column(
          children: [
            Container(
              width: 296,
              height: 296,
              decoration: BoxDecoration(
                color: S.surfaceTileSky,
                borderRadius: BorderRadius.circular(Radii.full),
              ),
              alignment: Alignment.center,
              child: Mono('городовой/спящий'),
            ),
            const SizedBox(height: Space.s4),
            Text('Пока пусто',
                style: T.heading2xl.copyWith(color: InkMode.light.textDefault)),
            const SizedBox(height: Space.s4),
            Text(
              'Городовые ждут на улицах. Когда ты их найдёшь — соберутся '
              'здесь. Пойдём посмотрим?',
              textAlign: TextAlign.center,
              style: T.bodyBase.copyWith(color: InkMode.light.textMuted),
            ),
            const SizedBox(height: Space.s4),
            DsButton(
                label: 'На карту', size: DsButtonSize.sm, onPressed: () {}),
          ],
        ),
      );
}

final sandboxPages = <DocPage>[
  sheetSandbox,
  filtersSandbox,
  overlaySandbox,
  albumSandbox,
  formSandbox,
];
