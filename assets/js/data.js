/* ==========================================================================
   Durham Wiffle Ball - league data

   Teams, fixtures and results transcribed from playdurham.com/wiffleball.
   The 32 played games were checked against the league's published standings
   table: all eight teams match on W-L-T, runs scored and runs allowed.

   One league, no A/B split. Fixtures live in the database once
   supabase/seed_games.sql is loaded; the list below is the fallback.
   ========================================================================== */
(function (global) {
  'use strict';

  var LOGO_CDN = 'https://playdurham.com/wp-content/uploads/';
  var IMG      = 'assets/Photos/';

  /* ---------- Teams ----------
     `color` is the team's shirt colour, used for the crest when no logo
     file is present, so the site never depends on a remote image. */
  var TEAMS = [
    { id:'red',    name:'Red Hot Herrings',   short:'Red Hot Herrings', color:'#C0392B',
      logo:LOGO_CDN+'2025/05/2025_Red-128x128.jpg',
      url:'https://playdurham.com/team/2026-red-hot-herrings/' },
    { id:'sky',    name:'Sky Flyers',         short:'Sky Flyers',       color:'#3FB6C9',
      logo:LOGO_CDN+'2024/04/WiffleBallTeams_05_Aqua-128x128.jpg',
      url:'https://playdurham.com/team/2026-sky-flyers/' },
    { id:'yellow', name:'Yellow Jackets',     short:'Yellow Jackets',   color:'#E8B300',
      logo:LOGO_CDN+'2026/03/unnamed-6-128x128.jpg',
      url:'https://playdurham.com/team/2026-yellow-jackets/' },
    { id:'pinky',  name:'Pinky Swears',       short:'Pinky Swears',     color:'#E0559A',
      logo:LOGO_CDN+'2025/05/2025_Pink-128x128.jpg',
      url:'https://playdurham.com/team/2026-pinky-swears/' },
    { id:'green',  name:'Greenwich Bean Time',short:'Greenwich',        color:'#3E9B4F',
      logo:LOGO_CDN+'2024/04/WiffleBallTeams_03_Green-128x128.jpg',
      url:'https://playdurham.com/team/2026-greenwich-bean-time/' },
    { id:'purple', name:'Purple Nurples',     short:'Purple Nurples',   color:'#7B4BC4',
      logo:LOGO_CDN+'2025/05/2025_Violet-128x128.jpg',
      url:'https://playdurham.com/team/2026-purple-nurples/' },
    { id:'blue',   name:'Blue Crue',          short:'Blue Crue',        color:'#2F6FD0',
      logo:LOGO_CDN+'2025/05/2025_Royal-128x128.jpg',
      url:'https://playdurham.com/team/2026-blue-crue/' },
    { id:'orange', name:'Orange Bananas',     short:'Orange Bananas',   color:'#E2811F',
      logo:LOGO_CDN+'2025/05/2025_Orange-128x128.jpg',
      url:'https://playdurham.com/team/2026-orange-you-glad-i-didnt-say-banana/' }
  ];
  TEAMS.forEach(function (t) { t.league = null; t.cause = 'Playing for Miracle League of the Triangle'; });

  var byId = {};
  TEAMS.forEach(function (t) { byId[t.id] = t; });

  /* ---------- Beneficiary and sponsors ---------- */
  var BENEFICIARY = {
    name: 'Miracle League of the Triangle',
    site: 'https://www.mltriangle.com/',
    blurb: 'Every dollar the league raises goes to Miracle League of the Triangle, which gives ' +
           'children with disabilities the chance to play baseball on a purpose-built, fully ' +
           'accessible field. The league plays its games on that same field in Durham.'
  };

  var SPONSORS = [
    { name:'Family Care',        site:'http://www.familycarepa.com' },
    { name:"Bralie's Bar",       site:'https://braliesbar.com' },
    { name:"Oakley's Lawn Care", site:'https://oakleyslawncarenc.com/' }
  ];

  /* ---------- Season ---------- */
  var SEASON = {
    id: '2026-wiffle',
    label: '2026 Season',
    opener: '2026-04-10',
    venue: 'Miracle League of the Triangle',
    venueAddress: '473 Moorehead Ave, Durham, NC 27703',
    venueMap: 'https://www.google.com/maps/search/?api=1&query=473+Moorehead+Ave,+Durham,+NC+27703',
    slots: ['6:20 PM', '7:10 PM', '8:00 PM', '8:50 PM'],
    xHandle: 'PlayDurham'
  };

  /* ---------- Fixtures ----------
     [date, time, home, homeScore, away, awayScore]. Scores null = not played. */
  var GAMES = [
    ['2026-04-10','18:20','pinky',1,'sky',2],    ['2026-04-10','19:10','orange',1,'purple',4],
    ['2026-04-10','20:00','blue',0,'yellow',9],  ['2026-04-10','20:50','red',4,'green',3],
    ['2026-04-24','18:20','sky',15,'blue',10],   ['2026-04-24','19:10','green',5,'purple',2],
    ['2026-04-24','20:00','pinky',10,'orange',3],['2026-04-24','20:50','yellow',1,'red',2],
    ['2026-05-15','18:20','blue',4,'orange',3],  ['2026-05-15','19:10','green',3,'pinky',9],
    ['2026-05-15','20:00','purple',2,'yellow',4],['2026-05-15','20:50','red',4,'sky',0],
    ['2026-05-29','18:20','purple',10,'pinky',5],['2026-05-29','19:10','orange',4,'green',7],
    ['2026-05-29','20:00','red',11,'blue',0],    ['2026-05-29','20:50','sky',5,'yellow',0],
    ['2026-06-12','18:20','blue',0,'green',17],  ['2026-06-12','19:10','purple',8,'sky',2],
    ['2026-06-12','20:00','orange',0,'red',8],   ['2026-06-12','20:50','red',3,'pinky',14],
    ['2026-06-26','18:20','purple',4,'blue',3],  ['2026-06-26','19:10','green',1,'sky',1],
    ['2026-06-26','20:00','yellow',6,'orange',0],['2026-06-26','20:50','pinky',1,'yellow',14],
    ['2026-07-24','18:20','pinky',5,'blue',2],   ['2026-07-24','19:10','green',3,'yellow',3],
    ['2026-07-24','20:00','red',1,'purple',1],   ['2026-07-24','20:50','sky',5,'orange',1],
    ['2026-08-07','18:20','purple',4,'green',5], ['2026-08-07','19:10','blue',3,'sky',6],
    ['2026-08-07','20:00','pinky',6,'orange',0], ['2026-08-07','20:50','yellow',8,'red',4],
    ['2026-08-21','18:20','orange',null,'green',null],
    ['2026-08-21','19:10','sky',null,'yellow',null],
    ['2026-08-21','20:00','blue',null,'red',null],
    ['2026-08-21','20:50','pinky',null,'purple',null]
  ];

  var RESULTS = {};

  function fmtTime(t) {
    var p = t.split(':'), h = parseInt(p[0], 10), m = p[1];
    var ap = h >= 12 ? 'PM' : 'AM', h12 = h % 12 || 12;
    return h12 + ':' + m + ' ' + ap;
  }

  function buildSchedule() {
    var byDate = {}, order = [];
    RESULTS = {};
    GAMES.forEach(function (g, i) {
      var d = g[0], id = 'w' + i;
      if (!byDate[d]) { byDate[d] = []; order.push(d); }
      byDate[d].push({
        id: id, gameId: null, time: fmtTime(g[1]), time24: g[1] + ':00', date: d,
        home: g[2], away: g[4], league: null, venue: SEASON.venue,
        status: g[3] == null ? 'scheduled' : 'final'
      });
      if (g[3] != null && g[5] != null) RESULTS[id] = { home: g[3], away: g[5] };
    });
    order.sort();
    return order.map(function (d, i) {
      byDate[d].sort(function (a, b) { return a.time24 < b.time24 ? -1 : 1; });
      return { week: i + 1, date: d, games: byDate[d] };
    });
  }

  var SCHEDULE = buildSchedule();

  /* Fixtures and scores from the database replace the built-in list. */
  function loadSchedule(season) {
    if (!global.DSAPI || !global.DSAPI.configured()) return Promise.resolve(false);
    return global.DSAPI.listGames(season || SEASON.id).then(function (rows) {
      if (!rows || !rows.length) return false;
      var byDate = {}, order = [];
      RESULTS = {};
      rows.forEach(function (r) {
        if (!byDate[r.game_date]) { byDate[r.game_date] = []; order.push(r.game_date); }
        var g = { id: r.id, gameId: r.legacy_id, time: fmtTime(r.game_time.slice(0, 5)),
                  time24: r.game_time, date: r.game_date, home: r.home_team, away: r.away_team,
                  league: null, venue: r.venue || SEASON.venue, status: r.status };
        if (r.home_score != null && r.away_score != null) {
          RESULTS[g.id] = { home: r.home_score, away: r.away_score };
        }
        byDate[r.game_date].push(g);
      });
      order.sort();
      SCHEDULE = order.map(function (d, i) {
        byDate[d].sort(function (a, b) { return a.time24 < b.time24 ? -1 : 1; });
        return { week: i + 1, date: d, games: byDate[d] };
      });
      return true;
    }).catch(function () { return false; });
  }

  function teamGames(teamId) {
    var out = [];
    SCHEDULE.forEach(function (day) {
      day.games.forEach(function (g) {
        if (g.home === teamId || g.away === teamId) {
          out.push({ game: g, day: day, isHome: g.home === teamId,
                     opponent: byId[g.home === teamId ? g.away : g.home] });
        }
      });
    });
    return out;
  }

  function computeStandings(results) {
    var rec = {};
    TEAMS.forEach(function (t) { rec[t.id] = { w:0, l:0, t:0, rs:0, ra:0, form:[] }; });
    SCHEDULE.forEach(function (day) {
      day.games.forEach(function (g) {
        var res = results && results[g.id];
        if (!res) return;
        var h = rec[g.home], a = rec[g.away];
        if (!h || !a) return;
        h.rs += res.home; h.ra += res.away;
        a.rs += res.away; a.ra += res.home;
        if (res.home > res.away)      { h.w++; a.l++; h.form.push('w'); a.form.push('l'); }
        else if (res.home < res.away) { a.w++; h.l++; a.form.push('w'); h.form.push('l'); }
        else                          { h.t++; a.t++; h.form.push('t'); a.form.push('t'); }
      });
    });
    return TEAMS.map(function (team) {
      var s = rec[team.id], gp = s.w + s.l + s.t;
      var pct = gp ? (s.w + s.t * 0.5) / gp : 0;
      var streak = { type:'-', n:0 };
      for (var i = s.form.length - 1; i >= 0; i--) {
        if (i === s.form.length - 1) streak = { type:s.form[i], n:1 };
        else if (s.form[i] === streak.type) streak.n++;
        else break;
      }
      return { team:team, gp:gp, w:s.w, l:s.l, t:s.t, pct:pct,
               rs:s.rs, ra:s.ra, diff:s.rs - s.ra, streak:streak, last5:s.form.slice(-5) };
    });
  }

  function ranked(results) {
    return computeStandings(results).sort(function (a, b) {
      if (b.pct !== a.pct)   return b.pct - a.pct;
      if (b.diff !== a.diff) return b.diff - a.diff;
      if (b.rs !== a.rs)     return b.rs - a.rs;
      return a.team.name.localeCompare(b.team.name);
    });
  }

  function standingsPosition(teamId, results) {
    var rows = ranked(results);
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].team.id === teamId) return { pos:i+1, of:rows.length, row:rows[i] };
    }
    return null;
  }

  /* Top 4 of 8 reach the end-of-season tournament. */
  var PLAYOFF_CUT = 4;

  var PHOTOS = [];
  var PHOTO_SEASONS = [];
  var CHAMPIONS = [];
  var SEASON_ARCHIVE = [
    { id:'2026-wiffle', label:'2026 Season', live:true },
    { id:'2024-wiffle', label:'2024 Season', live:false,
      standings:'https://playdurham.com/table/2024-summer-league/',
      schedule:'https://playdurham.com/wiffleball/' }
  ];
  var REVIEWS = [];

  /* The wiffle league has no separate charity roster: every team plays for
     the same beneficiary. These keep the shared components working. */
  function allOrgs(){ return []; }
  function activeTeams(){ return TEAMS; }
  function orgById(){ return null; }
  function loadOrgs(){ return Promise.resolve(false); }

  global.DS = {
    LOGO: 'https://playdurham.com/wp-content/uploads/2024/04/2024-Wiffle-Ball-Logo.jpg',
    LOGO_FALLBACK: LOGO_CDN + '2024/04/2024-Wiffle-Ball-Logo.jpg',
    HERO_PHOTO: 'https://playdurham.com/wp-content/uploads/2024/04/Promo_03-1024x487.jpg',
    HERO_FALLBACK: LOGO_CDN + '2024/04/Promo_03-1024x487.jpg',
    TEAMS: TEAMS,
    byId: byId,
    SEASON: SEASON,
    BENEFICIARY: BENEFICIARY,
    SPONSORS: SPONSORS,
    GAMES: GAMES,
    get SCHEDULE(){ return SCHEDULE; },
    get RESULTS(){ return RESULTS; },
    loadSchedule: loadSchedule,
    teamGames: teamGames,
    computeStandings: computeStandings,
    ranked: ranked,
    standingsPosition: standingsPosition,
    PLAYOFF_CUT: PLAYOFF_CUT,
    PHOTOS: PHOTOS, PHOTO_SEASONS: PHOTO_SEASONS, CHAMPIONS: CHAMPIONS,
    SEASON_ARCHIVE: SEASON_ARCHIVE, REVIEWS: REVIEWS,
    allOrgs: allOrgs, activeTeams: activeTeams, orgById: orgById, loadOrgs: loadOrgs,
    STATUS_LABEL: { active:'Active', inactive:'Inactive', former:'Past' }
  };
})(window);
