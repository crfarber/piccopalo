-- Piccopalo migratie 004 — Exercise library import (free-exercise-db)
-- Vereist: 003-fitness-tables.sql
-- Idempotent: veilig opnieuw uitvoeren
--
-- Voegt kolommen toe voor imported oefeningen + RPC om standaard-oefeningen
-- te seeden vanuit de app (RLS staat directe client-insert niet toe).

-- =====================================================================
-- 1. Schema-uitbreiding exercises
-- =====================================================================
alter table public.exercises
  add column if not exists level text,
  add column if not exists instructions text,
  add column if not exists thumbnail_path text,
  add column if not exists source_id text;

-- Dedup op free-exercise-db id
create unique index if not exists exercises_source_id_unique
  on public.exercises (source_id)
  where user_id is null and source_id is not null;

-- =====================================================================
-- 2. RPC: seed_standard_exercises
--    SECURITY DEFINER — bypass RLS voor standaard-oefeningen import
-- =====================================================================
create or replace function public.seed_standard_exercises(
  batch jsonb,
  replace_all boolean default false
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_count integer := 0;
begin
  if replace_all then
    delete from public.exercises
    where user_id is null and is_custom = false;
  end if;

  insert into public.exercises (
    user_id,
    name,
    category,
    is_custom,
    level,
    instructions,
    thumbnail_path,
    source_id
  )
  select
    null,
    item->>'name',
    item->>'category',
    false,
    item->>'level',
    item->>'instructions',
    item->>'thumbnail_path',
    item->>'source_id'
  from jsonb_array_elements(batch) as item
  where item->>'name' is not null
    and item->>'category' is not null
    and item->>'source_id' is not null
  on conflict (source_id) where (user_id is null and source_id is not null) do nothing;

  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;

revoke all on function public.seed_standard_exercises(jsonb, boolean) from public;
grant execute on function public.seed_standard_exercises(jsonb, boolean) to authenticated;

-- =====================================================================
-- Verificatie (optioneel)
-- =====================================================================
-- select column_name from information_schema.columns
--   where table_schema = 'public' and table_name = 'exercises'
--     and column_name in ('level', 'instructions', 'thumbnail_path', 'source_id');
--
-- select proname from pg_proc
--   where proname = 'seed_standard_exercises';
