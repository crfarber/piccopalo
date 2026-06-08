-- Piccopalo — basisschema: diary_entries
-- Status: productie (bestaand in Supabase)
-- Losse eiwit-innames per dag (handmatig, food picker, scan, …)

create table if not exists public.diary_entries (
  id uuid not null,
  user_id uuid not null,
  date_iso text not null,
  source_name text not null,
  quantity double precision not null,
  unit text not null,
  protein_per100 double precision not null,
  protein_amount double precision not null,
  created_at timestamp with time zone null default now(),
  constraint diary_entries_pkey primary key (id),
  constraint diary_entries_user_id_fkey foreign key (user_id) references auth.users (id)
) tablespace pg_default;
