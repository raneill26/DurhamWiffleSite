-- Durham Wiffle Ball: season and teams.
-- Runs against the SAME Supabase project as the softball league. Everything
-- is scoped to the 2026-wiffle season so the two leagues never collide.
--
-- NOTE: wiffle teams are deliberately NOT added to `organizations`. That
-- table is not season-scoped, so they would show up on the softball site's
-- Non-Profit Partners page. The wiffle site does not use organizations.

insert into seasons (id,label,starts_on,is_current) values
  ('2026-wiffle','2026 Season','2026-04-10',false)
  on conflict (id) do update set label=excluded.label, starts_on=excluded.starts_on;

-- teams.league is NOT NULL in the shared schema. The wiffle league has no
-- divisions, so every team is filed as 'A' and the site never shows it.
insert into teams (id,name,league,season_id) values
  ('red','Red Hot Herrings','A','2026-wiffle'),
  ('sky','Sky Flyers','A','2026-wiffle'),
  ('yellow','Yellow Jackets','A','2026-wiffle'),
  ('pinky','Pinky Swears','A','2026-wiffle'),
  ('green','Greenwich Bean Time','A','2026-wiffle'),
  ('purple','Purple Nurples','A','2026-wiffle'),
  ('blue','Blue Crue','A','2026-wiffle'),
  ('orange','Orange Bananas','A','2026-wiffle')
  on conflict (id) do update set name=excluded.name, season_id=excluded.season_id;

-- Give each captain a passcode before opening night:
-- select set_team_passcode('red', 'CHANGE-ME');   -- Red Hot Herrings
-- select set_team_passcode('sky', 'CHANGE-ME');   -- Sky Flyers
-- select set_team_passcode('yellow', 'CHANGE-ME');   -- Yellow Jackets
-- select set_team_passcode('pinky', 'CHANGE-ME');   -- Pinky Swears
-- select set_team_passcode('green', 'CHANGE-ME');   -- Greenwich Bean Time
-- select set_team_passcode('purple', 'CHANGE-ME');   -- Purple Nurples
-- select set_team_passcode('blue', 'CHANGE-ME');   -- Blue Crue
-- select set_team_passcode('orange', 'CHANGE-ME');   -- Orange Bananas

-- Check: expect 8 teams in this season.
select count(*) as teams from teams where season_id = '2026-wiffle';
