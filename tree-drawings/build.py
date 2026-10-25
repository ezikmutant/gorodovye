"""Собирает из points.csv данные для карты и файл для Organic Maps.

    python3 tree-drawings/build.py

points.csv — единственный источник: новые точки и правки вносятся туда,
потом скрипт запускается заново. Он пишет рядом:

- points.geojson — его читает index.html;
- tree-drawings-moscow.kml — список меток для Organic Maps (и Google My Maps,
  и «Моих карт» Яндекса: KML они тоже понимают).

Цвета меток в KML — имена стилей Organic Maps (`placemark-green` и т. п.):
по ним приложение красит метку, а другие программы берут цвет из IconStyle.
"""
import csv
import json
from pathlib import Path
from xml.sax.saxutils import escape

HERE = Path(__file__).resolve().parent

KINDS = {
    # вид: (подпись, стиль Organic Maps, цвет KML aabbggrr)
    'found': ('Найден на месте', 'placemark-red', 'ff2a2ac9'),
    'official': ('Официальная карта ПаркАрт', 'placemark-green', 'ff38783b'),
    'fili': ('Карта Филей', 'placemark-purple', 'ffb34c7a'),
    'osm': ('Рисунок по OSM', 'placemark-blue', 'ffae6a2c'),
    'check': ('Метка OSM — проверить', 'placemark-orange', 'ff0e66a2'),
}


def load():
    rows = list(csv.DictReader(open(HERE / 'points.csv', encoding='utf-8')))
    for r in rows:
        r['lat'], r['lon'] = float(r['lat']), float(r['lon'])
        r['shown_kind'] = 'found' if r['found'] else r['kind']
    return rows


def name(r):
    return r['title'] if r['untitled'] else f'«{r["title"]}»'


def geojson(rows):
    keep = ['id', 'kind', 'found', 'title', 'untitled', 'author', 'year', 'place', 'place_basis', 'note', 'osm',
            'official_lat', 'official_lon', 'source']
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
           '<description>Официальная карта ПаркАрт, рисунки в Филях и метки OpenStreetMap. '
           'Зелёные — Мосприрода, фиолетовые — Фили, синие — рисунки по OSM, '
           'оранжевые — метки OSM, которые надо проверить, красные — найдены на месте.</description>']
    for _, style, color in KINDS.values():
        out.append(f'<Style id="{style}"><IconStyle><color>{color}</color><Icon>'
                   f'<href>https://omaps.app/placemarks/{style}.png</href></Icon></IconStyle></Style>')
    for r in rows:
        label, style, _ = KINDS[r['shown_kind']]
        lines = [', '.join(x for x in (r['author'], r['year']) if x), r['place'], r['note'], label]
        if r['osm']:
            lines.append(f'OSM: https://www.openstreetmap.org/node/{r["osm"]}')
        desc = '\n'.join(x for x in lines if x)
        out.append(f'<Placemark><name>{escape(name(r))}</name>'
                   f'<description>{escape(desc)}</description>'
                   f'<styleUrl>#{style}</styleUrl>'
                   f'<Point><coordinates>{r["lon"]},{r["lat"]}</coordinates></Point></Placemark>')
    out += ['</Document>', '</kml>']
    return '\n'.join(out) + '\n'


def main():
    rows = load()
    (HERE / 'points.geojson').write_text(json.dumps(geojson(rows), ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    (HERE / 'tree-drawings-moscow.kml').write_text(kml(rows), encoding='utf-8')
    counts = {}
    for r in rows:
        counts[r['shown_kind']] = counts.get(r['shown_kind'], 0) + 1
    print(f'точек: {len(rows)} —', ', '.join(f'{KINDS[k][0].lower()}: {n}' for k, n in counts.items()))


if __name__ == '__main__':
    main()
