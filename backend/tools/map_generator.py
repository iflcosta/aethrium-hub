"""
Procedural map generator for Beatriz (Mapper agent).

Algorithm: BSP (Binary Space Partitioning) dungeon generation.
Supports dungeon, cave, city and grassland types.
Output: ASCII art layout + full JSON spec (rooms, corridors, AIDs, spawns, teleports).
The spec is designed to be imported manually into RME (Remere's Map Editor).
"""

import random
import math
from typing import List, Tuple, Dict, Any, Optional


# ─── Tile symbols ─────────────────────────────────────────────────────────────

WALL      = "#"
FLOOR     = "."
CORRIDOR  = ","
ENTRANCE  = "E"
BOSS      = "B"
TREASURE  = "T"
SHRINE    = "S"   # optional special room

# ─── Monster tables ───────────────────────────────────────────────────────────

MONSTERS: Dict[str, List[str]] = {
    "dungeon":    ["Skeleton", "Zombie", "Ghoul", "Lich", "Demon"],
    "cave":       ["Cave Rat", "Stone Golem", "Cyclops", "Minotaur", "Dragon"],
    "city":       [],  # cities don't have monster spawns by default
    "grassland":  ["Wolf", "Bear", "Wild Boar", "Deer", "Orc"],
    "underwater": ["Sea Serpent", "Shark", "Crab", "Pirate Ghost", "Leviathan"],
}

# ─── Room ─────────────────────────────────────────────────────────────────────

class Room:
    def __init__(self, x: int, y: int, w: int, h: int, room_type: str = "normal"):
        self.x = x        # top-left column
        self.y = y        # top-left row
        self.w = w        # width (columns)
        self.h = h        # height (rows)
        self.room_type = room_type

    def overlaps(self, other: "Room", padding: int = 2) -> bool:
        return (
            self.x - padding < other.x + other.w
            and self.x + self.w + padding > other.x
            and self.y - padding < other.y + other.h
            and self.y + self.h + padding > other.y
        )

    @property
    def center(self) -> Tuple[int, int]:
        return (self.x + self.w // 2, self.y + self.h // 2)

    @property
    def area(self) -> int:
        return self.w * self.h

    def to_dict(self, z: int = 7) -> Dict:
        cx, cy = self.center
        return {
            "x": self.x,
            "y": self.y,
            "z": z,
            "width": self.w,
            "height": self.h,
            "center": {"x": cx, "y": cy, "z": z},
            "type": self.room_type,
            "area_sqm": self.area,
        }


# ─── BSP helper ──────────────────────────────────────────────────────────────

def _bsp_partition(
    x: int, y: int, w: int, h: int,
    depth: int, max_depth: int, min_leaf: int,
    rng: random.Random,
) -> List[Tuple[int, int, int, int]]:
    """
    Recursively partition space. Returns list of leaf rectangles (x, y, w, h).
    """
    if depth >= max_depth or w < min_leaf * 2 or h < min_leaf * 2:
        return [(x, y, w, h)]

    leaves = []
    if w > h:
        split = rng.randint(min_leaf, w - min_leaf)
        leaves += _bsp_partition(x, y, split, h, depth + 1, max_depth, min_leaf, rng)
        leaves += _bsp_partition(x + split, y, w - split, h, depth + 1, max_depth, min_leaf, rng)
    else:
        split = rng.randint(min_leaf, h - min_leaf)
        leaves += _bsp_partition(x, y, w, split, depth + 1, max_depth, min_leaf, rng)
        leaves += _bsp_partition(x, y + split, w, h - split, depth + 1, max_depth, min_leaf, rng)

    return leaves


# ─── Main generator ──────────────────────────────────────────────────────────

def generate_map(
    width: int = 60,
    height: int = 40,
    dungeon_type: str = "dungeon",
    floor_z: int = 7,
    seed: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Generate a procedural map.

    Parameters
    ----------
    width, height : dimensions of the map grid
    dungeon_type  : "dungeon" | "cave" | "city" | "grassland" | "underwater"
    floor_z       : OTServ Z coordinate for the generated floor
    seed          : optional random seed for reproducibility

    Returns
    -------
    Dict with keys: ascii, rooms, corridors, aids, spawns, teleports,
    dimensions, legend, rme_notes
    """
    rng = random.Random(seed)

    # ── 1. Partition space ──────────────────────────────────────────────────
    max_depth = 4
    min_leaf  = 10
    leaves = _bsp_partition(0, 0, width, height, 0, max_depth, min_leaf, rng)

    # ── 2. Carve one room per leaf ──────────────────────────────────────────
    grid = [[WALL] * width for _ in range(height)]
    rooms: List[Room] = []

    for (lx, ly, lw, lh) in leaves:
        margin = 2
        max_rw = max(4, lw - margin * 2)
        max_rh = max(4, lh - margin * 2)
        rw = rng.randint(4, max_rw)
        rh = rng.randint(4, max_rh)
        rx = lx + rng.randint(margin, max(margin, lw - rw - margin))
        ry = ly + rng.randint(margin, max(margin, lh - rh - margin))
        room = Room(rx, ry, rw, rh)
        rooms.append(room)
        for row in range(ry, ry + rh):
            for col in range(rx, rx + rw):
                if 0 <= col < width and 0 <= row < height:
                    grid[row][col] = FLOOR

    # ── 3. Assign room types ────────────────────────────────────────────────
    # Sort by area to assign entrance (smallest) and boss (largest)
    rooms_sorted = sorted(rooms, key=lambda r: r.area)
    rooms_sorted[0].room_type  = "entrance"
    rooms_sorted[-1].room_type = "boss"
    if len(rooms_sorted) >= 4:
        rooms_sorted[len(rooms_sorted) // 2].room_type = "treasure"
    if len(rooms_sorted) >= 6:
        rooms_sorted[len(rooms_sorted) // 3].room_type = "shrine"

    # ── 4. Connect rooms with L-shaped corridors ────────────────────────────
    corridors = []
    # Connect each room to the nearest unconnected neighbour (greedy MST-ish)
    connected = [rooms_sorted[0]]
    unconnected = rooms_sorted[1:]

    while unconnected:
        best_dist = math.inf
        best_a = best_b = None
        for a in connected:
            for b in unconnected:
                ax, ay = a.center
                bx, by = b.center
                dist = abs(ax - bx) + abs(ay - by)
                if dist < best_dist:
                    best_dist = dist
                    best_a, best_b = a, b
        if best_a is None:
            break

        ax, ay = best_a.center
        bx, by = best_b.center

        # Horizontal first, then vertical
        step_x = 1 if bx > ax else -1
        step_y = 1 if by > ay else -1
        for col in range(ax, bx + step_x, step_x):
            if 0 <= col < width and 0 <= ay < height and grid[ay][col] == WALL:
                grid[ay][col] = CORRIDOR
        for row in range(ay, by + step_y, step_y):
            if 0 <= bx < width and 0 <= row < height and grid[row][bx] == WALL:
                grid[row][bx] = CORRIDOR

        corridors.append({
            "from": {"x": ax, "y": ay, "z": floor_z},
            "to":   {"x": bx, "y": by, "z": floor_z},
        })
        connected.append(best_b)
        unconnected.remove(best_b)

    # ── 5. Build ASCII art ──────────────────────────────────────────────────
    ascii_rows = ["".join(row) for row in grid]

    markers = {"entrance": ENTRANCE, "boss": BOSS, "treasure": TREASURE, "shrine": SHRINE}
    for room in rooms:
        if room.room_type in markers:
            cx, cy = room.center
            row_list = list(ascii_rows[cy])
            row_list[cx] = markers[room.room_type]
            ascii_rows[cy] = "".join(row_list)

    ascii_art = "\n".join(ascii_rows)

    # ── 6. AIDs ─────────────────────────────────────────────────────────────
    aids: Dict[str, Dict] = {}
    next_aid = 5000
    teleports = []

    entrance = next((r for r in rooms if r.room_type == "entrance"), rooms[0])
    boss_room = next((r for r in rooms if r.room_type == "boss"),     rooms[-1])
    treasure  = next((r for r in rooms if r.room_type == "treasure"), None)

    # Entrance teleport (links to city or surface)
    ex, ey = entrance.center
    aids[f"{ex},{ey},{floor_z}"] = {"aid": next_aid, "purpose": "teleport_saida_dungeon", "description": "Teleport de saída — leva de volta à cidade"}
    teleports.append({"from": {"x": ex, "y": ey, "z": floor_z}, "to": "cidade_spawn", "aid": next_aid, "label": "Saída da Dungeon"})
    next_aid += 1

    # Boss spawn AID
    bx, by = boss_room.center
    aids[f"{bx},{by},{floor_z}"] = {"aid": next_aid, "purpose": "spawn_boss", "description": "Centro da sala do boss"}
    next_aid += 1

    # Treasure room AID
    if treasure:
        tx, ty = treasure.center
        aids[f"{tx},{ty},{floor_z}"] = {"aid": next_aid, "purpose": "chest_treasure", "description": "Posição do baú de tesouro"}
        next_aid += 1

    # ── 7. Spawns ────────────────────────────────────────────────────────────
    monster_list = MONSTERS.get(dungeon_type, MONSTERS["dungeon"])
    spawns = []

    if monster_list:
        for room in rooms:
            if room.room_type == "boss" and len(monster_list) >= 1:
                spawns.append({
                    "position": {"x": room.center[0], "y": room.center[1], "z": floor_z},
                    "monster": monster_list[-1],
                    "radius": 2,
                    "count": 1,
                    "type": "boss",
                })
            elif room.room_type == "normal" and len(monster_list) >= 2:
                spawns.append({
                    "position": {"x": room.center[0], "y": room.center[1], "z": floor_z},
                    "monster": rng.choice(monster_list[:-1]),
                    "radius": 3,
                    "count": rng.randint(2, 6),
                    "type": "regular",
                })

    # ── 8. RME notes ─────────────────────────────────────────────────────────
    rme_notes = (
        f"Importar este spec no RME como referência. "
        f"Coordenadas são relativas ao tile de origem que você escolher. "
        f"Z={floor_z} equivale ao andar subterrâneo correspondente (7=1º sub, 8=2º, etc.). "
        f"Substitua os tiles genéricos pelos IDs específicos do tileset do projeto. "
        f"Tamanho total: {width}×{height} tiles."
    )

    return {
        "type": dungeon_type,
        "seed": seed,
        "dimensions": {"width": width, "height": height, "z": floor_z},
        "rooms": [r.to_dict(floor_z) for r in rooms],
        "corridors": corridors,
        "aids": aids,
        "spawns": spawns,
        "teleports": teleports,
        "ascii": ascii_art,
        "legend": {
            WALL:     "parede",
            FLOOR:    "chão (interior de sala)",
            CORRIDOR: "corredor",
            ENTRANCE: "sala de entrada (teleport de saída)",
            BOSS:     "sala do boss",
            TREASURE: "sala do tesouro",
            SHRINE:   "santuário / altar",
        },
        "rme_notes": rme_notes,
        "stats": {
            "total_rooms": len(rooms),
            "total_corridors": len(corridors),
            "total_spawns": len(spawns),
            "floor_tiles": sum(1 for row in grid for cell in row if cell in (FLOOR, CORRIDOR)),
        },
    }
