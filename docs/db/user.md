# User — gebruikersprofiel / account

## Wat is het?

Het **user**-domein bewaart de **profielgegevens** van de gebruiker: naam, gewicht, lengte, en de **standaard activiteitsfactor** die het **standaard eiwitdoel per dag** bepaalt (`gewicht × activityFactor`), tenzij een dagrecord een eigen factor heeft vastgelegd.

## Datamodel (`AccountData` + viewmodel)

[`AccountViewModel`](../../Piccopalo/ViewModels/AccountViewModel.swift) houdt de bron van waarheid in de UI. Persistentie loopt via **`UserProfileRepositoryProtocol`** (`loadAccount()` / `saveAccount(_:)`), gebacked door SwiftData. Het Codable-type **`AccountData`** (in hetzelfde bestand) is de payload voor repository en migratie.

| Veld | Betekenis |
|------|-----------|
| `name` | Weergavenaam |
| `weight` | Gewicht (kg), numeriek in opslag |
| `height` | Lengte (cm), numeriek in opslag |
| `activityFactor` | Default voor **nieuwe** dagen / eerste log van een dag |

**Activiteitsopties** (labels + factor) staan centraal in `AccountViewModel.activityOptions` (o.a. zelfde lijst als in dag-detail picker).

## Events

Na `saveAccount()` wordt **`Notification.Name.piccopaloAccountDidChange`** gepost zodat andere viewmodels (bijv. eiwit-home) kunnen herberekenen of herladen.

## Opslag (SwiftData)

- **Entity**: **`UserProfileEntity`** — `@Model` in [`UserProfileEntity.swift`](../../Piccopalo/Persistence/UserProfileEntity.swift); velden parallel aan `AccountData`.
- **Strategie**: één actief profiel (`fetchLimit(1)` / upsert in **`SwiftDataUserProfileRepository`**).
- **Migratie**: bestaande `piccopalo_account` (UserDefaults JSON) wordt bij eerste run geïmporteerd indien SwiftData leeg is; flag `swiftDataMigrated_v1` — zie [database.md](database.md).

### Legacy (`AccountStorage`)

Als er nog geen profiel in SwiftData staat en `piccopalo_account` ontbreekt, kan `AccountViewModel.loadAccount()` nog **`UserModel`** uit UserDefaults-key **`account`** laden (`AccountStorage`) en daarna naar de repository schrijven.

## Relatie met diary

- Account levert **default** `activityFactor` en **gewicht** voor nieuwe dagen en voor herberekening van doelen waar de app dat toepast.
- Een **opgeslagen dag** (`DayRecord` / `DiaryDayEntity`) kan een **afwijkende** `activityFactor` per dag vasthouden na de eerste log of na handmatige wijziging in detail.

Zie [diary.md](diary.md) voor dagrecords en [database.md](database.md) voor de totale persistencelaag.
