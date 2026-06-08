# Piccopalo – Health Uitbreiding: Bloedsuiker, GI & Correlaties
### Implementatieplan voor Cursor/co-pilot

---

## Context & Uitgangspunt

De app heeft al:
- Protein tracking ring (groen, binnenste ring)
- Water tracking ring (blauw, buitenste ring)
- Quick-add knoppen voor beide
- Barcode scanner via AVFoundation + Open Food Facts API
- Supabase backend met tabellen: `diary_days`, `diary_entries`, `user_profiles`, `water_entries`
- Schema-conventie: **`date_iso text`** (niet `datum date`) — dit moet overal consistent blijven
- Push notificaties voor water (11:00, 14:00, 17:00, 20:00)

Dit plan voegt toe:
1. Bloedsuiker-logging (handmatig)
2. Koolhydraten + Glycemische Index (GI) via barcode scanner
3. Symptoom/notitie-tracking
4. Correlatie-inzichten (wekelijks)
5. Timeline-view (dagoverzicht)

---

## Supabase: Nieuwe Tabellen

> **Canonieke bron:** de uitvoerbare SQL leeft in [`docs/db/migrations/001-health-extension.sql`](../db/migrations/001-health-extension.sql) (plus [`002-user-water-goal.sql`](../db/migrations/002-user-water-goal.sql) voor het waterdoel). De SQL hieronder is referentie; werk wijzigingen bij in de migratiebestanden, niet hier. Schema-uitleg staat in [`docs/db/health.md`](../db/health.md).

### 1. `blood_sugar_entries`

```sql
create table blood_sugar_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date_iso text not null,           -- bijv. "2024-06-07"
  recorded_at timestamptz not null, -- exacte tijd van meting
  value_mmol float not null,        -- waarde in mmol/L
  moment text,                      -- "nuchter" | "voor_eten" | "na_eten" | "nacht" | "willekeurig"
  note text,                        -- optionele vrije notitie
  created_at timestamptz default now()
);

-- RLS
alter table blood_sugar_entries enable row level security;
create policy "Eigen data" on blood_sugar_entries
  for all using (auth.uid() = user_id);
```

### 2. `symptom_entries`

```sql
create table symptom_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  date_iso text not null,
  recorded_at timestamptz not null,
  energy_level int check (energy_level between 1 and 5),  -- 1=uitgeput, 5=top
  focus_level int check (focus_level between 1 and 5),
  hunger_level int check (hunger_level between 1 and 5),
  note text,
  created_at timestamptz default now()
);

alter table symptom_entries enable row level security;
create policy "Eigen data" on symptom_entries
  for all using (auth.uid() = user_id);
```

### 3. Uitbreiding `diary_entries` — extra voedingsdata

Voeg kolommen toe aan bestaande tabel:

```sql
alter table diary_entries
  add column if not exists carbs_grams float,        -- koolhydraten in gram
  add column if not exists fiber_grams float,        -- vezels in gram
  add column if not exists fat_grams float,          -- vetten in gram
  add column if not exists glycemic_index int,       -- GI waarde (0-100)
  add column if not exists glycemic_load float;      -- GL = (GI × KH) / 100
```

> **Let op:** `diary_entries` gebruikt al `date_iso text`. Deze kolommen zijn nullable, zodat bestaande entries niet breken.

---

## Swift Data Models

Maak een nieuw bestand `HealthModels.swift`:

```swift
import Foundation

// MARK: - Bloedsuiker

struct BloodSugarEntry: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let dateIso: String           // "2024-06-07"
    let recordedAt: Date
    let valueMmol: Double         // mmol/L
    let moment: BSMoment?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dateIso = "date_iso"
        case recordedAt = "recorded_at"
        case valueMmol = "value_mmol"
        case moment
        case note
    }
}

enum BSMoment: String, Codable, CaseIterable {
    case nuchter = "nuchter"
    case voorEten = "voor_eten"
    case naEten = "na_eten"
    case nacht = "nacht"
    case willekeurig = "willekeurig"

    var label: String {
        switch self {
        case .nuchter: return "Nuchter"
        case .voorEten: return "Vóór het eten"
        case .naEten: return "Na het eten"
        case .nacht: return "Nacht"
        case .willekeurig: return "Zomaar"
        }
    }
}

// MARK: - Symptomen

struct SymptomEntry: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let dateIso: String
    let recordedAt: Date
    let energyLevel: Int?         // 1–5
    let focusLevel: Int?          // 1–5
    let hungerLevel: Int?         // 1–5
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dateIso = "date_iso"
        case recordedAt = "recorded_at"
        case energyLevel = "energy_level"
        case focusLevel = "focus_level"
        case hungerLevel = "hunger_level"
        case note
    }
}

// MARK: - Glycemische data (uitbreiding op bestaand DiaryEntry model)

// Voeg deze velden toe aan het bestaande DiaryEntry model:
// var carbsGrams: Double?
// var fiberGrams: Double?
// var fatGrams: Double?
// var glycemicIndex: Int?
// var glycemicLoad: Double?
//
// En in CodingKeys:
// case carbsGrams = "carbs_grams"
// case fiberGrams = "fiber_grams"
// case fatGrams = "fat_grams"
// case glycemicIndex = "glycemic_index"
// case glycemicLoad = "glycemic_load"

// MARK: - Correlatie berekening (lokaal, geen server)

struct WeeklyInsight {
    let avgBSAfterHighGI: Double?    // gemiddelde BS stijging na hoog-GI eten
    let avgBSAfterLowGI: Double?     // gemiddelde BS stijging na laag-GI eten
    let avgBSHighActivity: Double?   // gemiddelde BS op actieve dagen (>8k stappen)
    let avgBSLowActivity: Double?    // gemiddelde BS op rustige dagen (<5k stappen)
    let avgDailyBS: Double?          // gemiddelde BS deze week
    let dataPoints: Int              // hoeveel metingen
}
```

---

## Supabase Service Uitbreiding

Maak een nieuw bestand `HealthService.swift`:

```swift
import Foundation
import Supabase

class HealthService: ObservableObject {
    private let supabase = SupabaseManager.shared.client  // gebruik bestaande client

    // MARK: - Bloedsuiker

    func saveBSReading(_ entry: BloodSugarEntry) async throws {
        try await supabase
            .from("blood_sugar_entries")
            .insert(entry)
            .execute()
    }

    func fetchBSReadings(for dateIso: String) async throws -> [BloodSugarEntry] {
        let response = try await supabase
            .from("blood_sugar_entries")
            .select()
            .eq("date_iso", value: dateIso)
            .order("recorded_at", ascending: true)
            .execute()
        return try response.value
    }

    func fetchBSReadings(from startDate: String, to endDate: String) async throws -> [BloodSugarEntry] {
        let response = try await supabase
            .from("blood_sugar_entries")
            .select()
            .gte("date_iso", value: startDate)
            .lte("date_iso", value: endDate)
            .order("recorded_at", ascending: true)
            .execute()
        return try response.value
    }

    func deleteBSReading(id: UUID) async throws {
        try await supabase
            .from("blood_sugar_entries")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Symptomen

    func saveSymptomEntry(_ entry: SymptomEntry) async throws {
        try await supabase
            .from("symptom_entries")
            .insert(entry)
            .execute()
    }

    func fetchSymptomEntries(for dateIso: String) async throws -> [SymptomEntry] {
        let response = try await supabase
            .from("symptom_entries")
            .select()
            .eq("date_iso", value: dateIso)
            .order("recorded_at", ascending: true)
            .execute()
        return try response.value
    }

    // MARK: - Correlaties (lokale berekening)

    func calculateWeeklyInsights(
        bsReadings: [BloodSugarEntry],
        meals: [DiaryEntry],         // bestaand model
        stepCounts: [String: Int]    // dateIso → stappen
    ) -> WeeklyInsight {

        // GI-drempels: hoog GI = >70, laag GI = ≤55
        let highGIMeals = meals.filter { ($0.glycemicIndex ?? 0) > 70 }
        let lowGIMeals = meals.filter { ($0.glycemicIndex ?? 100) <= 55 }

        // BS stijging 1-3 uur na hoog-GI maaltijd
        let bsAfterHighGI = bsChangesAfterMeals(meals: highGIMeals, bsReadings: bsReadings)
        let bsAfterLowGI = bsChangesAfterMeals(meals: lowGIMeals, bsReadings: bsReadings)

        // BS op actieve vs. rustige dagen
        let activeDates = stepCounts.filter { $0.value > 8000 }.map { $0.key }
        let quietDates = stepCounts.filter { $0.value < 5000 }.map { $0.key }

        let bsActiveDay = bsReadings.filter { activeDates.contains($0.dateIso) }.map { $0.valueMmol }
        let bsQuietDay = bsReadings.filter { quietDates.contains($0.dateIso) }.map { $0.valueMmol }

        return WeeklyInsight(
            avgBSAfterHighGI: bsAfterHighGI.average(),
            avgBSAfterLowGI: bsAfterLowGI.average(),
            avgBSHighActivity: bsActiveDay.average(),
            avgBSLowActivity: bsQuietDay.average(),
            avgDailyBS: bsReadings.map { $0.valueMmol }.average(),
            dataPoints: bsReadings.count
        )
    }

    private func bsChangesAfterMeals(
        meals: [DiaryEntry],
        bsReadings: [BloodSugarEntry],
        windowHours: Double = 3.0
    ) -> [Double] {
        var changes: [Double] = []

        for meal in meals {
            guard let mealTime = meal.loggedAt else { continue }  // gebruik bestaand timestamp veld

            let windowEnd = mealTime.addingTimeInterval(windowHours * 3600)
            let bsInWindow = bsReadings.filter {
                $0.recordedAt > mealTime && $0.recordedAt <= windowEnd
            }

            // BS vlak vóór de maaltijd als baseline (±30 min)
            let baselineWindow = mealTime.addingTimeInterval(-1800)
            let baseline = bsReadings
                .filter { $0.recordedAt >= baselineWindow && $0.recordedAt <= mealTime }
                .map { $0.valueMmol }
                .average()

            if let baseline = baseline, let peakBS = bsInWindow.map({ $0.valueMmol }).max() {
                changes.append(peakBS - baseline)
            }
        }
        return changes
    }
}

// MARK: - Helper
extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
```

---

## Barcode Scanner Uitbreiding: GI & Koolhydraten

In het bestaande `FoodScannerViewModel` (of gelijkwaardig), **voeg toe aan de Open Food Facts parser**:

```swift
// In de functie die Open Food Facts JSON verwerkt:

struct FoodNutrition {
    var proteinGrams: Double?
    var carbsGrams: Double?
    var fiberGrams: Double?
    var fatGrams: Double?
    var glycemicIndex: Int?    // Open Food Facts bevat dit soms als "glycemic_index_100g"
    var glycemicLoad: Double?  // Berekend: (GI × KH) / 100

    // Bereken GL lokaal als GI beschikbaar is:
    mutating func calculateGlycemicLoad() {
        if let gi = glycemicIndex, let carbs = carbsGrams {
            glycemicLoad = (Double(gi) * carbs) / 100.0
        }
    }

    // GI categorie voor UI
    var glycemicCategory: GICategory {
        guard let gi = glycemicIndex else { return .unknown }
        switch gi {
        case 0...55: return .low
        case 56...70: return .medium
        default: return .high
        }
    }
}

enum GICategory {
    case low, medium, high, unknown

    var label: String {
        switch self {
        case .low: return "Laag GI"
        case .medium: return "Medium GI"
        case .high: return "Hoog GI"
        case .unknown: return "GI onbekend"
        }
    }

    var color: String {  // gebruik in SwiftUI als Color(hex:)
        switch self {
        case .low: return "#4CAF50"      // groen
        case .medium: return "#FF9800"   // oranje
        case .high: return "#F44336"     // rood
        case .unknown: return "#9E9E9E"  // grijs
        }
    }

    var emoji: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟠"
        case .high: return "🔴"
        case .unknown: return "⚪️"
        }
    }
}

// JSON parsing toevoeging (in bestaande Open Food Facts parser):
// let gi = product["glycemic_index_100g"] as? Int
// let carbs = nutriments["carbohydrates_100g"] as? Double
// let fiber = nutriments["fiber_100g"] as? Double
// let fat = nutriments["fat_100g"] as? Double
```

---

## Nieuwe Schermen (SwiftUI Views)

### 1. `BloodSugarLogView.swift` — BS opnemen

```swift
// Functionaliteit:
// - Numeriek invoerveld voor mmol/L waarde
// - Picker voor moment (nuchter, voor eten, na eten, nacht, zomaar)
// - Optioneel notitieveld
// - Opslaan-knop
// - Lijst van vandaag's metingen onderaan

// UI richtlijnen:
// - Grote, duidelijke invoer (iemand die net gemeten heeft wil snel opslaan)
// - Toon huidige tijd als default
// - Bevestiging: "Opgeslagen ✓" als subtle feedback (geen modal)
// - Swipe to delete op eerdere entries van vandaag

struct BloodSugarLogView: View {
    @StateObject private var healthService = HealthService()
    @State private var valueText = ""
    @State private var selectedMoment: BSMoment = .willekeurig
    @State private var note = ""
    @State private var todaysReadings: [BloodSugarEntry] = []
    @State private var isSaved = false

    var body: some View {
        // Implementeer UI hier
        // Zie UX-richtlijnen hieronder
    }
}

// UX-richtlijnen:
// Titel: "Bloedsuiker opnemen"
// Invoerveld label: "Waarde (mmol/L)"
// Placeholder: "bijv. 7.2"
// Picker label: "Moment"
// Notitie placeholder: "Optioneel – hoe voel je je?"
// Knop: "Opslaan"
// Bevestiging: "Opgeslagen om [tijd]" (groen, verdwijnt na 2 seconden)
// Lege staat: "Nog geen metingen vandaag"
```

### 2. `SymptomLogView.swift` — Gevoel vastleggen

```swift
// Functionaliteit:
// - Drie sliders of emoji-knoppen: energie, focus, honger (1–5)
// - Vrij notitieveld
// - Opslaan
// - Korte lijst van eerdere entries vandaag

// UX-richtlijnen:
// Titel: "Hoe voel je je?"
// Energie label: "Energie" — emoji: 😴 → ⚡️
// Focus label: "Focus" — emoji: 🌫 → 🎯
// Honger label: "Honger" — emoji: 🙂 → 🐺
// Notitie placeholder: "Iets bijzonders vandaag?"
// Knop: "Vastleggen"
// Lege staat: "Nog niets vastgelegd vandaag"

// Gebruik een 5-punt emoji-selector, geen nummers tonen aan gebruiker
```

### 3. `DayTimelineView.swift` — Dagoverzicht

```swift
// Functionaliteit:
// - Alle events van één dag op tijdlijn
// - Maaltijden (met GI-kleur), BS-metingen, symptomen, water, stappen
// - Navigatie naar andere dagen (swipe of pijltjes)
// - Tap op event → detail/correctie

// Data structuur voor tijdlijn:
enum TimelineEvent: Identifiable {
    case meal(DiaryEntry)
    case bloodSugar(BloodSugarEntry)
    case symptom(SymptomEntry)
    case water(WaterEntry)       // bestaand model

    var id: UUID { ... }         // geef elk type een UUID
    var timestamp: Date { ... }  // voor sortering
    var icon: String { ... }     // emoji icon per type
    var title: String { ... }    // korte omschrijving
    var subtitle: String { ... } // details
    var color: Color { ... }     // kleur per type
}

// Sortering: op timestamp, oudste eerst
// Weergave: verticale lijst, tijdstempel links, content rechts
// Maaltijden tonen GI-badge: 🟢 Laag GI / 🔴 Hoog GI
// BS-metingen tonen waarde in groot lettertype
// Geen data: "Nog niets gelogd op [datum]"

// UX-richtlijnen:
// Navigatiebalk: "[←] [datum] [→]"  
// Datum notatie: "Vandaag", "Gisteren", of "ma 3 juni"
// Floating button: "+" om snel iets toe te voegen (BS / maaltijd / gevoel)
```

### 4. `WeeklyInsightsView.swift` — Jouw inzichten

```swift
// Functionaliteit:
// - Wekelijkse statistieken uit WeeklyInsight model
// - Visuele vergelijking hoog GI vs laag GI impact
// - Activiteit vs BS correlatie
// - Gemiddeld BS deze week
// - Alleen tonen als voldoende data (minimaal 5 BS-metingen)

// UI opbouw:
// Sectie 1: "Bloedsuiker deze week"
//   → Gemiddelde: 7.1 mmol/L
//   → Min / Max range
//   → Aantal metingen

// Sectie 2: "GI impact"
//   → Hoog GI: gemiddeld +[X] stijging
//   → Laag GI: gemiddeld +[X] stijging
//   → Alleen tonen als beide groepen ≥ 3 datapunten hebben

// Sectie 3: "Activiteit effect"
//   → Actieve dagen: gemiddeld [X] mmol/L
//   → Rustige dagen: gemiddeld [X] mmol/L
//   → Alleen tonen als stap-data beschikbaar via HealthKit

// Sectie 4: "Koolhydraten"
//   → Gemiddeld per dag: [X] gram KH
//   → Verdeling hoog/laag GI (eenvoudige balk)

// Lege staat: "Voeg meer metingen toe voor inzichten"
// Minimum data: grijze kaart met uitleg waarom nog niet genoeg data

// UX-richtlijnen:
// Geen waarschuwingen, geen adviezen — alleen feiten
// Nooit: "Je moet minder hoog-GI eten" 
// Wel: "Na hoog GI-maaltijden steeg je BS gemiddeld 2.3 punten"
// Kopje: "Jouw inzichten" (persoonlijk, niet klinisch)
```

---

## Navigatie & Tab Structure

Voeg toe aan de bestaande tab-structuur:

```swift
// Optie A: Nieuwe tab "Inzichten"
TabView {
    HomeView()              // bestaand – ringen, quick-add
        .tabItem { Label("Vandaag", systemImage: "circle.grid.2x2") }

    DayTimelineView()       // nieuw
        .tabItem { Label("Dag", systemImage: "list.bullet.rectangle") }

    WeeklyInsightsView()    // nieuw
        .tabItem { Label("Inzichten", systemImage: "chart.line.uptrend.xyaxis") }

    ProfileView()           // bestaand
        .tabItem { Label("Profiel", systemImage: "person") }
}

// Optie B: Vanuit HomeView bereikbaar
// HomeView → "+" knop → sheet met keuze: Maaltijd / Bloedsuiker / Gevoel
// HomeView → "Dag bekijken" knop → DayTimelineView
// HomeView → "Inzichten" knop → WeeklyInsightsView
```

> **Aanbeveling:** Kies Optie A (aparte tabs) als de app primair dagelijks gebruikt wordt. Kies Optie B als je de HomeView centraal wilt houden en de app simpel wilt houden.

---

## HealthKit Uitbreiding

Uitbreiding op bestaande stappen-integratie (al in app via `BGTaskSchedulerPermittedIdentifiers`):

```swift
// In bestaande HealthKitManager (of gelijkwaardig):

// Al aanwezig: stappen ophalen
// Toevoegen: actieve calorieën (optioneel, voor activiteitsniveau)

func fetchStepCount(for dateIso: String) async -> Int {
    // Bestaande implementatie — hergebruiken
}

// Nieuw: Stappen voor een range van dagen (voor weekoverzicht)
func fetchStepCounts(from startDate: Date, to endDate: Date) async -> [String: Int] {
    // Geeft dictionary terug: ["2024-06-03": 6543, "2024-06-04": 9012, ...]
    // Gebruik HKStatisticsCollectionQuery voor efficiënte bulk fetch
    // dateIso format: "yyyy-MM-dd" (consistent met Supabase schema)
}
```

---

## Implementatievolgorde (sprint-plan)

### Sprint 1 — Bloedsuiker logger (1–2 dagen)
1. `blood_sugar_entries` tabel aanmaken in Supabase
2. `BloodSugarEntry` model + `CodingKeys` in `HealthModels.swift`
3. `HealthService.swift` met save/fetch/delete BS
4. `BloodSugarLogView.swift` — invoer + daglijst
5. Bereikbaar maken vanuit HomeView via "+" knop of nieuwe tab

**Testpunt:** Meting opslaan, lijst vernieuwen, swipe to delete.

### Sprint 2 — GI & koolhydraten in scanner (1–2 dagen)
1. `FoodNutrition` uitbreiding met carbs, fiber, fat, GI, GL
2. Open Food Facts JSON parser uitbreiden
3. GI-badge tonen in scan-resultaat scherm (`🟢 Laag GI`)
4. Nieuwe velden opslaan in `diary_entries`
5. GI-info tonen in dagelijks voedingsoverzicht

**Testpunt:** Scan een product, zie GI-badge, controleer Supabase of data klopt.

### Sprint 3 — Symptoom-tracking (1 dag)
1. `symptom_entries` tabel aanmaken in Supabase
2. `SymptomEntry` model
3. `SymptomLogView.swift` — emoji-slider + notitie
4. Bereikbaar via "+" knop

**Testpunt:** Gevoel vastleggen, terugzien in tijdlijn.

### Sprint 4 — Timeline & overzicht (2–3 dagen)
1. `TimelineEvent` enum die alle data-types samenvoegt
2. `DayTimelineView.swift` — gesorteerde lijst met dag-navigatie
3. GI-kleur tonen bij maaltijden
4. BS-metingen prominenter tonen

**Testpunt:** Dag bekijken met maaltijden + BS-metingen door elkaar.

### Sprint 5 — Wekelijkse inzichten (2–3 dagen)
1. Correlatie-berekening in `HealthService.calculateWeeklyInsights()`
2. Bulk stappen-data ophalen via HealthKit
3. `WeeklyInsightsView.swift` — statistieken per sectie
4. Minimale data-drempel inbouwen (geen lege grafieken tonen)

**Testpunt:** Na 5+ BS-metingen en 3+ maaltijden zichtbare inzichten.

---

## Valkuilen & aandachtspunten

| Punt | Risico | Oplossing |
|------|--------|-----------|
| `date_iso` format | Inconsistentie in datum-strings | Altijd `"yyyy-MM-dd"` via `DateFormatter` met `locale: Locale(identifier: "en_US_POSIX")` |
| GI-data in Open Food Facts | Niet altijd beschikbaar | UI toont `⚪️ GI onbekend` zonder crash |
| Correlatie met weinig data | Misleidende statistieken | Minimaal 3 datapunten per categorie, anders niet tonen |
| Medische aansprakelijkheid | App doet aan "advies" | Geen aanbevelingen, alleen feitelijke observaties. Geen klinische taal. |
| Performantie timeline | Veel data tegelijk laden | Fetch per dag, niet heel de history in één keer |
| Supabase RLS | Nieuwe tabellen zonder RLS | RLS aanmaken bij elke nieuwe tabel (zie SQL hierboven) |
| Simulator cache | Oude data bij testen | `Device → Erase All Content and Settings` + `⇧⌘K Clean Build` |

---

## Teksten voor UI (Nederlands, menselijk)

| Situatie | Tekst |
|----------|-------|
| Bloedsuiker opnemen knop | "BS opnemen" |
| Bevestiging opgeslagen | "Opgeslagen ✓" |
| Lege BS lijst | "Nog geen metingen vandaag" |
| Geen GI beschikbaar | "GI niet bekend voor dit product" |
| Inzichten onvoldoende data | "Voeg meer metingen toe voor inzichten. Je hebt [X] van de 5 benodigde metingen." |
| Gevoel knop | "Hoe voel ik me?" |
| Tijdlijn leeg | "Niets gelogd op [datum]" |
| GI laag | "🟢 Laag GI – stabiel" |
| GI hoog | "🔴 Hoog GI – let op" |
| Inzicht GI | "Na hoog-GI eten steeg je BS gemiddeld [X] punten" |
| Inzicht activiteit | "Op actieve dagen was je BS gemiddeld [X] lager" |

---

## Bestandsstructuur na implementatie

```
Piccopalo/
├── Models/
│   ├── HealthModels.swift          ← nieuw
│   ├── DiaryEntry.swift            ← uitgebreid met GI-velden
│   └── ... (bestaand)
├── Services/
│   ├── HealthService.swift         ← nieuw
│   ├── SupabaseManager.swift       ← bestaand
│   └── ... (bestaand)
├── Views/
│   ├── BloodSugarLogView.swift     ← nieuw
│   ├── SymptomLogView.swift        ← nieuw
│   ├── DayTimelineView.swift       ← nieuw
│   ├── WeeklyInsightsView.swift    ← nieuw
│   ├── HomeView.swift              ← kleine aanpassing (+ knop)
│   └── ... (bestaand)
└── ... (bestaand)
```

---

*Plan versie 1.0 — gegenereerd voor Piccopalo iOS (SwiftUI + Supabase)*
*Aanpassen indien bestaande bestandsnamen of modelnamen afwijken.*
