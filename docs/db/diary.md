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
- **Geschiedenis**: lijst en weekstrip lezen records via `ProteinViewModel.record(for:)` / `allRecords()` (gesorteerd op datum, nieuwste eerst).
- **Dagdetail**: handmatig gram en activiteit per dag; persist via `ProteinViewModel.saveDayRecord(_:)`.

## Opslag (SwiftData)

- **Entity**: **`DiaryDayEntity`** — `@Model` in [`DiaryDayEntity.swift`](../../Piccopalo/Persistence/DiaryDayEntity.swift); unieke **`dateISO`**; velden parallel aan `DayRecord`.
- **Entity**: **`DiaryProteinEntryEntity`** — `@Model` met relatie naar `DiaryDayEntity` (1 dag -> meerdere entries).
- **Protocol**: **`DiaryRepositoryProtocol`** — `day(for:)`, `save(_:)`, `allDaysSorted()`.
- **Implementatie**: **`SwiftDataDiaryRepository`** — mapt `DayRecord` ↔ entity; sortering `dateISO` aflopend.

Eenmalige import van vroeger opgeslagen `piccopalo_records` (UserDefaults) gebeurt in **`SwiftDataMigration`**; zie [database.md](database.md).

## Gedrag (productregels, kort)

- **Eerste log van de dag**: `activityFactor` komt uit het **account** (default).
- **Verdere logs diezelfde dag**: bestaande `activityFactor` van die dag blijft staan (niet opnieuw overschrijven bij elke +).
- **Detailpagina**: gebruiker kan activiteit en grammen aanpassen; doel wordt opnieuw berekend o.b.v. gewicht × gekozen factor.
- **Food picker**: gebruiker voert hoeveelheid in (`g` of `ml`) en de app rekent automatisch:
	- `proteinAmount = (quantity / 100) × proteinPer100`
- **Dagtotaal**: `proteinConsumed` wordt opgebouwd vanuit losse entries en blijft als snapshot zichtbaar.

Zie ook [database.md](database.md) voor de totale laag en [user.md](user.md) voor het account dat de default levert.
