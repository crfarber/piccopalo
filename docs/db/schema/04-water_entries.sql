-- Piccopalo — basisschema: water_entries
-- Status: productie (bestaand in Supabase)
-- Losse water-innames per dag (ml); totaal wordt in de app opgeteld

create table if not exists public.water_entries (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  date_iso text not null,
  milliliters integer not null,
  created_at timestamp with time zone null default now(),
  constraint water_entries_pkey primary key (id),
  constraint water_entries_user_id_fkey foreign key (user_id) references auth.users (id) on delete cascade
) tablespace pg_default;
