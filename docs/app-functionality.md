# Piccopalo App Functionality

## Purpose
Piccopalo helps users track daily protein intake against a daily goal.

The app combines:
- Profile-driven goal calculation (weight x activity factor)
- Daily intake logging
- Day-level history and correction
- Local persistence through SwiftData

## Main Navigation
The app has three tabs:
1. Today
2. History
3. Account

## Core Functional Flows

### Flow 1: Set or update account profile
User action:
- User opens Account and edits name, weight, height, or activity factor.

App behavior:
- Changes are saved through AccountViewModel to UserProfileRepositoryProtocol.
- A profile-change notification is emitted so dependent screens can refresh calculations.

Persistence:
- UserProfileEntity is upserted in SwiftData (single active profile strategy).

User-visible result:
- Updated goal calculations are reflected in Today and related views.

### Flow 2: Log protein from manual gram input
User action:
- User enters grams directly on Today and taps add/subtract.

App behavior:
- ProteinViewModel validates input and applies delta to the current day record.
- Goal is based on current account weight and activity factor logic.

Persistence:
- DayRecord is created or updated for today via DiaryRepositoryProtocol.

User-visible result:
- Progress percentage, remaining grams, and chart update immediately.

### Flow 3: Log protein from food source picker
User action:
- User opens food picker, selects a source, enters consumed quantity.

App behavior:
- App calculates protein grams from source nutrition metadata:
  - calculatedProtein = (quantity / 100) * proteinPer100Unit
- Quantity unit depends on source metadata (g or ml).

Persistence:
- Calculated grams are applied to today's day record and saved.

User-visible result:
- Today totals and progress reflect the calculated amount.

### Flow 4: Browse history and inspect day detail
User action:
- User opens History and taps a day.

App behavior:
- App loads sorted day records and presents a detail view for one date.

Persistence:
- Data is read from DiaryDayEntity records.

User-visible result:
- User sees goal, consumed grams, percentage, and status for that day.

### Flow 5: Correct a day manually
User action:
- User edits consumed grams in day detail and saves.

App behavior:
- App overwrites consumed grams for that day and recalculates derived UI values.

Persistence:
- Updated day record is saved through repository.

User-visible result:
- Day detail and related summaries reflect corrected values.

## Data Model and Persistence Overview

### User profile domain
Main fields:
- name
- weight
- height
- activityFactor

Role:
- Defines defaults for new day calculations.

### Diary domain
Main fields per day:
- date
- weight
- activityFactor
- proteinGoal
- proteinConsumed

Role:
- Stores day snapshots and totals used by Today, History, and Detail.

### Persistence layer
- SwiftData is the local source of truth.
- PersistenceController initializes ModelContainer and repositories.
- Legacy UserDefaults data is migrated once through SwiftDataMigration.

## Product Rules
1. Daily protein goal is weight x activityFactor.
2. Daily percentage is capped at 100 for display.
3. Remaining grams never goes below 0.
4. Existing day activity factor remains stable unless user edits that day.
5. Food picker input is quantity-based; protein grams are computed by the app.

## Known Product Boundaries
1. Data is local-first (no backend sync).
2. Profile is single-user on-device.
3. Historical day records can diverge from latest account settings by design.

## Traceability
Source references:
- [Database architecture](db/database.md)
- [Diary domain](db/diary.md)
- [User domain](db/user.md)
- [Project overview](../README.md)

Relevant implementation areas:
- Piccopalo/DB/
- Piccopalo/Domains/Account/
- Piccopalo/Domains/Diary/
- Piccopalo/Domains/ProteinMeter/
