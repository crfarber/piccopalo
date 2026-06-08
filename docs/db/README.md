# Piccopalo — database (Supabase / PostgreSQL)

Deze map is de **bron van waarheid** voor het databaseschema. Gebruik deze bestanden om Supabase bij te werken of een nieuwe omgeving op te zetten.

## Structuur

```text
docs/db/
├── README.md                 ← dit bestand
├── database.md               ← architectuur & app-koppeling (niet-SQL)
├── diary.md / user.md        ← domein-uitleg per feature
├── health.md                 ← bloedsuiker / symptomen / GI (niet-SQL)
├── schema/                   ← huidige basis (al in productie)
│   ├── 01-user_profiles.sql
│   ├── 02-diary_days.sql
│   ├── 03-diary_entries.sql
│   ├── 04-water_entries.sql
│   └── 05-rls-base.sql
└── migrations/               ← incrementele wijzigingen (nieuw toepassen)
    ├── README.md
    ├── 001-health-extension.sql
    └── 002-user-water-goal.sql
```

## Nieuw project of lege database

Voer in de **Supabase SQL Editor** uit, in deze volgorde:

1. [`schema/01-user_profiles.sql`](schema/01-user_profiles.sql)
2. [`schema/02-diary_days.sql`](schema/02-diary_days.sql)
3. [`schema/03-diary_entries.sql`](schema/03-diary_entries.sql)
4. [`schema/04-water_entries.sql`](schema/04-water_entries.sql)
5. [`schema/05-rls-base.sql`](schema/05-rls-base.sql)

Daarna alle openstaande migraties uit [`migrations/`](migrations/) in volgorde.

## Bestaand project (zoals jouw Supabase nu)

Je hebt de tabellen uit `schema/` al. Sla `schema/` over en draai **alleen** wat openstaat in `migrations/`:

1. [`migrations/001-health-extension.sql`](migrations/001-health-extension.sql) — bloedsuiker, symptomen, GI-kolommen
2. [`migrations/002-user-water-goal.sql`](migrations/002-user-water-goal.sql) — alleen als `water_goal_ml` nog ontbreekt

Zie [`migrations/README.md`](migrations/README.md) voor de stappen en log, en [`health.md`](health.md) voor de schema-uitleg.

## Conventies

| Onderwerp | Keuze |
|-----------|--------|
| Datums per dag | `date_iso text` — formaat `yyyy-MM-dd` |
| Gebruiker | `user_id uuid` → `auth.users(id)`, behalve `user_profiles.id` |
| Beveiliging | RLS op elke tabel; policy `auth.uid() = user_id` (of `id` bij profiel) |
| Idempotent | Migraties gebruiken `if not exists` / `add column if not exists` waar mogelijk |

## App-mapping (kort)

| Tabel | Swift / domein |
|-------|----------------|
| `user_profiles` | `AccountData` |
| `diary_days` + `diary_entries` | `DayRecord` + `ProteinEntry` |
| `water_entries` | `WaterEntry` |
| `blood_sugar_entries` | `BloodSugarEntry` *(migratie 001)* |
| `symptom_entries` | `SymptomEntry` *(migratie 001)* |

Zie ook [database.md](database.md), [diary.md](diary.md), [user.md](user.md) en [health.md](health.md).
