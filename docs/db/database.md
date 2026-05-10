# Database- en persistencelaag (Piccopalo)

Dit document beschrijft **waar app-data leeft**, hoe de lagen in elkaar zitten, en hoe dat aansluit op toekomstige uitbreiding (bijv. een backend op Azure).

## Doel van de laag

- **Huidig**: app-data leeft remote in **Supabase/PostgreSQL**.
- **Transport**: de app praat met Supabase via **Alamofire**.
- **Architectuur**: de repository-contracten blijven de schakel tussen UI en data-bron.

## Huidige situatie

- **Auth**: gebruikers loggen in via **Supabase Auth**.
- **Data-opslag**: dagrecords, losse inname-entries en gebruikersprofiel leven in **Supabase-tabellen**.
- **Transport**: de app praat met Supabase via **Alamofire**.
- **Beveiliging**: row level security zorgt ervoor dat een gebruiker alleen eigen data ziet.

```text
PiccopaloApp
  └── auth + repositories
         └── Supabase Auth + Supabase API
                ├── diary repository
                └── user profile repository
```

ViewModels krijgen repository-implementaties geïnjecteerd (`ProteinViewModel`, `AccountViewModel`).

## Supabase-opzet

Supabase is de bron van waarheid voor alle gebruikersdata. De app gebruikt:

- **Supabase Auth** voor login en sessies.
- **Supabase PostgreSQL** voor opslag van account- en dagdata.
- **Alamofire** voor HTTP-calls richting Supabase REST endpoints.
- **RLS** om af te dwingen dat een gebruiker alleen eigen data ziet.

### Tabellen

De data wordt logisch verdeeld over drie tabellen:

- **`user_profiles`**: één profiel per gebruiker.
- **`diary_days`**: één record per gebruiker per datum.
- **`diary_entries`**: losse inname-entries per dag.

De relationele sleutel is steeds de ingelogde Supabase-gebruiker via `auth.users.id`.

### RLS

Row Level Security is verplicht zodat de client nooit andermans data kan lezen of schrijven.

Basisregel:

- `user_profiles.id = auth.uid()`
- `diary_days.user_id = auth.uid()`
- `diary_entries.user_id = auth.uid()`

Dat betekent dat elke query automatisch afgekapt wordt tot de huidige gebruiker.

### API-verantwoordelijkheden

De API-laag wordt verantwoordelijk voor:

- inloggen en sessieherstel
- profiel ophalen en opslaan
- dagrecords ophalen en opslaan
- losse entries ophalen en opslaan
- eventueel later: sync, conflict resolution en offline queueing

### Alamofire-opzet

Alamofire is geschikt als transportlaag voor de Supabase REST-calls. De API-laag kan dan bestaan uit:

- een kleine `APIClient` met de base URL van Supabase
- een `Session` met auth headers
- requests voor `select`, `insert`, `update`, `upsert` en `delete`
- decodering van JSON naar domeinmodellen zoals `AccountData`, `DayRecord` en `ProteinEntry`

Dat houdt de repository-implementaties dun: zij vertalen alleen tussen domeinmodellen en API-payloads.

### Quantity-based logging (g/ml)

Via de food picker voert de gebruiker een hoeveelheid in met bron-specifieke unit (`g` of `ml`).

De app berekent eiwit automatisch met:

`proteinAmount = (quantity / 100) * proteinPer100`

De berekende waarde wordt als losse inname-entry aan de dag gehangen en verwerkt in `proteinConsumed`.

`Notification.Name.piccopaloAccountDidChange` wordt na elke account-save nog steeds gepost zodat andere onderdelen (zoals eiwit-home) kunnen reageren.

### Legacy account (`account` key)

Heel oude profieldata kan onder UserDefaults-key **`account`** (`UserModel` via `AccountStorage`) staan. Dat is alleen nog relevant voor oude installs.

## Gerelateerde documenten

- [diary.md](diary.md) — dagboek / eiwit per dag  
- [user.md](user.md) — gebruikersprofiel / account  

## Onderhoud

Pas dit bestand aan bij wijzigingen aan **auth-flow**, **Supabase-tabellen**, **RLS**, **API-laag**, of **repository-grenzen**.
