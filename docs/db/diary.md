# Diary — eiwit per dag (dagboek)

## Wat is het?

Het **diary**-domein bewaart per **kalenderdag** (ISO-string `yyyy-MM-dd`) hoeveel eiwit iemand heeft gegeten, tegen welk **doel** dat die dag gold, met daarbij **gewicht** en **activiteitsfactor** zoals die voor die dag gelden (default uit account, aanpasbaar per dag in detail).

## Domeinmodel (`DayRecord`)

Struct in de app (Codable, `Identifiable` via `date`):

| Veld | Type | Betekenis |
|------|------|------------|
| `date` | `String` | Unieke dag, formaat `yyyy-MM-dd` |
| `weight` | `Double` | Gewicht (kg) gebruikt voor doelberekening / weergave |
| `activityFactor` | `Double` | Vermenigvuldiger voor eiwitdoel (zelfde schaal als account-opties) |
| `proteinGoal` | `Double` | Doel in gram voor die dag (`weight × activityFactor` in productlogica) |
| `proteinConsumed` | `Double` | Gegeten eiwit (g) |
| `entries` | `[ProteinEntry]` | Losse innames op die dag (bron, hoeveelheid, unit, berekende eiwitgrammen) |

### Inname model (`ProteinEntry`)

Elke losse inname bevat:

| Veld | Type | Betekenis |
|------|------|------------|
| `id` | `UUID` | Unieke entry-id |
| `sourceName` | `String` | Herkomst (bijv. Milk, Handmatig, Correctie) |
| `quantity` | `Double` | Ingevoerde hoeveelheid |
| `unit` | `ProteinEntryUnit` | `g` of `ml` |
| `proteinPer100` | `Double` | Voedingswaarde per 100 unit |
| `proteinAmount` | `Double` | Berekende bijdrage in eiwitgrammen |
| `createdAt` | `Date` | Tijdstip van loggen |

## Waar wordt het gebruikt?

- **Home / vandaag**: `ProteinViewModel` laadt en schrijft de record voor “vandaag” via `DiaryRepositoryProtocol`.
- **Dag-tab**: weekstrip, dagoverzicht (eiwit, water, activiteit, stappen) en tijdlijn lezen records via `ProteinViewModel.record(for:)` / `allRecords()`. Activiteit per dag aanpasbaar via `ProteinViewModel.saveDayRecord(_:)`. Items verwijderen via swipe-to-delete op de tijdlijn.

## Opslag

- **Bron van waarheid**: Supabase/PostgreSQL.
- **Repository**: `DiaryRepositoryProtocol` wordt ingevuld door een `SupabaseDiaryRepository`.
- **Mapping**: `DayRecord` en `ProteinEntry` worden gemapt naar API-payloads voor `diary_days` en `diary_entries`.

## Gedrag (productregels, kort)

- **Eerste log van de dag**: `activityFactor` komt uit het **account** (default).
- **Verdere logs diezelfde dag**: bestaande `activityFactor` van die dag blijft staan (niet opnieuw overschrijven bij elke +).
- **Dag-tab**: gebruiker kan activiteit per dag aanpassen; doel wordt opnieuw berekend o.b.v. gewicht × gekozen factor.
- **Food picker**: gebruiker voert hoeveelheid in (`g` of `ml`) en de app rekent automatisch:
	- `proteinAmount = (quantity / 100) × proteinPer100`
- **Dagtotaal**: `proteinConsumed` wordt opgebouwd vanuit losse entries en blijft als snapshot zichtbaar.
- **Remote sync**: records worden per gebruiker opgeslagen met `user_id` als scheiding.

Zie ook [database.md](database.md) voor de totale laag en [user.md](user.md) voor het account dat de default levert.
