#!/usr/bin/env python3
"""Genereer SQL seed uit exercises_filtered.json voor handmatige import in Supabase."""

import json
from pathlib import Path

INPUT = Path(__file__).resolve().parent.parent / "Piccopalo" / "Resources" / "exercises_filtered.json"
OUTPUT = Path(__file__).resolve().parent.parent / "docs" / "db" / "migrations" / "004-exercise-library-seed.sql"

MUSCLE_MAP = {
    "chest": "borst",
    "lats": "rug", "middle back": "rug", "lower back": "rug", "traps": "rug",
    "shoulders": "schouders", "neck": "schouders",
    "biceps": "armen", "triceps": "armen", "forearms": "armen",
    "quadriceps": "benen", "hamstrings": "benen", "glutes": "benen",
    "calves": "benen", "adductors": "benen", "abductors": "benen",
    "abdominals": "core",
}


def sql_escape(value: str) -> str:
    return value.replace("'", "''")


def main() -> None:
    data = json.load(open(INPUT, encoding="utf-8"))
    rows = []
    for item in data:
        muscle = (item.get("primaryMuscles") or [None])[0]
        if not muscle:
            continue
        category = MUSCLE_MAP.get(muscle.lower())
        if not category:
            continue
        name = sql_escape(item["name"])
        level = item.get("level")
        instructions = item.get("instructions") or []
        instruction_text = sql_escape("\n\n".join(instructions)) if instructions else None
        thumbnail = item.get("images", [None])[0]
        source_id = sql_escape(item["id"])
        level_sql = f"'{sql_escape(level)}'" if level else "null"
        instructions_sql = f"'{instruction_text}'" if instruction_text else "null"
        thumbnail_sql = f"'{sql_escape(thumbnail)}'" if thumbnail else "null"
        rows.append(
            f"  ('{name}', '{category}', false, {level_sql}, {instructions_sql}, {thumbnail_sql}, '{source_id}')"
        )

    OUTPUT.write_text(
        "\n".join([
            "-- Piccopalo migratie 004 — handmatige seed (free-exercise-db)",
            "-- Vereist: 003-fitness-tables.sql + 004-exercise-library-import.sql",
            "-- Genereer opnieuw: python3 scripts/generate_exercise_seed_sql.py",
            "",
            "delete from public.exercises where user_id is null and is_custom = false;",
            "",
            "insert into public.exercises (name, category, is_custom, level, instructions, thumbnail_path, source_id)",
            "values",
            ",\n".join(rows),
            "on conflict (source_id) where (user_id is null and source_id is not null) do nothing;",
            "",
            f"-- {len(rows)} oefeningen",
        ]),
        encoding="utf-8",
    )
    print(f"Geschreven: {OUTPUT} ({len(rows)} oefeningen)")


if __name__ == "__main__":
    main()
