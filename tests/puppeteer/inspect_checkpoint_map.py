"""Read-only installed vanilla map check; not an in-game navigation test."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parents[2] / '.claude/tools'))
import lotheader_parser as lp

index = lp.MapIndex(lp.VANILLA_MAP)
squares = index.squares_world(12598, 961, 12608, 1170)
props = lp.tile_props()
points = [(12607, y, 0) for y in range(965, 1171)]
points += [(x, 965, 0) for x in range(12599, 12608)]
rows = [{'position': p, 'tiles': [{'name': t, 'properties': props.get(t, {})}
         for t in squares.get(p, [])]} for p in points]
(ROOT / 'reports/inspection').mkdir(parents=True, exist_ok=True)
(ROOT / 'reports/inspection/checkpoint-map-route.json').write_text(
    json.dumps({'validation': 'static installed map only; dynamic vehicles not inspected',
                'map': lp.VANILLA_MAP, 'squares': rows}, indent=2), encoding='utf-8')
for row in rows:
    obstacles = [t for t in row['tiles'] if any(k in t['properties']
                 for k in ('solid', 'solidtrans', 'CollideN', 'CollideW', 'CantClimb'))]
    if not row['tiles'] or obstacles:
        print(row['position'], obstacles or 'EMPTY')
print('Static route checked:', len(rows), 'squares. Vehicles and reachability require the game.')
for (x, y, z), tiles in sorted(squares.items()):
    if z == 0 and 1000 <= y <= 1004:
        obstacles = [t for t in tiles if any(k in props.get(t, {})
                     for k in ('solid', 'solidtrans', 'CollideN', 'CollideW', 'CantClimb'))]
        if obstacles:
            print('Roadblock vicinity', (x, y, z), obstacles)
