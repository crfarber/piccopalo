#!/usr/bin/env python3
"""Download and filter free-exercise-db for Piccopalo bundle import."""

import json
import urllib.request
from collections import Counter
from pathlib import Path

URL = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json"
OUTPUT = Path(__file__).resolve().parent.parent / "Piccopalo" / "Resources" / "exercises_filtered.json"

ALLOWED_EQUIPMENT = {
    "barbell",
    "dumbbell",
    "cable",
    "machine",
    "e-z curl bar",
    "body only",
    "kettlebells",
}


def main() -> None:
    with urllib.request.urlopen(URL) as resp:
        data = json.load(resp)

    filtered = [
        e
        for e in data
        if e.get("category") == "strength" and e.get("equipment") in ALLOWED_EQUIPMENT
    ]

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(filtered, f, indent=2, ensure_ascii=False)

    equipment_counts = Counter(e.get("equipment") for e in filtered)
    print(f"Totaal origineel:  {len(data)}")
    print(f"Na filtering:      {len(filtered)}")
    print("Per equipment:")
    for equip, count in sorted(equipment_counts.items()):
        print(f"  {equip}: {count}")


if __name__ == "__main__":
    main()
