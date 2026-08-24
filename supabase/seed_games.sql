-- Durham Wiffle Ball fixtures and results, 2026 Season.
-- Transcribed from playdurham.com/wiffleball and checked against the league's
-- published standings: all eight teams match on W-L-T, runs scored and allowed.
-- Safe to re-run: clears this season's games first.

delete from games where season_id = '2026-wiffle';

insert into games (season_id, game_date, game_time, home_team, away_team, league, venue, home_score, away_score, status) values
  ('2026-wiffle','2026-04-10','18:20:00','pinky','sky','A','Miracle League of the Triangle',1,2,'final'),
  ('2026-wiffle','2026-04-10','19:10:00','orange','purple','A','Miracle League of the Triangle',1,4,'final'),
  ('2026-wiffle','2026-04-10','20:00:00','blue','yellow','A','Miracle League of the Triangle',0,9,'final'),
  ('2026-wiffle','2026-04-10','20:50:00','red','green','A','Miracle League of the Triangle',4,3,'final'),
  ('2026-wiffle','2026-04-24','18:20:00','sky','blue','A','Miracle League of the Triangle',15,10,'final'),
  ('2026-wiffle','2026-04-24','19:10:00','green','purple','A','Miracle League of the Triangle',5,2,'final'),
  ('2026-wiffle','2026-04-24','20:00:00','pinky','orange','A','Miracle League of the Triangle',10,3,'final'),
  ('2026-wiffle','2026-04-24','20:50:00','yellow','red','A','Miracle League of the Triangle',1,2,'final'),
  ('2026-wiffle','2026-05-15','18:20:00','blue','orange','A','Miracle League of the Triangle',4,3,'final'),
  ('2026-wiffle','2026-05-15','19:10:00','green','pinky','A','Miracle League of the Triangle',3,9,'final'),
  ('2026-wiffle','2026-05-15','20:00:00','purple','yellow','A','Miracle League of the Triangle',2,4,'final'),
  ('2026-wiffle','2026-05-15','20:50:00','red','sky','A','Miracle League of the Triangle',4,0,'final'),
  ('2026-wiffle','2026-05-29','18:20:00','purple','pinky','A','Miracle League of the Triangle',10,5,'final'),
  ('2026-wiffle','2026-05-29','19:10:00','orange','green','A','Miracle League of the Triangle',4,7,'final'),
  ('2026-wiffle','2026-05-29','20:00:00','red','blue','A','Miracle League of the Triangle',11,0,'final'),
  ('2026-wiffle','2026-05-29','20:50:00','sky','yellow','A','Miracle League of the Triangle',5,0,'final'),
  ('2026-wiffle','2026-06-12','18:20:00','blue','green','A','Miracle League of the Triangle',0,17,'final'),
  ('2026-wiffle','2026-06-12','19:10:00','purple','sky','A','Miracle League of the Triangle',8,2,'final'),
  ('2026-wiffle','2026-06-12','20:00:00','orange','red','A','Miracle League of the Triangle',0,8,'final'),
  ('2026-wiffle','2026-06-12','20:50:00','red','pinky','A','Miracle League of the Triangle',3,14,'final'),
  ('2026-wiffle','2026-06-26','18:20:00','purple','blue','A','Miracle League of the Triangle',4,3,'final'),
  ('2026-wiffle','2026-06-26','19:10:00','green','sky','A','Miracle League of the Triangle',1,1,'final'),
  ('2026-wiffle','2026-06-26','20:00:00','yellow','orange','A','Miracle League of the Triangle',6,0,'final'),
  ('2026-wiffle','2026-06-26','20:50:00','pinky','yellow','A','Miracle League of the Triangle',1,14,'final'),
  ('2026-wiffle','2026-07-24','18:20:00','pinky','blue','A','Miracle League of the Triangle',5,2,'final'),
  ('2026-wiffle','2026-07-24','19:10:00','green','yellow','A','Miracle League of the Triangle',3,3,'final'),
  ('2026-wiffle','2026-07-24','20:00:00','red','purple','A','Miracle League of the Triangle',1,1,'final'),
  ('2026-wiffle','2026-07-24','20:50:00','sky','orange','A','Miracle League of the Triangle',5,1,'final'),
  ('2026-wiffle','2026-08-07','18:20:00','purple','green','A','Miracle League of the Triangle',4,5,'final'),
  ('2026-wiffle','2026-08-07','19:10:00','blue','sky','A','Miracle League of the Triangle',3,6,'final'),
  ('2026-wiffle','2026-08-07','20:00:00','pinky','orange','A','Miracle League of the Triangle',6,0,'final'),
  ('2026-wiffle','2026-08-07','20:50:00','yellow','red','A','Miracle League of the Triangle',8,4,'final'),
  ('2026-wiffle','2026-08-21','18:20:00','orange','green','A','Miracle League of the Triangle',null,null,'scheduled'),
  ('2026-wiffle','2026-08-21','19:10:00','sky','yellow','A','Miracle League of the Triangle',null,null,'scheduled'),
  ('2026-wiffle','2026-08-21','20:00:00','blue','red','A','Miracle League of the Triangle',null,null,'scheduled'),
  ('2026-wiffle','2026-08-21','20:50:00','pinky','purple','A','Miracle League of the Triangle',null,null,'scheduled');

-- Check: expect 36 games over 9 nights, 32 with a final score.
select count(*) as games, count(distinct game_date) as nights,
       count(home_score) as scored from games where season_id = '2026-wiffle';
