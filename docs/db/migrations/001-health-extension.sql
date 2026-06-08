-- Piccopalo migratie 001 — Health uitbreiding
-- Bron: docs/plans/Health Uitbreiding: Bloedsuiker, GI & Correlaties.md
-- Vereist: basis-schema (docs/db/schema/)
-- Idempotent: veilig opnieuw uitvoeren
--
-- Dekt drie app-features:
--   1. Bloedsuiker loggen   -> SupabaseBloodSugarRepository.swift
--   2. Gevoel / symptomen   -> SupabaseSymptomRepository.swift
--   3. GI via barcode scan  -> diary_entries kolommen (DiaryRepository.swift)

-- =====================================================================
-- 1. blood_sugar_entries  (feature: bloedsuiker loggen)
-- =====================================================================
create table if not exists public.blood_sugar_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  date_iso text not null,            -- "yyyy-MM-dd", consistent met diary
  recorded_at timestamptz not null,  -- exacte tijd van meting
  value_mmol double precision not null,
  moment text,                       -- nuchter | voor_eten | na_eten | nacht | willekeurig
  note text,
  created_at timestamptz default now()
);

alter table public.blood_sugar_entries enable row level security;

drop policy if exists "Eigen data" on public.blood_sugar_entries;
create policy "Eigen data" on public.blood_sugar_entries
  for all using (auth.uid() = user_id);

create index if not exists blood_sugar_entries_user_date_idx
  on public.blood_sugar_entries (user_id, date_iso);

-- =====================================================================
-- 2. symptom_entries  (feature: gevoel / symptomen)
-- =====================================================================
create table if not exists public.symptom_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  date_iso text not null,
  recorded_at timestamptz not null,
  energy_level int check (energy_level between 1 and 5),  -- 1=uitgeput, 5=top
  focus_level int check (focus_level between 1 and 5),
  hunger_level int check (hunger_level between 1 and 5),
  note text,
  created_at timestamptz default now()
);

alter table public.symptom_entries enable row level security;

drop policy if exists "Eigen data" on public.symptom_entries;
create policy "Eigen data" on public.symptom_entries
  for all using (auth.uid() = user_id);

create index if not exists symptom_entries_user_date_idx
  on public.symptom_entries (user_id, date_iso);

-- =====================================================================
-- 3. diary_entries — glycemische / voedingsdata (feature: GI via scan)
--    Nullable kolommen, zodat bestaande entries niet breken.
-- =====================================================================
alter table public.diary_entries
  add column if not exists carbs_grams double precision,    -- koolhydraten (g)
  add column if not exists fiber_grams double precision,     -- vezels (g)
  add column if not exists fat_grams double precision,       -- vetten (g)
  add column if not exists glycemic_index int,               -- GI (0-100)
  add column if not exists glycemic_load double precision;   -- GL = (GI x KH) / 100

-- =====================================================================
-- Verificatie (optioneel) — uncomment en run in Supabase SQL Editor
-- =====================================================================
-- select table_name from information_schema.tables
--   where table_schema = 'public'
--     and table_name in ('blood_sugar_entries', 'symptom_entries');
--
-- select column_name from information_schema.columns
--   where table_schema = 'public'
--     and table_name = 'diary_entries'
--     and column_name in ('carbs_grams', 'fiber_grams', 'fat_grams',
--                          'glycemic_index', 'glycemic_load');
