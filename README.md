# Durham Wiffle Ball

A clone of the Durham Softball site, rebuilt for the wiffle league. Open `index.html` in a browser.
No build step.

## What is different from the softball site

- **One league, no A/B split.** A single standings table. Teams on the same winning percentage
  share a position, the way the league prints it.
- **One beneficiary.** Every team plays for Miracle League of the Triangle, so there is no
  charity roster, no partners page and no per-charity pages.
- **Eight teams, nine Friday nights.** Four games a night at 6:20, 7:10, 8:00 and 8:50.
- **Top 4 of 8** reach the end-of-season tournament, marked by the dashed line in the standings.
- **Team crests** are coloured discs drawn from each team's colour, with the league's logo images
  as the source when they load. Nothing breaks if an image is unavailable.

## Data

Teams, all 36 fixtures and the 32 played results were transcribed from
`playdurham.com/wiffleball`. The transcription was checked against the league's published
standings table: **all eight teams match on W-L-T, runs scored and runs allowed**, and the
rendered standings reproduce that table exactly.

`assets/js/data.js` holds the fallback copy. Once the database is seeded it takes over.

## Supabase

This site uses the **same Supabase project as the softball league**, scoped to the `2026-wiffle`
season. Nothing new to set up.

1. `supabase/seed.sql` loads the season and the eight teams
2. `supabase/seed_games.sql` loads all 36 fixtures with results

The schema itself already exists from the softball site. `supabase/schema.sql` is included only
for reference.

**Two deliberate choices worth knowing:**

- Wiffle teams are **not** added to the `organizations` table. That table is not season-scoped, so
  they would appear on the softball site's Non-Profit Partners page.
- `teams.league` is `NOT NULL` in the shared schema, so every wiffle team is filed as `A`. The site
  never reads or displays it.

The admin has no Partners tab for the same reason: organizations are shared and belong to softball.

## Images

The logo and hero currently load from `playdurham.com`, which stays online. To make the site fully
self-contained, drop local copies into `assets/Photos` and update `LOGO` and `HERO_PHOTO` at the
bottom of `assets/js/data.js`.

## The waiver

`assets/js/waiver.js` is the **softball waiver with the sport swapped**. It has not been written or
reviewed for this league. Have it looked at before collecting real signatures. Its version key is
`wiffle-2026-v1`, kept separate from the softball waiver so signatures never mix.
