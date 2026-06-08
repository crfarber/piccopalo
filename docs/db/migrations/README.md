# Database-migraties

Incrementele SQL-bestanden voor **bestaande** Supabase-projecten. Voer alleen migraties uit die je nog niet hebt toegepast.

## Volgorde

| # | Bestand | Beschrijving | Status |
|---|---------|--------------|--------|
| 001 | [`001-health-extension.sql`](001-health-extension.sql) | Bloedsuiker, symptomen, GI-kolommen op `diary_entries` | **Open** — Health Uitbreiding plan |
| 002 | [`002-user-water-goal.sql`](002-user-water-goal.sql) | Kolom `water_goal_ml` op `user_profiles` (app verwacht dit veld) | **Controleren** — mogelijk al handmatig toegevoegd |

## Toepassen (Supabase Dashboard)

1. Open je project op [supabase.com](https://supabase.com) → **SQL Editor** → **New query**
2. Kopieer de volledige inhoud van [`001-health-extension.sql`](001-health-extension.sql) en plak in de editor
3. Klik **Run** (`Cmd+Enter`) — je zou **Success** moeten zien
4. Optioneel: controleer of `water_goal_ml` op `user_profiles` staat; ontbreekt die, run dan ook [`002-user-water-goal.sql`](002-user-water-goal.sql)
5. Vink hieronder af dat de migratie gedraaid is

Beide bestanden zijn idempotent (`if not exists` / `add column if not exists`), dus opnieuw draaien is veilig. Het verificatieblok onderaan elk SQL-bestand kun je uncommenten om de wijzigingen te bevestigen.

Schema-uitleg per tabel staat in [`../health.md`](../health.md).

## Log (handmatig bijhouden)

```text
[ ] 001-health-extension — productie
[ ] 002-user-water-goal — productie
```

## Nieuwe migratie toevoegen

1. Maak `00N-korte-naam.sql` in deze map
2. Gebruik `if not exists` / `add column if not exists`
3. Voeg RLS + index toe voor nieuwe tabellen
4. Werk deze README en [`../README.md`](../README.md) bij

Bronplan: [`../../plans/Health Uitbreiding: Bloedsuiker, GI & Correlaties.md`](../../plans/Health%20Uitbreiding:%20Bloedsuiker,%20GI%20&%20Correlaties.md)
