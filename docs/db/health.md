# Health — bloedsuiker, symptomen & glycemische index

## Wat is het?

Het **health**-domein voegt drie databasewijzigingen toe bovenop het basisschema: bloedsuikermetingen, gevoel/symptoom-registraties en glycemische voedingsdata op bestaande eiwit-innames. Alles wordt per gebruiker opgeslagen met RLS.

Deze wijzigingen leven in [`migrations/001-health-extension.sql`](migrations/001-health-extension.sql). De app gebruikt `date_iso text` (`yyyy-MM-dd`) consistent met de rest van het schema.

## Tabellen

### `blood_sugar_entries`

Eén rij per bloedsuikermeting. Mapt op `BloodSugarEntry` via [`SupabaseBloodSugarRepository.swift`](../../Piccopalo/Domains/Health/DB/SupabaseBloodSugarRepository.swift).

| Kolom | Type | Betekenis |
|-------|------|-----------|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | `auth.users(id)`, on delete cascade |
| `date_iso` | `text` | Dag van de meting (`yyyy-MM-dd`) |
| `recorded_at` | `timestamptz` | Exacte tijd van de meting |
| `value_mmol` | `double precision` | Waarde in mmol/L |
| `moment` | `text` | Zie momentwaarden hieronder (optioneel) |
| `note` | `text` | Vrije notitie (optioneel) |
| `created_at` | `timestamptz` | Insert-tijd |

**Momentwaarden** (`BSMoment` in [`BloodSugarEntry.swift`](../../Piccopalo/Domains/Health/Models/BloodSugarEntry.swift)):

| Waarde | Label |
|--------|-------|
| `nuchter` | Nuchter |
| `voor_eten` | Vóór het eten |
| `na_eten` | Na het eten |
| `nacht` | Nacht |
| `willekeurig` | Zomaar |

### `symptom_entries`

Eén rij per gevoel-registratie (energie, focus, honger op schaal 1-5). Mapt op `SymptomEntry` via [`SupabaseSymptomRepository.swift`](../../Piccopalo/Domains/Health/DB/SupabaseSymptomRepository.swift).

| Kolom | Type | Betekenis |
|-------|------|-----------|
| `id` | `uuid` | Primary key |
| `user_id` | `uuid` | `auth.users(id)`, on delete cascade |
| `date_iso` | `text` | Dag van registratie (`yyyy-MM-dd`) |
| `recorded_at` | `timestamptz` | Exacte tijd |
| `energy_level` | `int` | 1-5 (1=uitgeput, 5=top), optioneel |
| `focus_level` | `int` | 1-5, optioneel |
| `hunger_level` | `int` | 1-5, optioneel |
| `note` | `text` | Vrije notitie (optioneel) |
| `created_at` | `timestamptz` | Insert-tijd |

### `diary_entries` — extra kolommen

Nullable kolommen op de bestaande tabel, gevuld via barcode-scan ([`OpenFoodFactsService.swift`](../../Piccopalo/Services/OpenFoodFactsService.swift)) en gemapt in [`DiaryRepository.swift`](../../Piccopalo/Domains/Diary/DB/DiaryRepository.swift).

| Kolom | Type | Betekenis |
|-------|------|-----------|
| `carbs_grams` | `double precision` | Koolhydraten (g) voor de gelogde portie |
| `fiber_grams` | `double precision` | Vezels (g) |
| `fat_grams` | `double precision` | Vetten (g) |
| `glycemic_index` | `int` | GI-waarde (0-100) |
| `glycemic_load` | `double precision` | GL = (GI × koolhydraten) / 100 |

Bestaande entries zonder deze data blijven werken; de kolommen zijn `null` waar geen scan-data is.

## Wat zit NIET in de database

- **Timeline (Dag-tab)**: aggregeert bestaande tabellen in de app, geen eigen tabel. Zie [`DayTimelineView.swift`](../../Piccopalo/Domains/Health/Screens/DayTimelineView.swift).
- **Wekelijkse inzichten / correlaties**: lokaal berekend in [`HealthViewModel.calculateWeeklyInsights`](../../Piccopalo/Domains/Health/ViewModels/HealthViewModel.swift).
- **Stappen**: via HealthKit on-demand opgehaald, niet in Supabase opgeslagen.

## Beveiliging (RLS)

Elke tabel heeft RLS aan met policy `auth.uid() = user_id`. Een gebruiker ziet en schrijft uitsluitend eigen data.

## Toepassen

Zie [`migrations/README.md`](migrations/README.md). Kort: kopieer [`migrations/001-health-extension.sql`](migrations/001-health-extension.sql) in de Supabase SQL Editor en run. De migratie is idempotent.

Zie ook [database.md](database.md) voor de totale laag en [diary.md](diary.md) voor het dagboekmodel.
