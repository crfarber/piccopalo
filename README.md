# Piccopalo — design brief (iOS)

Korte referentie voor design: wat de app doet, welke schermen er zijn, welke inhoud en interacties designers kunnen uitwerken.

## Product in één zin

**Piccopalo helpt je je dagelijkse eiwitdoel te halen**: je ziet hoeveel eiwit je vandaag al binnen hebt, hoe ver je van je doel bent, en je kunt meerdere keren per dag grammetjes toevoegen (of corrigeren).

## Navigatie (tab bar)

Drie tabs, accentkleur in de app is **groen** (`TabView` met `.tint(.green)`).

| Tab | Doel |
|-----|------|
| **Today** (`HomeView`) | Startscherm: eiwit invoeren, voortgang vandaag |
| **History** (`HistoryView`) | Lijst met eerdere dagen + detail per dag |
| **Account** (`AccountView`) | Profielgegevens die het doel beïnvloeden (o.a. gewicht) |

Tab-labels in code: *Today*, *History*, *Account* (Engels); History-schermtitel in de navigatie: **Geschiedenis**.

## Rekenregels (belangrijk voor copy en uitleg)

- **Dagdoel eiwit (gram)** = `gewicht (kg) × activiteitsfactor`
  - Gewicht komt uit **Account** (lokaal opgeslagen profiel).
  - **Activiteitsfactor** zit in de app-logica (zie `ProteinViewModel`): o.a. 0.8 / 1.2 / 1.4 / 1.6 met bijbehorende Nederlandse labels (*Weinig beweging*, *Licht actief*, …).
  - In de **huidige UI** staat de activiteitskiezer **niet** op Today; de factor wordt wel uit een opgeslagen dagrecord geladen of valt terug op de standaard (1.2). Voor design: bepaal of activiteit op **Today**, **Account** of **onboarding** hoort — en hoe je dat uitlegt aan de gebruiker.
- **Gegeten eiwit vandaag** = optelling van alle toevoegingen (en aftrekken bij correctie), per kalenderdag.
- **Percentage richting doel** = `min(gegeten / doel × 100, 100)` (cap op 100% in de weergave).
- **Nog te gaan** = `max(doel − gegeten, 0)`.

## Today — startscherm (`HomeView`)

**Doel van het scherm:** snel eiwit loggen en direct feedback zien.

### Header

- Emoji **🍝** (placeholder voor een eigen app-icoon/illustratie).
- Titel: **Piccopalo**
- Subtitel: **Jouw dagelijkse eiwittracker**
- Titel nu in **groen**, subtitel secundaire tekstkleur.

### Sectie “Eiwit”

- **Label:** “Eiwit” met SF Symbol `dumbbell.fill` (kan vervangen worden door eigen asset / zonder icoon).
- **Invoer:** tekstveld **Gram** (decimaaltoetsenbord).
- **Acties:**
  - **+** (groen): telt ingevoerde gram bij het totaal van vandaag.
  - **−** (oranje): trekt ingevoerde gram af (correctie; totaal gaat niet onder 0).
- **Overlay rechtsboven:** knop met label **Eiwit** + icoon `carrot.fill` (opent voedselkiezer — zie modaal hieronder).

### Sectie “Vandaag”

- Label met `chart.bar.fill`.
- Rijen (key–value):
  - **Dagdoel** — `Xg`
  - **Gegeten** — `Xg` (groen)
  - **Nog te gaan** — `Xg` (oranje)
  - **Percentage** — `X%`
- **Voortgangsbalk** (`ProgressBarView`): achtergrond licht grijs; vulling **geel / oranje / groen** afhankelijk van percentage (<50 / 50–90 / ≥90).
- **Motivatiezin** onder de balk (afhankelijk van percentage), o.a. met emoji’s — kan herschreven worden voor tone-of-voice.

## Modaal: voedselkiezer (`ProteinSourcePickerView`)

**Doel:** eiwit toevoegen via een lijst met voedingsmiddelen en eiwit per 100g.

- **Zoekbalk** bovenaan.
- **Lijst:** naam links, `Xg` rechts (eiwit per 100g).
- **Detailstap na selectie:**
  - Titel *Selected Food*, naam van product, sluitknop (`xmark.circle.fill`).
  - Invoer *Protein Amount (grams)* + hint *Default: … g per 100g*.
  - Actie om toe te voegen en sheet te sluiten (flow sluit af met `dismiss`).

Design kan dit hernoemen naar Nederlands en de “per 100g”-uitleg visueel duidelijker maken (bijvoorbeeld rekenhulp of portie-slider).

## History — geschiedenis (`HistoryView`)

**Lege staat**

- Emoji **📅**
- **Nog geen data**
- Subtekst: *Voeg vandaag je eerste eiwitinname toe!*

**Met data**

- Inset grouped **list** van dagen (datum als `yyyy-MM-dd` in data — design kan dit formatteren naar locale-vriendelijke datum).
- Elke rij toont:
  - Datum (headline)
  - Regel: **Doel: Xg** | **Gegeten: Xg**
  - Voortgangsbalk (lage hoogte, ca. 10pt)
  - **X%** als caption

Tap → **Dagdetail** (`DayDetailView`).

## Dagdetail (`DayDetailView`)

**Doel:** inzicht in één dag + **handmatige correctie** van gegeten eiwit.

1. **Gegevens** (`person.fill`)
   - Gewicht (kg) — snapshot opgeslagen bij die dag
   - Activiteit — tekst afgeleid van factor
2. **Resultaten** (`chart.bar.fill`)
   - Eiwitdoel, gegeten, percentage + voortgangsbalk
3. **Handmatig aanpassen** (`square.and.pencil`)
   - Veld *Gegeten gram* + knop **Opslaan**
   - Uitleg: *Pas alleen deze dag aan. Je kunt fouten achteraf corrigeren.*

Design: overweeg bevestiging, undo, of “reset naar 0” als secundaire actie.

## Account (`AccountView`)

**Doel:** gegevens die het eiwitdoel sturen (nu vooral gewicht).

- Sectie **Jouw gegevens** (`person.fill`)
  - **Gewicht (kg)** — numeriek veld; wijzigingen worden opgeslagen (bij wijziging gewicht).

`AccountViewModel` heeft in code ook `name` en `length`; die staan **nog niet** in de UI — ruimte voor design om profiel uit te breiden.

## Onboarding (optioneel / in aanbouw)

Onder `Domains/Account/Onboarding/` staan onder andere `NameView`, `LengteView`, `WeightView`, `OnboardingView` — nog niet geïntegreerd in de hoofd-tabflow. Design kan hier een eerste-run flow voor voorstellen.

## Visuele richting (huidige implementatie)

- **Primaire accent:** groen (titels, tab tint, sommige knoppen).
- **Secundair:** oranje (correctie), blauw (opslaan in detail), systeemgrijs voor achtergronden van kaarten/knoppen.
- Veel gebruik van **SF Symbols** en **emoji** als tijdelijke branding — vervangbaar door illustraties en eigen iconenset.

## Wat de designer concreet kan opleveren

1. **Brand kit:** logo, kleuren, typografie (Dynamic Type), dark mode.
2. **Componenten:** tab bar, group cards, primary/secondary/destructive buttons, invoervelden (inclusief decimal pad), voortgangsbalk states (0–100%, >100% als je ooit uncappen wilt).
3. **Copy deck** NL/EN voor alle labels, lege staten en foutmeldingen (onder andere gewicht 0 → doel 0; uitleg activiteit).
4. **Flows op papier/Figma:** Today (handmatig + uit lijst), History → Detail → handmatige edit, Account.
5. **Datumweergave:** gebruikersvriendelijke datum in plaats van raw `yyyy-MM-dd` in lijst en detail.

## Technische context (voor afstemming)

- Platform: **SwiftUI**, iOS-app in map `Piccopalo/`.
- Data: **SwiftData** (lokaal) met repositories; eenmalige migratie van oude UserDefaults-keys (`piccopalo_records`, `piccopalo_account`). Optioneel legacy **`account`** via `AccountStorage` bij eerste load.

---

*Dit document beschrijft de app zoals die in de codebase staat; waar de UI en de logica nog niet volledig synchroon zijn (zoals activiteit op Today), is dat bewust vermeld zodat design en development hetzelfde verwachtingspatroon kunnen afspreken.*
