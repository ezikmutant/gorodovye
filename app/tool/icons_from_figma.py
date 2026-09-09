#!/usr/bin/env python3
"""Переносит контуры глифов из Figma в `lib/ds/components/icon_paths.dart`.

Источник — набор `Icon` (узел `68:14`) в файле eK3JWxVILnuTJc2B8Zqx8Z. Экспорт
каждого варианта в SVG делается через Figma MCP (`download_assets`, формат svg);
внутри экспорта иконка лежит в группе `id="Name=<имя>"`, остальное — фон
страницы, и сюда не попадает.

Скрипт приводит circle / ellipse / rect / line к обычным контурам, а команды
H и V — к L, чтобы разборщику в Dart хватило четырёх команд: M, L, C, Z.

Запуск:  python3 tool/icons_from_figma.py <папка с svg>
"""

import re
import sys
import glob
import os
import xml.etree.ElementTree as ET

NS = '{http://www.w3.org/2000/svg}'
K = 0.5522847498307936  # доля радиуса для приближения дуги кубической кривой

# Имена вариантов в Figma → имена в enum DsIconName.
DART_NAME = {
    'check': 'check', 'warning': 'warning', 'info': 'info',
    'question': 'question', 'camera': 'camera', 'eye': 'eye', 'x': 'x',
    'share-2': 'share2', 'sliders-horizontal': 'slidersHorizontal',
    'chevron-right': 'chevronRight', 'chevron-up': 'chevronUp',
    'map-pin': 'mapPin', 'image': 'image', 'arrow-left': 'arrowLeft',
    'expand': 'expand', 'sign': 'sign', 'calendar': 'calendar',
    'arrow-up-down': 'arrowUpDown', 'download': 'download',
}

# Порядок в enum DsIconName — генерируем в нём же, чтобы файлы читались рядом.
ORDER = ['check', 'warning', 'info', 'question', 'camera', 'eye', 'x',
         'share-2', 'sliders-horizontal', 'chevron-right', 'map-pin', 'image',
         'arrow-left', 'sign', 'chevron-up', 'expand', 'calendar',
         'arrow-up-down', 'download']


def num(v, default=0.0):
    return float(v) if v is not None else default


def fmt(x):
    """Короткая запись числа: 3.2 вместо 3.19995."""
    return f'{round(x, 3):g}'


def arc_path(cx, cy, rx, ry):
    """Овал четырьмя кубическими кривыми."""
    ox, oy = rx * K, ry * K
    return (f'M{fmt(cx - rx)} {fmt(cy)}'
            f'C{fmt(cx - rx)} {fmt(cy - oy)} {fmt(cx - ox)} {fmt(cy - ry)} {fmt(cx)} {fmt(cy - ry)}'
            f'C{fmt(cx + ox)} {fmt(cy - ry)} {fmt(cx + rx)} {fmt(cy - oy)} {fmt(cx + rx)} {fmt(cy)}'
            f'C{fmt(cx + rx)} {fmt(cy + oy)} {fmt(cx + ox)} {fmt(cy + ry)} {fmt(cx)} {fmt(cy + ry)}'
            f'C{fmt(cx - ox)} {fmt(cy + ry)} {fmt(cx - rx)} {fmt(cy + oy)} {fmt(cx - rx)} {fmt(cy)}Z')


def rect_path(x, y, w, h, rx, ry):
    if rx <= 0 and ry <= 0:
        return (f'M{fmt(x)} {fmt(y)}L{fmt(x + w)} {fmt(y)}'
                f'L{fmt(x + w)} {fmt(y + h)}L{fmt(x)} {fmt(y + h)}Z')
    rx = min(rx or ry, w / 2)
    ry = min(ry or rx, h / 2)
    ox, oy = rx * K, ry * K
    return (f'M{fmt(x + rx)} {fmt(y)}L{fmt(x + w - rx)} {fmt(y)}'
            f'C{fmt(x + w - rx + ox)} {fmt(y)} {fmt(x + w)} {fmt(y + ry - oy)} {fmt(x + w)} {fmt(y + ry)}'
            f'L{fmt(x + w)} {fmt(y + h - ry)}'
            f'C{fmt(x + w)} {fmt(y + h - ry + oy)} {fmt(x + w - rx + ox)} {fmt(y + h)} {fmt(x + w - rx)} {fmt(y + h)}'
            f'L{fmt(x + rx)} {fmt(y + h)}'
            f'C{fmt(x + rx - ox)} {fmt(y + h)} {fmt(x)} {fmt(y + h - ry + oy)} {fmt(x)} {fmt(y + h - ry)}'
            f'L{fmt(x)} {fmt(y + ry)}'
            f'C{fmt(x)} {fmt(y + ry - oy)} {fmt(x + rx - ox)} {fmt(y)} {fmt(x + rx)} {fmt(y)}Z')


TOKEN = re.compile(r'([MLHVCZmlhvcz])|(-?\d*\.?\d+(?:e-?\d+)?)')


def normalize(d):
    """M/L/H/V/C/Z (только абсолютные — Figma других не пишет) → M/L/C/Z."""
    toks = [(a or b) for a, b in TOKEN.findall(d)]
    out, i, cmd = [], 0, None
    x = y = 0.0
    while i < len(toks):
        t = toks[i]
        if re.match(r'[A-Za-z]', t):
            cmd, i = t, i + 1
            if cmd in 'Zz':
                out.append('Z')
            continue
        if cmd is None:
            raise ValueError(f'контур без команды: {d}')
        n = lambda k: float(toks[i + k])
        if cmd == 'M':
            x, y = n(0), n(1); out.append(f'M{fmt(x)} {fmt(y)}'); i += 2; cmd = 'L'
        elif cmd == 'L':
            x, y = n(0), n(1); out.append(f'L{fmt(x)} {fmt(y)}'); i += 2
        elif cmd == 'H':
            x = n(0); out.append(f'L{fmt(x)} {fmt(y)}'); i += 1
        elif cmd == 'V':
            y = n(0); out.append(f'L{fmt(x)} {fmt(y)}'); i += 1
        elif cmd == 'C':
            out.append(f'C{fmt(n(0))} {fmt(n(1))} {fmt(n(2))} {fmt(n(3))} {fmt(n(4))} {fmt(n(5))}')
            x, y = n(4), n(5); i += 6
        else:
            raise ValueError(f'команда {cmd} не поддержана: {d}')
    return ''.join(out)


# Собственный цвет глифа. В наборе он один на глиф, но не у всех совпадает
# с text-default: три значка статуса носят свой. Неизвестный цвет — ошибка:
# молча покрасить его чернилами значит потерять смысл.
TINT = {
    '#1C1B19': None,          # text-default — красится чернильным режимом
    '#7E9E6B': 'S.bgSuccess',  # success-500
    '#EBC94C': 'S.bgWarning',  # warning-500
    '#8E90D8': 'S.bgInfo',     # info-500
    '#FFFFFF': None,           # белый приходит от режима «На тёмном»
}


def color_of(el):
    c = el.get('fill')
    if c in (None, 'none'):
        c = el.get('stroke')
    return (c or '').upper()


def glyph(el):
    """Элемент SVG → (контур, залит ли)."""
    tag = el.tag.replace(NS, '')
    filled = el.get('fill') not in (None, 'none')
    if tag == 'path':
        return normalize(el.get('d')), filled
    if tag == 'circle':
        r = num(el.get('r'))
        return arc_path(num(el.get('cx')), num(el.get('cy')), r, r), filled
    if tag == 'ellipse':
        return arc_path(num(el.get('cx')), num(el.get('cy')),
                        num(el.get('rx')), num(el.get('ry'))), filled
    if tag == 'rect':
        return rect_path(num(el.get('x')), num(el.get('y')),
                         num(el.get('width')), num(el.get('height')),
                         num(el.get('rx')), num(el.get('ry'))), filled
    if tag == 'line':
        return (f"M{fmt(num(el.get('x1')))} {fmt(num(el.get('y1')))}"
                f"L{fmt(num(el.get('x2')))} {fmt(num(el.get('y2')))}"), False
    raise ValueError(f'неизвестный элемент {tag}')


def main(src):
    found = {}
    for f in glob.glob(os.path.join(src, '*.svg')):
        root = ET.parse(f).getroot()
        groups = [e for e in root.iter() if e.get('id', '').startswith('Name=')]
        if len(groups) != 1:
            raise SystemExit(f'{f}: ожидалась одна группа Name=, найдено {len(groups)}')
        name = groups[0].get('id')[len('Name='):]
        parts = list(groups[0].iter())[1:]
        colors = {color_of(e) for e in parts}
        if len(colors) != 1:
            raise SystemExit(f'{name}: глиф двухцветный ({sorted(colors)}) — '
                             'модель «глиф красится целиком» этого не описывает')
        (color,) = colors
        if color not in TINT:
            raise SystemExit(f'{name}: неизвестный цвет {color}, '
                             'добавьте его в TINT со смысловым токеном')
        found[name] = ([glyph(e) for e in parts], TINT[color])

    missing = [n for n in ORDER if n not in found]
    extra = [n for n in found if n not in ORDER]
    if missing or extra:
        raise SystemExit(f'не сошлось: нет {missing}, лишние {extra}')

    lines = [
        '// СГЕНЕРИРОВАНО. Не править руками — правки затрёт следующая пересборка.',
        '//',
        '// Контуры глифов сняты с набора `Icon` в Figma (`68:14`) и приведены к',
        '// четырём командам: M, L, C, Z. Система координат — 16×16, та же, что у',
        '// варианта в макете; обводка 1.5 в этих же единицах, поэтому при другом',
        '// размере глиф масштабируется целиком, вместе с толщиной линии.',
        '//',
        '// Пересобрать: `python3 tool/icons_from_figma.py <папка с svg из Figma>`.',
        '',
        "import 'package:flutter/painting.dart';",
        '',
        "import '../tokens/semantics.dart';",
        "import 'icon_names.dart';",
        '',
        '/// Сторона системы координат, в которой заданы контуры.',
        'const double kGlyphBox = 16;',
        '',
        '/// Толщина обводки в тех же единицах.',
        'const double kGlyphStroke = 1.5;',
        '',
        '/// Один кусок глифа. Заливка и обводка красятся одним цветом:',
        '/// глиф — единое целое (`ds/CONTRACT.md`, пункт 9).',
        'class GlyphPart {',
        '  const GlyphPart(this.d, {this.filled = false});',
        '',
        '  final String d;',
        '  final bool filled;',
        '}',
        '',
        'const glyphs = <DsIconName, List<GlyphPart>>{',
    ]
    for name in ORDER:
        parts, _ = found[name]
        lines.append(f'  // {name} — {len(parts)} '
                     f'{"кусок" if len(parts) == 1 else "куска" if len(parts) < 5 else "кусков"}')
        lines.append(f'  DsIconName.{DART_NAME[name]}: [')
        for d, filled in parts:
            lines.append(f"    GlyphPart('{d}'{', filled: true' if filled else ''}),")
        lines.append('  ],')
    lines += ['};', '']

    tinted = [(n, t) for n, (_, t) in found.items() if t]
    lines += [
        '/// Глифы, у которых в наборе свой цвет. Остальные шестнадцать берут',
        '/// его из чернильного режима — это те, что стоят в кнопках и строках,',
        '/// где цвет задаёт фон. Значки статуса живут сами по себе: жёлтый',
        '/// `warning` на красной плашке остаётся жёлтым.',
        '///',
        '/// Явно переданный в [DsIcon] цвет перебивает и то и другое.',
        'const glyphTint = <DsIconName, Color>{',
    ]
    for name in ORDER:
        tint = found[name][1]
        if tint:
            lines.append(f'  DsIconName.{DART_NAME[name]}: {tint},')
    lines += ['};', '']
    out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       'lib', 'ds', 'components', 'icon_paths.dart')
    open(out, 'w').write('\n'.join(lines))
    print(f'{out}: {len(ORDER)} глифов, '
          f'{sum(len(v[0]) for v in found.values())} кусков, '
          f'{len(tinted)} со своим цветом: '
          f'{", ".join(n for n, _ in tinted)}')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else '.')
