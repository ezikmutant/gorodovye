"""Собирает из points.csv и territories.geojson данные для карты и файлы для импорта.

    python3 tree-drawings/build.py

points.csv — единственный источник точек: новые точки и правки вносятся туда,
потом скрипт запускается заново. Точки со status=excluded остаются в таблице
(с причиной в status_note), но ни в один файл ниже не попадают.

territories.geojson — контуры территорий, где проходил ПаркАрт (из OSM).

Скрипт пишет рядом:

- points.geojson — его читает index.html;
- tree-drawings-moscow.kml — список меток для Organic Maps (Google My Maps его тоже понимает);
- yandex-map.geojson — точки и территории для импорта в Конструктор Яндекс Карт.

Цвета меток в KML — имена стилей Organic Maps (`placemark-green` и т. п.):
по ним приложение красит метку, а другие программы берут цвет из IconStyle.
Цвета для Яндекса — из палитры конструктора: другие он не показывает.
"""
import csv
import json
from pathlib import Path
from xml.sax.saxutils import escape

HERE = Path(__file__).resolve().parent

KINDS = {
    # вид: (подпись, стиль Organic Maps, цвет KML aabbggrr, цвет конструктора Яндекса)
    'found': ('Найден на месте', 'placemark-red', 'ff4545ed', '#ed4543'),
    'confirmed': ('Виден на фото в Яндекс Картах', 'placemark-green', 'ff40db56', '#56db40'),
    'official': ('Официальная карта ПаркАрт, не проверено', 'placemark-gray', 'ffb3b3b3', '#b3b3b3'),
    'fili': ('Карта Филей', 'placemark-purple', 'ffff1eb5', '#b51eff'),
    'osm': ('Рисунок по OSM', 'placemark-blue', 'ffff981e', '#1e98ff'),
    'check': ('Метка без подтверждения — проверить', 'placemark-orange', 'ff1e93ff', '#ff931e'),
    'missing': ('Не найден на месте', 'placemark-bluegray', 'ff595959', '#595959'),
}
TERRITORY_STYLE = {'fill': '#56db40', 'fill-opacity': 0.15, 'stroke': '#1bad03', 'stroke-width': '2',
                   'stroke-opacity': 0.8}


def shown_kind(r):
    if r['missing']:
        return 'missing'
    if r['found']:
        return 'found'
    if r['confirmed'] == 'yandex-photo':
        return 'confirmed'
    if r['kind'] == 'yandex':
        return 'check'
    return r['kind']


def load():
    rows = [r for r in csv.DictReader(open(HERE / 'points.csv', encoding='utf-8')) if r['status'] != 'excluded']
    for r in rows:
        r['lat'], r['lon'] = float(r['lat']), float(r['lon'])
        r['shown_kind'] = shown_kind(r)
    return rows


def name(r):
    return r['title'] if r['untitled'] else f'«{r["title"]}»'


def describe(r):
    lines = [', '.join(x for x in (r['author'], r['year']) if x), r['place'], r['note'], r['field_note'], r['status_note'],
             KINDS[r['shown_kind']][0], f'Источник: {r["source"]}']
    if r['yandex']:
        lines.append(f'Яндекс Карты: https://yandex.ru/maps/org/{r["yandex"]}/')
    if r['osm']:
        lines.append(f'OSM: https://www.openstreetmap.org/node/{r["osm"]}')
    return '\n'.join(x for x in lines if x)


def geojson(rows):
    keep = ['id', 'kind', 'found', 'missing', 'confirmed', 'title', 'untitled', 'author', 'year', 'place', 'place_basis',
            'note', 'field_note', 'status_note', 'yandex', 'osm', 'official_lat', 'official_lon', 'source']
    return {'type': 'FeatureCollection', 'features': [
        {'type': 'Feature', 'id': r['id'],
         'geometry': {'type': 'Point', 'coordinates': [r['lon'], r['lat']]},
         'properties': {k: r[k] for k in keep if r[k] != ''} | {'shown_kind': r['shown_kind']}}
        for r in rows]}


def kml(rows):
    out = ['<?xml version="1.0" encoding="UTF-8"?>',
           '<kml xmlns="http://www.opengis.net/kml/2.2">',
           '<Document>',
           '<name>Рисунки на деревьях Москвы</name>',
           '<description>Красные — найдены на месте, зелёные — видны на фото в Яндекс Картах, '
           'серые — официальная карта ПаркАрт (не проверены, часть координат сбита), фиолетовые — Фили, '
           'синие — рисунки по OSM, оранжевые — метки, которые надо проверить, '
           'тёмно-серые — не нашлись на месте.</description>']
    for _, style, color, _ in KINDS.values():
        out.append(f'<Style id="{style}"><IconStyle><color>{color}</color><Icon>'
                   f'<href>https://omaps.app/placemarks/{style}.png</href></Icon></IconStyle></Style>')
    for r in rows:
        style = KINDS[r['shown_kind']][1]
        out.append(f'<Placemark><name>{escape(name(r))}</name>'
                   f'<description>{escape(describe(r))}</description>'
                   f'<styleUrl>#{style}</styleUrl>'
                   f'<Point><coordinates>{r["lon"]},{r["lat"]}</coordinates></Point></Placemark>')
    out += ['</Document>', '</kml>']
    return '\n'.join(out) + '\n'


def inside(lon, lat, ring):
    hit, j = False, len(ring) - 1
    for i in range(len(ring)):
        (xi, yi), (xj, yj) = ring[i], ring[j]
        if (yi > lat) != (yj > lat) and lon < (xj - xi) * (lat - yi) / (yj - yi) + xi:
            hit = not hit
        j = i
    return hit


def yandex(rows, terr):
    feats = []
    counts = {}
    for f in terr['features']:
        p = f['properties']
        n = sum(1 for r in rows if inside(r['lon'], r['lat'], f['geometry']['coordinates'][0]))
        counts[p['name']] = counts.get(p['name'], 0) + n
    for f in terr['features']:
        p = f['properties']
        n = counts[p['name']]
        text = [f'Территория акции «ПаркАрт», {p["years"]}.',
                f'Точек рисунков на карте: {n}.' if n else 'Точек рисунков нет: известно только, что здесь рисовали.',
                p['note'], 'Границы примерные.' if p['approx'] else 'Границы — из OpenStreetMap.']
        feats.append({'type': 'Feature', 'geometry': f['geometry'],
                      'properties': {'description': f'{p["name"]}\n' + '\n'.join(x for x in text if x),
                                     **TERRITORY_STYLE}})
    for t in terr.get('points', []):
        feats.append({'type': 'Feature', 'geometry': {'type': 'Point', 'coordinates': t['coordinates']},
                      'properties': {'iconCaption': t['name'], 'marker-color': '#1bad03',
                                     'description': f'{t["name"]}\nТерритория акции «ПаркАрт», {t["years"]}. {t["note"]}'}})
    for r in rows:
        feats.append({'type': 'Feature', 'geometry': {'type': 'Point', 'coordinates': [r['lon'], r['lat']]},
                      'properties': {'iconCaption': name(r), 'description': describe(r),
                                     'marker-color': KINDS[r['shown_kind']][3]}})
    for i, f in enumerate(feats):
        f['id'] = i
    return {'type': 'FeatureCollection',
            'metadata': {'name': 'Рисунки на деревьях Москвы', 'creator': 'tree-drawings/build.py'},
            'features': feats}


def main():
    rows = load()
    terr = json.load(open(HERE / 'territories.geojson', encoding='utf-8'))
    dump = lambda obj, fn: (HERE / fn).write_text(json.dumps(obj, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    dump(geojson(rows), 'points.geojson')
    dump(yandex(rows, terr), 'yandex-map.geojson')
    (HERE / 'tree-drawings-moscow.kml').write_text(kml(rows), encoding='utf-8')
    counts = {}
    for r in rows:
        counts[r['shown_kind']] = counts.get(r['shown_kind'], 0) + 1
    print(f'точек на карте: {len(rows)} —', ', '.join(f'{KINDS[k][0].lower()}: {n}' for k, n in counts.items()))
    print(f'территорий: {len({f["properties"]["name"] for f in terr["features"]}) + len(terr.get("points", []))}')


if __name__ == '__main__':
    main()
