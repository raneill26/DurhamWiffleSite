/* ==========================================================================
   Durham Wiffle Ball - Supabase RPC client
   Plain fetch, no SDK, so the site stays dependency free.
   Each call maps to a function in supabase/schema.sql.
   ========================================================================== */
(function (global) {
  'use strict';
  var cfg = global.DS_CONFIG || {};

  function configured() { return !!(cfg.SUPABASE_URL && cfg.SUPABASE_ANON_KEY); }

  function rpc(fn, args) {
    if (!configured()) return Promise.reject(new Error('NOT_CONFIGURED'));
    return fetch(cfg.SUPABASE_URL.replace(/\/$/, '') + '/rest/v1/rpc/' + fn, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': cfg.SUPABASE_ANON_KEY,
        'Authorization': 'Bearer ' + cfg.SUPABASE_ANON_KEY
      },
      body: JSON.stringify(args || {})
    }).then(function (r) {
      return r.json().catch(function () { return null; }).then(function (body) {
        if (!r.ok) {
          var msg = (body && (body.message || body.hint)) || ('Request failed (' + r.status + ')');
          var e = new Error(msg); e.status = r.status; throw e;
        }
        return body;
      });
    });
  }

  var KEY = 'ds_team_session';
  function saveSession(s) { try { sessionStorage.setItem(KEY, JSON.stringify(s)); } catch (e) {} }
  function loadSession() {
    try {
      var s = JSON.parse(sessionStorage.getItem(KEY) || 'null');
      if (s && new Date(s.expires_at) > new Date()) return s;
    } catch (e) {}
    return null;
  }
  function clearSession() { try { sessionStorage.removeItem(KEY); } catch (e) {} }

  function sha256Hex(text) {
    if (!(global.crypto && global.crypto.subtle)) return Promise.resolve('unavailable');
    return global.crypto.subtle.digest('SHA-256', new TextEncoder().encode(text))
      .then(function (buf) {
        return Array.from(new Uint8Array(buf))
          .map(function (b) { return b.toString(16).padStart(2, '0'); }).join('');
      });
  }

  /* ---------------- admin ---------------- */
  var AKEY = 'ds_admin_session';
  function saveAdmin(s){ try{ sessionStorage.setItem(AKEY, JSON.stringify(s)); }catch(e){} }
  function loadAdmin(){
    try{ var s=JSON.parse(sessionStorage.getItem(AKEY)||'null');
      if(s && new Date(s.expires_at) > new Date()) return s; }catch(e){}
    return null;
  }
  function adminToken(){ var s=loadAdmin(); if(!s) throw new Error('NO_ADMIN'); return s.token; }

  global.DSAPI = {
    configured: configured,
    session: loadSession,
    logout: clearSession,

    teamLogin: function (teamId, passcode) {
      return rpc('team_login', { p_team_id: teamId, p_passcode: passcode })
        .then(function (rows) {
          var s = Array.isArray(rows) ? rows[0] : rows;
          if (!s || !s.token) throw new Error('Invalid passcode');
          saveSession(s); return s;
        });
    },

    roster: function (gameId) {
      var s = loadSession();
      if (!s) return Promise.reject(new Error('NO_SESSION'));
      return rpc('team_roster', { p_token: s.token, p_game_id: gameId });
    },

    setRosterOrder: function (ids) {
      var s = loadSession();
      if (!s) return Promise.reject(new Error('NO_SESSION'));
      return rpc('set_roster_order', { p_token: s.token, p_ids: ids });
    },

    markAttendance: function (gameId, playerId, status, notedBy) {
      var s = loadSession();
      if (!s) return Promise.reject(new Error('NO_SESSION'));
      return rpc('mark_attendance', {
        p_token: s.token, p_game_id: gameId, p_player_id: playerId,
        p_status: status, p_noted_by: notedBy || null
      });
    },

    /* ---- admin ---- */
    adminLogin: function (passcode) {
      return rpc('admin_login', { p_passcode: passcode }).then(function (rows) {
        var s = Array.isArray(rows) ? rows[0] : rows;
        if (!s || !s.token) throw new Error('Invalid passcode');
        saveAdmin(s); return s;
      });
    },
    adminSession: loadAdmin,
    adminLogout: function () { try { sessionStorage.removeItem(AKEY); } catch (e) {} },

    listPhotos: function (season) { return rpc('list_photos', { p_season: season || null }); },
    savePhoto: function (p) {
      return rpc('admin_save_photo', { p_token: adminToken(), p_id: p.id || null, p_url: p.url,
        p_caption: p.caption || null, p_season: p.season_id || null,
        p_sort: p.sort_order || 0, p_wide: !!p.is_wide });
    },
    deletePhoto: function (id) { return rpc('admin_delete_photo', { p_token: adminToken(), p_id: id }); },

    listChampions: function () { return rpc('list_champions', {}); },
    saveChampion: function (c) {
      return rpc('admin_save_champion', { p_token: adminToken(), p_id: c.id || null,
        p_label: c.label, p_league: c.league || null, p_team: c.team_name || null,
        p_photo: c.photo_url || null, p_caption: c.caption || null });
    },
    deleteChampion: function (id) { return rpc('admin_delete_champion', { p_token: adminToken(), p_id: id }); },

    listSeasons: function () { return rpc('list_seasons', {}); },

    /* ---- settings ---- */
    getSettings: function () {
      return rpc('get_settings', {}).then(function (rows) {
        var out = {};
        (rows || []).forEach(function (r) { out[r.key] = r.value; });
        return out;
      });
    },
    setSetting: function (k, v) {
      return rpc('admin_set_setting', { p_token: adminToken(), p_key: k, p_value: v });
    },

    /* ---- registration intake ---- */
    registrations: function (season) {
      return rpc('admin_registrations', { p_token: adminToken(), p_season: season || cfg.CURRENT_SEASON });
    },
    assignTeam: function (playerId, teamId) {
      return rpc('admin_assign_team', { p_token: adminToken(), p_player: playerId, p_team: teamId || '' });
    },
    setPaid: function (playerId, paid, season) {
      return rpc('admin_set_paid', { p_token: adminToken(), p_player: playerId,
        p_season: season || cfg.CURRENT_SEASON, p_paid: !!paid });
    },
    clearPlayers: function (season, confirm) {
      return rpc('admin_clear_players', { p_token: adminToken(),
        p_season: season || cfg.CURRENT_SEASON, p_confirm: confirm });
    },

    updatePlayer: function (p) {
      return rpc('admin_update_player', { p_token: adminToken(), p_id: p.id, p_name: p.full_name,
        p_email: p.email || '', p_phone: p.phone || '', p_shirt: p.shirt_size || '',
        p_team: p.team_id || '', p_preferred: p.preferred_team_id || '' });
    },
    setWaiver: function (id, signed) {
      return rpc('admin_set_waiver', { p_token: adminToken(), p_id: id, p_signed: !!signed });
    },
    mergePlayers: function (keepId, dropId) {
      return rpc('admin_merge_players', { p_token: adminToken(), p_keep: keepId, p_drop: dropId });
    },

    /* ---- organizations ---- */
    listOrgs: function (season) { return rpc('list_organizations', { p_season: season || null }); },
    saveOrg: function (o) {
      return rpc('admin_save_org', { p_token: adminToken(), p_id: o.id, p_name: o.name,
        p_short: o.short_name || null, p_cause: o.cause || null, p_blurb: o.blurb || null,
        p_logo: o.logo_url || null, p_website: o.website || null, p_legacy: o.legacy_url || null,
        p_status: o.status, p_season: o.season_id || null, p_league: o.league || null });
    },
    deleteOrg: function (id) { return rpc('admin_delete_org', { p_token: adminToken(), p_id: id }); },

    /* ---- schedule ---- */
    listGames: function (season) { return rpc('list_games', { p_season: season || cfg.CURRENT_SEASON }); },
    saveGame: function (g) {
      return rpc('admin_save_game', { p_token: adminToken(), p_id: g.id || null,
        p_season: g.season_id || cfg.CURRENT_SEASON, p_date: g.game_date, p_time: g.game_time,
        p_home: g.home_team, p_away: g.away_team, p_venue: g.venue || 'Pineywood Park',
        p_home_score: g.home_score, p_away_score: g.away_score, p_status: g.status || 'scheduled' });
    },
    deleteGame: function (id) { return rpc('admin_delete_game', { p_token: adminToken(), p_id: id }); },
    setScore: function (id, hs, as_, status) {
      return rpc('admin_set_score', { p_token: adminToken(), p_id: id,
        p_home_score: hs, p_away_score: as_, p_status: status || 'final' });
    },
    generateSchedule: function (o) {
      return rpc('admin_generate_schedule', { p_token: adminToken(),
        p_season: o.season || cfg.CURRENT_SEASON, p_first_date: o.first_date,
        p_weeks: o.weeks, p_first_time: o.first_time || '09:10',
        p_slot_minutes: o.slot_minutes || 55 });
    },

    /* ---- rosters ---- */
    listPlayers: function (season) {
      return rpc('admin_list_players', { p_token: adminToken(), p_season: season || cfg.CURRENT_SEASON });
    },
    savePlayer: function (p) {
      return rpc('admin_save_player', { p_token: adminToken(), p_id: p.id || null,
        p_season: p.season_id || cfg.CURRENT_SEASON, p_name: p.full_name,
        p_email: p.email || '', p_team: p.team_id || '' });
    },
    deletePlayer: function (id) { return rpc('admin_delete_player', { p_token: adminToken(), p_id: id }); },

    /* ---- photo placement ---- */
    photosByPlacement: function (place) { return rpc('list_photos_by_placement', { p_placement: place }); },
    setPhotoPlacement: function (id, placement, sort) {
      return rpc('admin_set_photo_placement', { p_token: adminToken(), p_id: id,
        p_placement: placement, p_sort: sort || 0 });
    },
    newSeason: function (o) {
      return rpc('admin_new_season', { p_token: adminToken(), p_id: o.id, p_label: o.label,
        p_starts: o.starts_on || null, p_copy_teams: o.copy_teams !== false,
        p_make_current: o.make_current !== false });
    },
    setCurrentSeason: function (id) { return rpc('admin_set_current_season', { p_token: adminToken(), p_id: id }); },
    setTeamPasscode: function (teamId, code) {
      return rpc('admin_set_team_passcode', { p_token: adminToken(), p_team_id: teamId, p_passcode: code });
    },

    /* Upload straight to Supabase Storage, bucket "photos". Returns a public URL. */
    uploadPhoto: function (file) {
      if (!configured()) return Promise.reject(new Error('NOT_CONFIGURED'));
      adminToken();
      var safe = file.name.replace(/[^a-zA-Z0-9._-]/g, '-');
      var path = Date.now() + '-' + safe;
      var base = cfg.SUPABASE_URL.replace(/\/$/, '');
      return fetch(base + '/storage/v1/object/photos/' + encodeURIComponent(path), {
        method: 'POST',
        headers: {
          'apikey': cfg.SUPABASE_ANON_KEY,
          'Authorization': 'Bearer ' + cfg.SUPABASE_ANON_KEY,
          'Content-Type': file.type || 'application/octet-stream',
          'x-upsert': 'true'
        },
        body: file
      }).then(function (r) {
        if (!r.ok) return r.text().then(function (t) { throw new Error('Upload failed: ' + t); });
        return base + '/storage/v1/object/public/photos/' + encodeURIComponent(path);
      });
    },

    registerPlayer: function (data, waiverText) {
      return sha256Hex(waiverText).then(function (hash) {
        return rpc('register_player', {
          p_season: cfg.CURRENT_SEASON,
          p_full_name: data.fullName, p_email: data.email, p_phone: data.phone || null,
          p_team_id: data.teamId || null,
          p_waiver_version: cfg.WAIVER_VERSION, p_signed_name: data.signedName,
          p_agreed_hash: hash, p_user_agent: navigator.userAgent,
          p_signature_image: data.signatureImage || null,
          p_shirt_size: data.shirtSize || null
        });
      });
    }
  };
})(window);
