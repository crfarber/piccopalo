# Piccopalo v0.2 (iOS)

Piccopalo is een iOS app voor dagelijkse eiwittracking met automatische activiteitsinschatting op basis van HealthKit, barcode-scanning voor producten en cloud-opslag via Supabase.

## Wat is nieuw in deze versie

De app is uitgebreid van lokale eiwittracker naar een account-gebonden app met cloud data en health-integratie.

Nieuwe of sterk uitgebreide onderdelen:
- Authenticatie (inloggen, registreren, uitloggen) met Supabase Auth.
- Cloud persistence via Supabase tabellen voor profiel, dagtotalen en individuele entries.
- Barcode scanner (EAN13/UPC) met productlookup via Open Food Facts.
- HealthKit-koppeling (stappen, actieve energie, oefentijd, afstand, trappen).
- Dynamische activiteitsfactor uit 7-daags model (week 70%, vandaag 30%).
- Lokale notificaties en background checks voor stappen-doelen (13:00 reminder + drempels).
- Verbeterde history/dagdetail met lijst van losse innames en verwijderen van entries.

## Belangrijkste features

## 1) Login en account
- E-mail/wachtwoord login en signup.
- Tabbar is alleen zichtbaar voor ingelogde gebruikers.
- Account bevat naam, gewicht, lengte en activiteitsniveau.
- Uitloggen vanuit accountscherm.

## 2) Protein tracking (Today)
- Handmatig eiwit toevoegen.
- Eiwit toevoegen via vaste voedingslijst met berekening op hoeveelheid.
- Eiwit toevoegen via barcode scan en automatische productdata.
- Live statistieken: gegeten, doel, nog te gaan, percentage.

Rekenregels:
- Dagdoel (g) = gewicht (kg) x activiteitsfactor.
- Percentage = min((gegeten / doel) x 100, 100).
- Nog te gaan = max(doel - gegeten, 0).

## 3) Barcode + Open Food Facts
- Camera scanner ondersteunt EAN13 en UPC.
- Product lookup via Open Food Facts API.
- Portie invoeren en automatisch eiwit berekenen.
- Heldere foutafhandeling (niet gevonden, geen eiwitdata, timeout, netwerk).
- Fallback naar handmatige invoer wanneer nodig.

## 4) History en dagdetail
- Overzicht van eerdere dagen, gesorteerd op datum.
- 7-daagse strip met voortgang per dag.
- Dagdetail toont resultaat, doel, activiteit en innames.
- Handmatige correctie per dag.
- Losse innames verwijderen met automatische herberekening van totaal.

## 5) HealthKit en activiteit
- Leest vandaag en weekgemiddelde voor:
  - stappen
  - actieve energie
  - oefentijd
  - afstand
  - verdiepingen
- Berekent activiteitsfactor (0.8 / 1.2 / 1.4 / 1.6) uit gecombineerde activiteitsscore.
- Health details-scherm toont advies en laat gebruiker factor overnemen in account.
- Background observers verversen healthdata bij updates.

## 6) Notificaties
- Dagelijkse herinnering rond 13:00 op basis van stapvoortgang.
- Drempelnotificaties op 80%, 95% en 100% van stappendoel.
- Background task scheduling voor periodieke step checks.

## Architectuur

- UI: SwiftUI.
- State: ObservableObject viewmodels met environment objects.
- Auth + backend: Supabase.
- Device data: HealthKit, UserNotifications, BackgroundTasks, AVFoundation.

Belangrijke componenten:
- App root en dependency wiring in Piccopalo/PiccopaloApp.swift.
- Auth flow in Piccopalo/Auth/.
- Protein domain in Piccopalo/Domains/ProteinMeter/.
- History domain in Piccopalo/Domains/Diary/.
- Account domain in Piccopalo/Domains/Account/.
- Health integratie in Piccopalo/Health/.
- Externe services in Piccopalo/Services/.

## Data en opslag

Supabase repositories:
- SupabaseUserProfileRepository: profieldata.
- SupabaseDiaryRepository: dagrecords en entries.

Dagrecord bevat onder andere:
- date
- weight
- activityFactor
- proteinGoal
- proteinConsumed
- entries[]

## Productstatus

Geimplementeerd:
- Auth gate + accountbeheer.
- Cloud-synchronisatie van profiel en dagdata.
- Handmatig loggen, voedingslijst en barcodeflow.
- History met detail en correcties.
- HealthKit metrics en activiteitssuggestie.
- Notificaties en background monitoring voor stappen.

In code aanwezig maar nog niet in hoofdflow:
- Onboarding views onder Piccopalo/Domains/Account/Onboarding/.

## Vereisten

- iOS project met SwiftUI.
- Health permissies voor gezondheidsfeatures.
- Camera permissie voor barcode scanner.
- Internetverbinding voor Open Food Facts en Supabase.

## Documentatie

- Overzicht functionaliteit: docs/app-functionality.md
- User stories: docs/user-stories.md
- Datamodel: docs/db/
