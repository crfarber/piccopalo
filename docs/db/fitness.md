# Fitness — oefeningen, schema's, sessies & sets

## Wat is het?

Het **fitness**-domein voegt krachttraining-tracking toe: een oefeningen-bibliotheek (ingebouwd + eigen), trainingsschema's per dag van de week, vrij of vanuit een schema gelogde sessies, en gelogde sets per oefening met referentie naar de vorige keer.

De wijzigingen leven in [`migrations/003-fitness-tables.sql`](migrations/003-fitness-tables.sql) (tabellen + RLS), [`migrations/004-exercise-library-import.sql`](migrations/004-exercise-library-import.sql) (import-kolommen + RPC), en optioneel [`migrations/003-fitness-seed.sql`](migrations/003-fitness-seed.sql) (38 handmatige oefeningen, vervangen door app-import).

## Tabellen

### `exercises`

Oefeningen-bibliotheek. Mapt op `Exercise` via [`SupabaseExerciseRepository.swift`](../../Piccopalo/Domains/Fitness/DB/SupabaseExerciseRepository.swift).

| Kolom | Type | Betekenis |
|-------|------|-----------|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid?` | `null` = standaard-oefening (voor iedereen); gevuld = eigen oefening |
| `name` | `text` | Naam van de oefening |
| `category` | `text` | `borst` \| `rug` \| `schouders` \| `armen` \| `benen` \| `core` |
| `is_custom` | `boolean` | `true` = door gebruiker aangemaakt |
| `level` | `text?` | Moeilijkheid: `beginner` \| `intermediate` \| `expert` *(migratie 004)* |
| `instructions` | `text?` | Stap-voor-stap uitleg *(migratie 004)* |
| `thumbnail_path` | `text?` | Relatief pad naar free-exercise-db afbeelding *(migratie 004)* |
| `source_id` | `text?` | Origineel free-exercise-db id; dedup-index *(migratie 004)* |
| `created_at` | `timestamptz` | Insert-tijd |

**RLS:** iedereen leest standaard-oefeningen (`user_id is null`) plus de eigen oefeningen. Insert/update/delete alleen op eigen oefeningen met `is_custom = true`. Standaard-oefeningen worden geïmporteerd via RPC `seed_standard_exercises` (SECURITY DEFINER, migratie 004).

### `workout_templates`

Trainingsschema. Mapt op `WorkoutTemplate`.

| Kolom | Type | Betekenis |
|-------|------|-----------|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | `auth.users(id)`, on delete cascade |
| `name` | `text` | Bijv. "Push dag", "Beendag" |
| `day_of_week` | `int?` | 1=maandag t/m 7=zondag, `null` = geen vaste dag |
| `created_at` | `timestamptz` | Insert-tijd |

### `workout_template_exercises`

Oefeningen binnen een schema, met doelwaarden. Mapt op `WorkoutTemplateExercise`.

| Kolom | Type | Betekenis |
|-------|------|-----------|
| `id` | `uuid` | Primary key |
| `template_id` | `uuid` | `workout_templates(id)`, on delete cascade |
| `exercise_id` | `uuid` | `exercises(id)`, on delete cascade |
| `sort_order` | `int` | Volgorde in het schema |
| `target_sets` | `int?` | Geplande sets (suggestie) |
| `target_reps` | `int?` | Geplande reps (suggestie) |
| `target_weight_kg` | `double precision?` | Gepland gewicht (suggestie) |
| `target_rest_seconds` | `int?` | Geplande rust (default 90) |

### `workout_sessions`

Eén rij per uitgevoerde training. Mapt op `WorkoutSession`.

| Kolom | Type | Betekenis |
|-------|------|-----------|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | `auth.users(id)`, on delete cascade |
| `date_iso` | `text` | Dag van de sessie (`yyyy-MM-dd`) |
| `template_id` | `uuid?` | Schema; `null` = vrij gelogd. On delete set null |
| `started_at` | `timestamptz?` | Starttijd |
| `finished_at` | `timestamptz?` | Eindtijd (leeg = nog bezig) |
| `note` | `text?` | Vrije notitie |
| `created_at` | `timestamptz` | Insert-tijd |

### `workout_sets`

Gelogde set binnen een sessie. Mapt op `WorkoutSet`.

| Kolom | Type | Betekenis |
|-------|------|-----------|
| `id` | `uuid` | Primary key |
| `session_id` | `uuid` | `workout_sessions(id)`, on delete cascade |
| `exercise_id` | `uuid` | `exercises(id)`, on delete cascade |
| `set_number` | `int` | 1, 2, 3... |
| `reps` | `int?` | Aantal herhalingen |
| `weight_kg` | `double precision?` | Gewicht in kg |
| `rest_seconds` | `int?` | Gehouden rust |
| `note` | `text?` | Vrije notitie |
| `logged_at` | `timestamptz` | Tijd van loggen |

## Relaties

```text
exercises ─┐
           ├─< workout_template_exercises >─ workout_templates ─< workout_sessions ─< workout_sets
           └──────────────────────────────────────────────────────────────────────┘
```

- Een schema (`workout_templates`) bevat geordende oefeningen (`workout_template_exercises`).
- Een sessie (`workout_sessions`) hoort optioneel bij een schema en bevat sets (`workout_sets`).
- Een set verwijst rechtstreeks naar een oefening, zodat de "vorige keer"-referentie per oefening over alle sessies werkt.

## Vorige sessie referentie

`SupabaseWorkoutRepository.fetchPreviousSets(exerciseId:before:)` zoekt de meest recente sessie vóór een datum die daadwerkelijk sets voor die oefening bevat, en geeft die sets terug als `PreviousSetSummary`. De index `workout_sets_exercise_idx` houdt dit snel.

## Toepassen

Zie [`migrations/README.md`](migrations/README.md): `003-fitness-tables.sql`, dan `004-exercise-library-import.sql`. De app importeert daarna automatisch uit `Piccopalo/Resources/exercises_filtered.json`.

## Oefeningen-bibliotheek import

- **Bron:** [free-exercise-db](https://github.com/yuhonas/free-exercise-db) — gefilterd via [`scripts/filter_exercises.py`](../../scripts/filter_exercises.py)
- **Bundle:** `Piccopalo/Resources/exercises_filtered.json`
- **Import:** `ExerciseImportService` roept `seed_standard_exercises(batch, replace_all)` aan in batches van 50
- **Eenmalig per device:** `UserDefaults` key `exerciseLibrarySeeded_v1`
