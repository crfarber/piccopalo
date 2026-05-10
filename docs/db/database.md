# Database- en persistencelaag (Piccopalo)

Dit document beschrijft **waar app-data leeft**, hoe de lagen in elkaar zitten, en hoe dat aansluit op toekomstige uitbreiding (bijv. een backend op Azure).

## Doel van de laag

- **Lokaal**: betrouwbare opslag van **dagrecords** (eiwit per dag), losse **inname-entries** per dag, en **gebruikersprofiel** (account) via **SwiftData** (SQLite).
- **Later**: dezelfde **repository-contracten** kunnen worden vervangen door een implementatie die HTTP naar een API praat; de UI hoeft dan minimaal te wijzigen.

## Huidige situatie

### SwiftData (bron van waarheid)

- **`ModelContainer`**: aangemaakt in [`PersistenceController`](../../Piccopalo/Persistence/PersistenceController.swift) met schema **`DiaryDayEntity`**, **`DiaryProteinEntryEntity`**, **`UserProfileEntity`**.
- **`.modelContainer(...)`**: gehangen op `WindowGroup` in [`PiccopaloApp`](../../Piccopalo/PiccopaloApp.swift).
- **Repositories** (main actor, `ModelContext` = `container.mainContext`):
  - **`SwiftDataDiaryRepository`** — implementeert `DiaryRepositoryProtocol`
  - **`SwiftDataUserProfileRepository`** — implementeert `UserProfileRepositoryProtocol`

```text
PiccopaloApp
  └── .modelContainer(shared)
         └── PersistenceController.shared
                ├── diaryRepository
                └── userProfileRepository
```

ViewModels krijgen deze repositories geïnjecteerd (`ProteinViewModel`, `AccountViewModel`).

### Quantity-based logging (g/ml)

Via de food picker voert de gebruiker een hoeveelheid in met bron-specifieke unit (`g` of `ml`).

De app berekent eiwit automatisch met:

`proteinAmount = (quantity / 100) * proteinPer100`

De berekende waarde wordt als losse inname-entry aan de dag gehangen en verwerkt in `proteinConsumed`.

### Migratie van UserDefaults (eenmalig)

Oude installs hadden JSON in UserDefaults:

| Sleutel | Inhoud |
|---------|--------|
| `piccopalo_records` | Dictionary `datum (yyyy-MM-dd)` → `DayRecord` |
| `piccopalo_account` | `AccountData` (naam, gewicht, lengte, `activityFactor`) |

[`SwiftDataMigration`](../../Piccopalo/Persistence/SwiftDataMigration.swift) draait bij app-start **als** `swiftDataMigrated_v1` nog niet `true` is:

1. Als er al SwiftData-rijen zijn → alleen de flag zetten (geen dubbele import).
2. Anders UserDefaults-data importeren naar entities, `modelContext.save()`, daarna **`swiftDataMigrated_v1 = true`**.
3. Daarna: **alleen** repositories / SwiftData voor dag- en accountdata.

`Notification.Name.piccopaloAccountDidChange` wordt na elke account-save nog steeds gepost zodat andere onderdelen (zoals eiwit-home) kunnen reageren.

### Legacy account (`account` key)

Heel oude profieldata kan onder UserDefaults-key **`account`** (`UserModel` via `AccountStorage`) staan. Als SwiftData nog geen profiel heeft, laadt [`AccountViewModel`](../../Piccopalo/ViewModels/AccountViewModel.swift) dat pad en schrijft direct door naar de repository.

## Gerelateerde documenten

- [diary.md](diary.md) — dagboek / eiwit per dag  
- [user.md](user.md) — gebruikersprofiel / account  

## Onderhoud

Pas dit bestand aan bij wijzigingen aan **container-setup**, **migratiestrategie**, of **repository-grenzen**.
