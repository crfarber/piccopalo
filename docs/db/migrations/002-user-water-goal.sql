-- Piccopalo migratie 002 — waterdoel op profiel
-- De app leest/schrijft water_goal_ml (optioneel, default 2000 ml in de app).
-- Draai na 001 als de kolom water_goal_ml nog niet in user_profiles staat.
-- Idempotent: veilig opnieuw uitvoeren.

alter table public.user_profiles
  add column if not exists water_goal_ml integer default 2000;

-- Verificatie (optioneel):
-- select column_name from information_schema.columns
--   where table_schema = 'public'
--     and table_name = 'user_profiles'
--     and column_name = 'water_goal_ml';
