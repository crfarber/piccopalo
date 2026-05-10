# Piccopalo User Stories

This document maps product intent to implementation work using Epic -> Story -> Task.

Status legend:
- Implemented
- Partial
- Planned

## Epic 1: Account and Goal Foundation

### Story 1.1 (Implemented)
As a user,
I want to set my profile values,
so that the app can calculate my daily protein goal.

Tasks:
1. Maintain profile fields (name, weight, height, activity factor) in account view model.
2. Persist profile through UserProfileRepositoryProtocol.
3. Notify dependent screens when profile changes.
4. Display updated goal values in user-facing screens.

### Story 1.2 (Partial)
As a user,
I want account defaults to influence new day calculations,
so that each day starts with the correct baseline target.

Tasks:
1. Apply account defaults when creating/loading today context.
2. Keep per-day overrides independent from global profile changes.
3. Document expected behavior for first log vs existing day.

## Epic 2: Daily Protein Logging

### Story 2.1 (Implemented)
As a user,
I want to manually add or subtract protein grams,
so that I can quickly track intake.

Tasks:
1. Validate decimal input on Today screen.
2. Apply positive delta for add and negative delta for subtract.
3. Prevent total consumed from dropping below zero.
4. Persist updated day total immediately.

### Story 2.2 (Implemented)
As a user,
I want instant progress feedback,
so that I know how close I am to my goal.

Tasks:
1. Recalculate consumed, remaining, and percentage after each update.
2. Cap percentage display at 100.
3. Update progress visuals and motivational message.

## Epic 3: Food Source Quantity Calculator

### Story 3.1 (Implemented)
As a user,
I want to select a food source and enter consumed quantity,
so that the app calculates protein grams for me.

Tasks:
1. Keep a source list with nutrition per 100 unit metadata.
2. Support strict source unit metadata (g or ml).
3. Show quantity input in source-specific unit.
4. Compute protein with formula quantity/100 x proteinPer100Unit.
5. Add computed grams into today totals.

### Story 3.2 (Partial)
As a user,
I want the picker flow to be clear and error-resistant,
so that I do not need to calculate anything manually.

Tasks:
1. Show selected source and nutrition context clearly.
2. Validate quantity input and disable submit for invalid values.
3. Show computed protein preview before submit.
4. Keep naming/copy consistent across Today and picker screens.

## Epic 4: History and Day Correction

### Story 4.1 (Implemented)
As a user,
I want to see my historical daily progress,
so that I can review consistency over time.

Tasks:
1. Load day records sorted by date.
2. Show goal, consumed grams, and percentage per day.
3. Support navigation to day detail.

### Story 4.2 (Implemented)
As a user,
I want to manually correct one day,
so that occasional logging mistakes can be fixed.

Tasks:
1. Allow consumed grams edit in day detail.
2. Save corrected value for that day only.
3. Refresh current day state if edited date is today.

## Epic 5: Persistence Reliability and Migration

### Story 5.1 (Implemented)
As a user,
I want my data to survive app restarts,
so that tracking is reliable.

Tasks:
1. Persist profile and day data in .
2. Keep repositories as data-access boundary.
3. Use one shared ModelContainer for app runtime.

### Story 5.2 (Implemented)
As a user upgrading from older builds,
I want my previous data preserved,
so that I do not lose history.

Tasks:
1. Import legacy UserDefaults account and diary payload once.
2. Set migration flag to avoid duplicate imports.
3. Preserve behavior when  is already populated.

## Traceability
Reference docs:
- [App functionality](app-functionality.md)
- [Database architecture](db/database.md)
- [Diary domain](db/diary.md)
- [User domain](db/user.md)

Primary implementation areas:
- Piccopalo/DB/
- Piccopalo/Domains/Account/
- Piccopalo/Domains/Diary/
- Piccopalo/Domains/ProteinMeter/
