/* ==========================================================================
   Durham Wiffle Ball - shared UI
   ========================================================================== */
(function (global) {
  'use strict';
  var DS = global.DS;

  function esc(s){return String(s).replace(/[&<>"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c];});}
  function fmtDate(iso,opts){return new Date(iso+'T12:00:00').toLocaleDateString('en-US',opts||{weekday:'long',month:'long',day:'numeric',year:'numeric'});}
  function pct(n){return n.toFixed(3).replace(/^0/,'');}
  function qs(k){var m=new RegExp('[?&]'+k+'=([^&]*)').exec(location.search);return m?decodeURIComponent(m[1]):null;}

  var ICONS = {
    pin:'<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0z"/><circle cx="12" cy="10" r="3"/></svg>',
    info:'<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/></svg>',
    arrow:'<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg>',
    chev:'<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9l6 6 6-6"/></svg>',
    plate:'<svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M4 4h16v9l-8 7-8-7V4z"/></svg>',
    menu:'<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M3 6h18M3 12h18M3 18h18"/></svg>',
    fb:'<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M22 12a10 10 0 1 0-11.6 9.9v-7H7.9V12h2.5V9.8c0-2.5 1.5-3.9 3.8-3.9 1.1 0 2.2.2 2.2.2v2.4h-1.2c-1.2 0-1.6.8-1.6 1.6V12h2.7l-.4 2.9h-2.3v7A10 10 0 0 0 22 12z"/></svg>',
    yt:'<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M23 12s0-3.4-.4-5c-.3-.9-1-1.6-1.9-1.9C19 4.7 12 4.7 12 4.7s-7 0-8.7.4c-.9.3-1.6 1-1.9 1.9C1 8.6 1 12 1 12s0 3.4.4 5c.3.9 1 1.6 1.9 1.9 1.7.4 8.7.4 8.7.4s7 0 8.7-.4c.9-.3 1.6-1 1.9-1.9.4-1.6.4-5 .4-5zM9.8 15.3V8.7l5.7 3.3-5.7 3.3z"/></svg>',
    x:'<svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M18.2 2H21l-6.4 7.3L22.2 22h-6l-4.7-6.1L6.1 22H3.3l6.9-7.8L2.2 2h6.1l4.2 5.6L18.2 2zm-1 18.3h1.6L7.9 3.6H6.2l11 16.7z"/></svg>'
  };

  /* Team crest: the logo if there is one, otherwise a coloured disc with the
     team's initial. Wiffle teams are named after colours, so this reads well
     and removes any dependency on a remote image. */
  function crest(team, size, cls){
    size = size || 48;
    var initial = esc((team.name||'?').charAt(0));
    var fallback = '<span class="crest '+(cls||'')+'" style="width:'+size+'px;height:'+size+'px;'+
      'background:'+(team.color||'#55636E')+';font-size:'+Math.round(size*0.42)+'px">'+initial+'</span>';
    if(!team.logo) return fallback;
    return '<img class="'+(cls||'')+'" src="'+team.logo+'" alt="" loading="lazy" '+
           'style="width:'+size+'px;height:'+size+'px;border-radius:50%;object-fit:cover;'+
           'background:'+(team.color||'#eee')+'" '+
           'onerror="this.outerHTML=this.getAttribute(\'data-fb\')" '+
           'data-fb="'+esc(fallback).replace(/"/g,'&quot;')+'">';
  }

  var NAV = [
    { label:'Schedule',  href:'schedule.html' },
    { label:'Standings', href:'standings.html' },
    { label:'Teams',     href:'current-teams.html' },
    { label:'Register',  href:'register.html' },
    { label:'League Info', children:[
      { label:'About us',      href:'about.html' },
      { label:'Rules',         href:'rules.html' },
      { label:'Directions',    href:'directions.html' },
      { label:'Where the money goes', href:'donations.html' }
    ]}
  ];

  function renderHeader(){
    var host=document.querySelector('[data-header]'); if(!host) return;
    var cur=host.getAttribute('data-header')||'';

    var desk=NAV.map(function(n){
      if(n.children){
        var kids=n.children.map(function(c){
          return '<a href="'+c.href+'"'+(c.href===cur?' aria-current="page"':'')+'>'+esc(c.label)+'</a>';
        }).join('');
        var active=n.children.some(function(c){return c.href===cur;});
        return '<div class="nav-item" data-dropdown><button type="button" aria-expanded="false"'+
               (active?' style="color:var(--gold)"':'')+'>'+esc(n.label)+ICONS.chev+
               '</button><div class="dropdown">'+kids+'</div></div>';
      }
      return '<a href="'+n.href+'"'+(n.href===cur?' aria-current="page"':'')+'>'+esc(n.label)+'</a>';
    }).join('');

    var mob=NAV.reduce(function(a,n){return n.children?a.concat(n.children):a.concat([n]);},[])
      .map(function(n){return '<a href="'+n.href+'"'+(n.href===cur?' aria-current="page"':'')+'>'+esc(n.label)+'</a>';}).join('');

    host.innerHTML =
      '<header class="site-header">'+
        '<div class="wrap header-bar">'+
          '<a class="brand" href="index.html">'+
            '<img src="'+DS.LOGO+'" alt="Durham Wiffle Ball, Play Ball Y\'all" '+
              'onerror="this.onerror=null;this.src=DS.LOGO_FALLBACK">'+
            '<span class="brand-txt"><span class="brand-name">Durham Wiffle Ball</span>'+
            '<span class="brand-tag">Play Ball Y\'all</span></span>'+
          '</a>'+
          '<nav class="nav">'+desk+
            '<a class="btn btn-primary btn-sm nav-cta" href="https://paypal.me/plaync" target="_blank" rel="noopener">Donate</a>'+
          '</nav>'+
          '<button class="burger" type="button" aria-label="Menu" aria-expanded="false" data-burger>'+ICONS.menu+'</button>'+
        '</div>'+
        '<div class="mobile-nav" data-mobile-nav><div class="wrap">'+mob+
          '<a class="btn btn-primary" href="https://paypal.me/plaync" target="_blank" rel="noopener">Donate</a>'+
        '</div></div>'+
      '</header>';

    host.querySelectorAll('[data-dropdown]').forEach(function(item){
      var btn=item.querySelector('button');
      btn.addEventListener('click',function(e){
        e.stopPropagation();
        var open=item.getAttribute('data-open')==='true';
        host.querySelectorAll('[data-dropdown]').forEach(function(o){o.removeAttribute('data-open');});
        if(!open) item.setAttribute('data-open','true');
        btn.setAttribute('aria-expanded',String(!open));
      });
    });
    document.addEventListener('click',function(){
      host.querySelectorAll('[data-dropdown]').forEach(function(o){
        o.removeAttribute('data-open');
        o.querySelector('button').setAttribute('aria-expanded','false');
      });
    });

    var burger=host.querySelector('[data-burger]'), mn=host.querySelector('[data-mobile-nav]');
    burger.addEventListener('click',function(){
      var open=mn.getAttribute('data-open')==='true';
      mn.setAttribute('data-open',String(!open));
      burger.setAttribute('aria-expanded',String(!open));
    });
  }

  function renderFooter(){
    var host=document.querySelector('[data-footer]'); if(!host) return;
    host.innerHTML=
      '<footer class="site-footer"><div class="wrap">'+
        '<div class="footer-grid">'+
          '<div class="footer-brand">'+
            '<img src="'+DS.LOGO+'" alt="Durham Wiffle Ball" '+
              'onerror="this.onerror=null;this.src=DS.LOGO_FALLBACK">'+
            '<p class="footer-quote">Friday nights, Miracle League field.</p>'+
            '<div class="socials">'+
              '<a href="https://x.com/PlayDurham" target="_blank" rel="noopener" aria-label="X">'+ICONS.x+'</a>'+
              '<a href="https://www.facebook.com/durhamsoftball" target="_blank" rel="noopener" aria-label="Facebook">'+ICONS.fb+'</a>'+
              '<a href="https://www.youtube.com/channel/UCxdJh6Hg2TeVmHBexDFyAew" target="_blank" rel="noopener" aria-label="YouTube">'+ICONS.yt+'</a>'+
            '</div></div>'+
          '<div><h4>The league</h4><ul>'+
            '<li><a href="schedule.html">Schedule</a></li>'+
            '<li><a href="standings.html">Standings</a></li>'+
            '<li><a href="current-teams.html">Teams</a></li>'+
            
            
            '<li><a href="rules.html">Rules</a></li>'+
            '<li><a href="register.html">Register to play</a></li></ul></div>'+
          '<div><h4>About</h4><ul>'+
            '<li><a href="about.html">About Durham Wiffle Ball</a></li>'+
            '<li><a href="donations.html">Where the money goes</a></li>'+
            
            '<li><a href="directions.html">Directions</a></li>'+
            '<li><a href="http://playdurham.com" target="_blank" rel="noopener">More Play NC games</a></li></ul></div>'+
          '<div><h4>Contact</h4><ul>'+
            '<li><a href="mailto:playncinc@gmail.com">playncinc@gmail.com</a><div class="footer-note">Goes straight to Ryan</div></li>'+
            '<li><a href="tel:8324227259">(832) 422-7259</a><div class="footer-note">Text only &middot; 24-48hr response</div></li>'+
            '<li><a href="directions.html">400 E Woodcroft Pkwy<br>Durham, NC 27713</a><div class="footer-note">Turn left when you enter the park</div></li></ul></div>'+
        '</div>'+
        '<div class="footer-bar">'+
          '<span>&copy; '+new Date().getFullYear()+' Durham Wiffle Ball &middot; Managed by Play NC, a 501(c)(3) non-profit</span>'+
          '<span class="spacer"></span>'+
          '<a class="btn btn-primary btn-sm" href="https://paypal.me/plaync" target="_blank" rel="noopener">Donate to the pool</a>'+
        '</div>'+
      '</div></footer>';
  }

  /* ---------- Game card ---------- */
  function teamRow(team,side,score,isWinner,records){
    var isHome=side==='home';
    var rec=records&&records[team.id];
    return '<div class="gc-row '+(isHome?'is-home':'is-away')+'">'+
      crest(team,48,'gc-logo')+
      '<div class="gc-team">'+
        '<a class="gc-team-name" href="team.html?id='+team.id+'">'+esc(team.name)+'</a>'+
        '<div class="gc-team-sub">'+
          '<span class="tag-ha '+(isHome?'tag-home':'tag-away')+'">'+(isHome?ICONS.plate+'Home':'Away')+'</span>'+
          (rec?'<span class="gc-record">'+rec+'</span>':'')+
        '</div></div>'+
      (score==null?'':'<div class="gc-score'+(isWinner?'':' is-loser')+'">'+score+'</div>')+
    '</div>';
  }

  function gameCard(game,opts){
    opts=opts||{};
    var home=DS.byId[game.home], away=DS.byId[game.away];
    var res=opts.results&&opts.results[game.id];
    var hs=res?res.home:null, as=res?res.away:null;
    return '<article class="game-card'+(opts.compact?' gc-compact':'')+'">'+
      '<div class="gc-meta">'+
        '<span class="gc-time">'+esc(game.time)+'</span>'+
        (res?'<span class="pill pill-final">Final</span>':'')+
        '<span class="spacer"></span>'+
        '<span class="gc-venue">'+ICONS.pin+esc(game.venue)+'</span>'+
      '</div>'+
      '<div class="gc-teams">'+
        teamRow(away,'away',as,res&&as>hs,opts.records)+
        '<div class="gc-at"><span>at</span></div>'+
        teamRow(home,'home',hs,res&&hs>as,opts.records)+
      '</div>'+
    '</article>';
  }

  /* ---------- Standings ---------- */
  var SORT={pct:function(r){return [r.pct,r.diff,r.rs];},w:function(r){return [r.w,r.pct,r.diff];},
    l:function(r){return [-r.l,r.pct,r.diff];},rs:function(r){return [r.rs,r.pct];},
    ra:function(r){return [-r.ra,r.pct];},diff:function(r){return [r.diff,r.pct];},
    team:function(r){return [r.team.name];}};

  function sortRows(rows,key,dir){
    var fn=SORT[key]||SORT.pct;
    var s=rows.slice().sort(function(a,b){
      var va=fn(a),vb=fn(b);
      for(var i=0;i<va.length;i++){if(va[i]<vb[i])return 1;if(va[i]>vb[i])return -1;}
      return a.team.name.localeCompare(b.team.name);
    });
    if(dir==='asc') s.reverse();
    return s;
  }
  function last5HTML(f){return f.length?'<span class="last5">'+f.map(function(x){return '<i class="'+x+'">'+x.toUpperCase()+'</i>';}).join('')+'</span>':'<span class="muted">-</span>';}
  function streakHTML(s){return s.n?'<span class="streak streak-'+s.type+'">'+s.type.toUpperCase()+s.n+'</span>':'<span class="muted">-</span>';}

  function standingsTable(rows,opts){
    opts=opts||{};
    var sk=opts.sortKey||'pct', sd=opts.sortDir||'desc';
    var sorted=sortRows(rows,sk,sd);
    var played=sorted.some(function(r){return r.gp>0;});
    var cut=(opts.cut!=null)?opts.cut:(typeof DS.PLAYOFF_CUT==='number'?DS.PLAYOFF_CUT:0);
    // Teams on the same winning percentage share a position, as the league prints it.
    var displayPos=sorted.map(function(r){
      return 1 + sorted.filter(function(o){ return o.pct > r.pct; }).length;
    });
    var head=[{k:'pos',t:'#',cls:'col-pos',s:false},{k:'team',t:'Team',cls:'col-team'},{k:'gp',t:'GP',s:false},
      {k:'w',t:'W'},{k:'l',t:'L'},{k:'t',t:'T',s:false},{k:'pct',t:'PCT'},{k:'rs',t:'RS'},{k:'ra',t:'RA'},
      {k:'diff',t:'Diff'},{k:'strk',t:'Strk',s:false},{k:'l5',t:'Last 5',s:false}]
      .map(function(h){
        var sortable=h.s!==false&&SORT[h.k];
        return '<th class="'+(h.cls||'')+(sortable?' sortable':'')+'"'+(sortable?' data-sort="'+h.k+'"':'')+
               (h.k===sk?' data-dir="'+sd+'"':'')+'>'+h.t+'</th>';
      }).join('');

    var body=sorted.map(function(r,i){
      var pc=played?(i===0?'pos-1':(cut&&i<cut?'pos-2':'')):'';
      var dc=r.diff>0?'diff-pos':(r.diff<0?'diff-neg':'muted');
      return '<tr'+(i===cut-1?' class="cutline"':'')+'>'+
        '<td class="col-pos"><span class="pos-badge '+pc+'">'+displayPos[i]+'</span></td>'+
        '<td class="col-team"><div class="team-cell"><img src="'+r.team.logo+'" alt="" loading="lazy">'+
          '<a class="tn" href="team.html?id='+r.team.id+'">'+esc(r.team.name)+'</a></div></td>'+
        '<td>'+r.gp+'</td><td class="num-strong">'+r.w+'</td><td class="num-strong">'+r.l+'</td><td>'+r.t+'</td>'+
        '<td class="num-strong">'+pct(r.pct)+'</td><td>'+r.rs+'</td><td>'+r.ra+'</td>'+
        '<td class="'+dc+'">'+(r.diff>0?'+':'')+r.diff+'</td>'+
        '<td>'+streakHTML(r.streak)+'</td><td>'+last5HTML(r.last5)+'</td></tr>';
    }).join('');

    var cards=sorted.map(function(r,i){
      var pc=played?(i===0?'pos-1':(cut&&i<cut?'pos-2':'')):'';
      var dc=r.diff>0?'diff-pos':(r.diff<0?'diff-neg':'muted');
      return '<a class="sc-row" href="team.html?id='+r.team.id+'">'+
        '<span class="pos-badge '+pc+'">'+displayPos[i]+'</span>'+
        '<img class="sc-logo" src="'+r.team.logo+'" alt="" loading="lazy">'+
        '<div class="sc-main"><div class="sc-name">'+esc(r.team.name)+'</div>'+
        '<div class="sc-sub"><span>PCT '+pct(r.pct)+'</span><span class="'+dc+'">Diff '+(r.diff>0?'+':'')+r.diff+'</span>'+streakHTML(r.streak)+'</div></div>'+
        '<div class="sc-rec">'+r.w+'-'+r.l+(r.t?'-'+r.t:'')+'</div></a>';
    }).join('');

    return '<div class="table-wrap" data-standings>'+
      '<div class="table-head"><h3>'+esc(opts.title||'')+'</h3><span class="spacer"></span>'+
      '<span class="pill pill-outline">'+rows.length+' teams</span></div>'+
      '<div class="table-scroll"><table class="standings"><thead><tr>'+head+'</tr></thead><tbody>'+body+'</tbody></table></div>'+
      '<div class="standings-cards">'+cards+'</div>'+
      '<div class="table-foot">'+
        '<span class="key"><strong>GP</strong> games played</span>'+
        '<span class="key"><strong>PCT</strong> win pct</span>'+
        '<span class="key"><strong>RS/RA</strong> runs scored / allowed</span>'+
        '<span class="key">Dashed line = '+(cut?'top '+cut+' reach the tournament':'playoff cut')+'</span>'+
      '</div></div>';
  }

  /* ---------- X / @PlayDurham feed with fallback ---------- */
  function mountXFeed(host,handle){
    if(!host) return;
    handle=handle||DS.SEASON.xHandle;
    host.innerHTML=
      '<div class="x-feed">'+
        '<div class="x-head">'+ICONS.x+'<b>@'+handle+'</b><span>Rainouts and announcements</span>'+
        '<span class="spacer"></span>'+
        '<a class="btn btn-outline btn-sm" href="https://x.com/'+handle+'" target="_blank" rel="noopener">Follow</a></div>'+
        '<div class="x-body" data-x-body>'+
          '<a class="twitter-timeline" data-height="500" data-theme="light" data-chrome="noheader nofooter transparent" '+
          'href="https://twitter.com/'+handle+'">Loading posts…</a>'+
        '</div>'+
      '</div>';

    var body=host.querySelector('[data-x-body]');
    function fallback(){
      body.innerHTML=
        '<div class="x-fallback">'+
          '<p>The live X timeline could not load. X often blocks embedded feeds. '+
          'Rainouts and announcements are posted to @'+handle+'.</p>'+
          '<div class="btn-row" style="justify-content:center">'+
            '<a class="btn btn-primary btn-sm" href="https://x.com/'+handle+'" target="_blank" rel="noopener">Open @'+handle+' on X</a>'+
            '<a class="btn btn-outline btn-sm" href="https://www.facebook.com/durhamsoftball" target="_blank" rel="noopener">Facebook</a>'+
          '</div>'+
        '</div>';
    }
    var s=document.createElement('script');
    s.src='https://platform.twitter.com/widgets.js';
    s.async=true; s.charset='utf-8';
    s.onerror=fallback;
    document.head.appendChild(s);
    // if the widget hasn't replaced the anchor with an iframe in time, show the fallback
    setTimeout(function(){ if(!body.querySelector('iframe')) fallback(); },4000);
  }

  /* ---------- Photos ---------- */
  function photoBand(list,opts){
    opts=opts||{};
    return list.map(function(p,i){
      var cls='photo'+(p.wide&&opts.allowWide?' wide':'')+(p.tall?' tall':'');
      return '<figure class="'+cls+'">'+
        '<img src="'+p.src+'" alt="'+esc(p.caption||'Durham Wiffle Ball')+'" loading="'+(i<2?'eager':'lazy')+'">'+
        (p.caption?'<figcaption class="photo-cap">'+esc(p.caption)+'</figcaption>':'')+
      '</figure>';
    }).join('');
  }

  function init(){ renderHeader(); renderFooter(); }

  global.DSUI={esc:esc,crest:crest,fmtDate:fmtDate,pct:pct,qs:qs,ICONS:ICONS,gameCard:gameCard,
    standingsTable:standingsTable,sortRows:sortRows,mountXFeed:mountXFeed,photoBand:photoBand,init:init};

  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',init);
  else init();
})(window);
