# User — gebruikersprofiel / account

## Wat is het?

Het **user**-domein bewaart de **profielgegevens** van de gebruiker: naam, gewicht, lengte, en de **standaard activiteitsfactor** die het **standaard eiwitdoel per dag** bepaalt (`gewicht × activityFactor`), tenzij een dagrecord een eigen factor heeft vastgelegd.

## Datamodel (`AccountData` + viewmodel)

[`AccountViewModel`](../../Piccopalo/ViewModels/AccountViewModel.swift) houdt de bron van waarheid in de UI. Persistentie loopt via **`UserProfileRepositoryProtocol`** (`loadAccount()` / `saveAccount(_:)`) en praat via de repository-laag met **Supabase**. Het Codable-type **`AccountData`** (in hetzelfde bestand) is de payload voor repository en API.

| Veld | Betekenis |
|------|-----------|
| `name` | Weergavenaam |
| `weight` | Gewicht (kg), numeriek in opslag |
| `height` | Lengte (cm), numeriek in opslag |
| `activityFactor` | Default voor **nieuwe** dagen / eerste log van een dag |

**Activiteitsopties** (labels + factor) staan centraal in `AccountViewModel.activityOptions` (o.a. zelfde lijst als in dag-detail picker).

## Events

Na `saveAccount()` wordt **`Notification.Name.piccopaloAccountDidChange`** gepost zodat andere viewmodels (bijv. eiwit-home) kunnen herberekenen of herladen.

## Opslag

- **Bron van waarheid**: Supabase.
- **Strategie**: één profiel per gebruiker, gekoppeld aan `auth.users.id`.
- **Upsert**: profieldata wordt altijd per ingelogde gebruiker opgeslagen zodat accounts gescheiden blijven.

### Legacy (`AccountStorage`)

Als er nog oude data aanwezig is, kan `AccountViewModel.loadAccount()` nog **`UserModel`** uit UserDefaults-key **`account`** laden (`AccountStorage`).

## Relatie met diary

- Account levert **default** `activityFactor` en **gewicht** voor nieuwe dagen en voor herberekening van doelen waar de app dat toepast.
- Een **opgeslagen dag** (`DayRecord`) kan een **afwijkende** `activityFactor` per dag vasthouden na de eerste log of na handmatige wijziging in detail.

Zie [diary.md](diary.md) voor dagrecords en [database.md](database.md) voor de totale persistencelaag.
