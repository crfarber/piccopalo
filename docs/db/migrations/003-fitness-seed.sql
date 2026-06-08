-- Piccopalo migratie 003 — seed: standaard-oefeningen
-- Vereist: 003-fitness-tables.sql (tabel exercises + unieke index op default-namen)
-- Idempotent: `on conflict do nothing` op de unieke index voor standaard-oefeningen
--
-- user_id wordt bewust niet meegegeven (= null) -> zichtbaar voor iedereen.
-- is_custom = false -> niet verwijderbaar via de app (RLS).

insert into public.exercises (name, category, is_custom) values
  -- Borst
  ('Bench press (flat)', 'borst', false),
  ('Bench press (incline)', 'borst', false),
  ('Dumbbell fly', 'borst', false),
  ('Cable crossover', 'borst', false),
  ('Dips (borst)', 'borst', false),
  ('Push-up', 'borst', false),
  -- Rug
  ('Deadlift', 'rug', false),
  ('Barbell row', 'rug', false),
  ('Lat pulldown', 'rug', false),
  ('Cable row', 'rug', false),
  ('Pull-up', 'rug', false),
  ('T-bar row', 'rug', false),
  -- Schouders
  ('Overhead press', 'schouders', false),
  ('Dumbbell press', 'schouders', false),
  ('Lateral raise', 'schouders', false),
  ('Front raise', 'schouders', false),
  ('Face pull', 'schouders', false),
  ('Arnold press', 'schouders', false),
  -- Armen
  ('Barbell curl', 'armen', false),
  ('Hammer curl', 'armen', false),
  ('Tricep pushdown', 'armen', false),
  ('Skull crusher', 'armen', false),
  ('Overhead tricep extension', 'armen', false),
  ('Preacher curl', 'armen', false),
  -- Benen
  ('Squat', 'benen', false),
  ('Leg press', 'benen', false),
  ('Romanian deadlift', 'benen', false),
  ('Leg extension', 'benen', false),
  ('Leg curl', 'benen', false),
  ('Lunges', 'benen', false),
  ('Hip thrust', 'benen', false),
  ('Calf raise', 'benen', false),
  -- Core
  ('Plank', 'core', false),
  ('Cable crunch', 'core', false),
  ('Hanging leg raise', 'core', false),
  ('Russian twist', 'core', false),
  ('Ab wheel rollout', 'core', false)
on conflict (name, category) where (user_id is null) do nothing;

-- Verificatie (optioneel):
-- select category, count(*) from public.exercises
--   where user_id is null group by category order by category;
