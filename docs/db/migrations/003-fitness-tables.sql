-- Piccopalo migratie 003 — Fitness / krachttraining
-- Bron: docs/plans/Fitness Tracking (implementatieplan)
-- Vereist: basis-schema (docs/db/schema/)
-- Idempotent: veilig opnieuw uitvoeren
--
-- Dekt de fitness-feature:
--   1. exercises                   -> SupabaseExerciseRepository.swift
--   2. workout_templates           -> SupabaseWorkoutRepository.swift
--   3. workout_template_exercises  -> SupabaseWorkoutRepository.swift
--   4. workout_sessions            -> SupabaseWorkoutRepository.swift
--   5. workout_sets                -> SupabaseWorkoutRepository.swift
--
-- Seed met standaard-oefeningen staat apart: 003-fitness-seed.sql

-- =====================================================================
-- 1. exercises  (oefeningen-bibliotheek)
--    user_id is null  -> ingebouwde standaard-oefening (voor iedereen)
--    user_id gevuld   -> eigen oefening van die gebruiker
-- =====================================================================
create table if not exists public.exercises (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,  -- null = standaard
  name text not null,
  category text not null,            -- borst | rug | schouders | armen | benen | core
  is_custom boolean not null default false,
  created_at timestamptz default now()
);

alter table public.exercises enable row level security;

-- Lezen: standaard-oefeningen (user_id is null) + eigen oefeningen
drop policy if exists "Oefeningen lezen" on public.exercises;
create policy "Oefeningen lezen" on public.exercises
  for select using (user_id is null or auth.uid() = user_id);

-- Aanmaken: alleen eigen, custom oefeningen
drop policy if exists "Eigen oefening toevoegen" on public.exercises;
create policy "Eigen oefening toevoegen" on public.exercises
  for insert with check (auth.uid() = user_id and is_custom = true);

-- Bijwerken: alleen eigen, custom oefeningen
drop policy if exists "Eigen oefening bijwerken" on public.exercises;
create policy "Eigen oefening bijwerken" on public.exercises
  for update using (auth.uid() = user_id and is_custom = true);

-- Verwijderen: alleen eigen, custom oefeningen (standaard blijft altijd bestaan)
drop policy if exists "Eigen oefening verwijderen" on public.exercises;
create policy "Eigen oefening verwijderen" on public.exercises
  for delete using (auth.uid() = user_id and is_custom = true);

create index if not exists exercises_user_category_idx
  on public.exercises (user_id, category);

-- Voorkomt dubbele standaard-oefeningen bij opnieuw seeden.
create unique index if not exists exercises_default_name_unique
  on public.exercises (name, category)
  where user_id is null;

-- =====================================================================
-- 2. workout_templates  (trainingsschema's)
-- =====================================================================
create table if not exists public.workout_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,                -- bijv. "Push dag", "Beendag"
  day_of_week int,                   -- 1=maandag t/m 7=zondag, null=geen vaste dag
  created_at timestamptz default now()
);

alter table public.workout_templates enable row level security;

drop policy if exists "Eigen schema's" on public.workout_templates;
create policy "Eigen schema's" on public.workout_templates
  for all using (auth.uid() = user_id);

create index if not exists workout_templates_user_idx
  on public.workout_templates (user_id, day_of_week);

-- =====================================================================
-- 3. workout_template_exercises  (oefeningen binnen een schema)
-- =====================================================================
create table if not exists public.workout_template_exercises (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.workout_templates (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id) on delete cascade,
  sort_order int not null default 0,    -- volgorde in het schema
  target_sets int,                      -- geplande sets
  target_reps int,                      -- geplande reps
  target_weight_kg double precision,    -- gepland gewicht
  target_rest_seconds int default 90,   -- geplande rust in seconden
  created_at timestamptz default now()
);

alter table public.workout_template_exercises enable row level security;

drop policy if exists "Via template toegang" on public.workout_template_exercises;
create policy "Via template toegang" on public.workout_template_exercises
  for all using (
    exists (
      select 1 from public.workout_templates t
      where t.id = template_id and t.user_id = auth.uid()
    )
  );

create index if not exists workout_template_exercises_template_idx
  on public.workout_template_exercises (template_id, sort_order);

-- =====================================================================
-- 4. workout_sessions  (uitgevoerde trainingen)
--    template_id null  -> vrij gelogde sessie
-- =====================================================================
create table if not exists public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  date_iso text not null,            -- "yyyy-MM-dd", consistent met diary
  template_id uuid references public.workout_templates (id) on delete set null,
  started_at timestamptz,
  finished_at timestamptz,
  note text,
  created_at timestamptz default now()
);

alter table public.workout_sessions enable row level security;

drop policy if exists "Eigen sessies" on public.workout_sessions;
create policy "Eigen sessies" on public.workout_sessions
  for all using (auth.uid() = user_id);

create index if not exists workout_sessions_user_date_idx
  on public.workout_sessions (user_id, date_iso);

-- =====================================================================
-- 5. workout_sets  (gelogde sets per sessie)
-- =====================================================================
create table if not exists public.workout_sets (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.workout_sessions (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id) on delete cascade,
  set_number int not null,           -- 1, 2, 3...
  reps int,
  weight_kg double precision,
  rest_seconds int,
  note text,
  logged_at timestamptz default now()
);

alter table public.workout_sets enable row level security;

drop policy if exists "Via sessie toegang" on public.workout_sets;
create policy "Via sessie toegang" on public.workout_sets
  for all using (
    exists (
      select 1 from public.workout_sessions s
      where s.id = session_id and s.user_id = auth.uid()
    )
  );

create index if not exists workout_sets_session_idx
  on public.workout_sets (session_id, exercise_id, set_number);

-- Versnelt "vorige sessie" referentie: sets per oefening over alle sessies.
create index if not exists workout_sets_exercise_idx
  on public.workout_sets (exercise_id);

-- =====================================================================
-- Verificatie (optioneel) — uncomment en run in Supabase SQL Editor
-- =====================================================================
-- select table_name from information_schema.tables
--   where table_schema = 'public'
--     and table_name in ('exercises', 'workout_templates',
--                         'workout_template_exercises',
--                         'workout_sessions', 'workout_sets');
