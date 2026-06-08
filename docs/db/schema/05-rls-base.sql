-- Piccopalo — RLS voor basis-tabellen
-- Status: aanbevolen bij nieuwe omgeving (draai na 01–04)
-- Op bestaand project: policies zijn idempotent (drop + create)

-- user_profiles (pk = auth user id)
alter table public.user_profiles enable row level security;

drop policy if exists "Eigen profiel" on public.user_profiles;
create policy "Eigen profiel" on public.user_profiles
  for all using (auth.uid() = id);

-- diary_days
alter table public.diary_days enable row level security;

drop policy if exists "Eigen data" on public.diary_days;
create policy "Eigen data" on public.diary_days
  for all using (auth.uid() = user_id);

-- diary_entries
alter table public.diary_entries enable row level security;

drop policy if exists "Eigen data" on public.diary_entries;
create policy "Eigen data" on public.diary_entries
  for all using (auth.uid() = user_id);

-- water_entries
alter table public.water_entries enable row level security;

drop policy if exists "Eigen data" on public.water_entries;
create policy "Eigen data" on public.water_entries
  for all using (auth.uid() = user_id);
