-- Piccopalo — basisschema: diary_days
-- Status: productie (bestaand in Supabase)
-- Eén rij per gebruiker per kalenderdag (eiwitdoel + totaal)

create table if not exists public.diary_days (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  date_iso text not null,
  weight double precision not null default 0,
  activity_factor double precision not null default 1.2,
  protein_goal double precision not null default 0,
  protein_consumed double precision not null default 0,
  constraint diary_days_pkey primary key (id),
  constraint diary_days_user_id_date_iso_key unique (user_id, date_iso),
  constraint diary_days_user_id_fkey foreign key (user_id) references auth.users (id)
) tablespace pg_default;
