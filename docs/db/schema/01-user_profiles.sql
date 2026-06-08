-- Piccopalo — basisschema: user_profiles
-- Status: productie (bestaand in Supabase)
-- Eén profiel per gebruiker; primary key = auth.users.id

create table if not exists public.user_profiles (
  id uuid not null,
  name text not null default ''::text,
  weight double precision not null default 0,
  height double precision not null default 0,
  activity_factor double precision not null default 1.2,
  updated_at timestamp with time zone null default now(),
  constraint user_profiles_pkey primary key (id),
  constraint user_profiles_id_fkey foreign key (id) references auth.users (id)
) tablespace pg_default;
