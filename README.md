# MealMesh – Surplus Food Redistribution Network

Providers (bakeries, grocers, canteens) post surplus food with a "usable by" window. Recipient
organizations browse listings ranked by urgency and claim them atomically (one recipient per listing).

**Team:** Nandika Gupta (PES2UG24CS303) · Tanvi Magalur (PES2UG24CS257) — Section E
**Stack:** PostgreSQL (Neon) for relational data · MongoDB for per-listing details (planned) · app layer (planned)

## Repo layout
| Path | What it is |
|---|---|
| `sql/01_schema.sql` | Tables, constraints, indexes, view, ALTER/DROP demos |
| `sql/02_functions_triggers.sql` | `claim_listing()` (row-locked atomic claim), validation + sync triggers, `expire_listings()` |
| `sql/03_seed.sql` | Sample users, listings, claims, reviews |
| `sql/04_queries.sql` | Joins, aggregates, nested queries, urgency ranking |
| `sql/05_tests.sql` | Cases that should fail (double claim, expired claim, premature review...) |
| `docs/` | Report PDF, ER diagram, relational schema |

## Run it
```bash
psql "$DATABASE_URL" -f sql/01_schema.sql
psql "$DATABASE_URL" -f sql/02_functions_triggers.sql
psql "$DATABASE_URL" -f sql/03_seed.sql
psql "$DATABASE_URL" -f sql/04_queries.sql
```
Or paste each file into the Neon SQL Editor. `01_schema.sql` drops and recreates all tables.

## Design notes
- **One recipient per listing:** partial unique index `uq_active_claim_per_listing` (non-cancelled claims only),
  so cancelling a claim re-opens the listing.
- **Atomic claiming:** `claim_listing()` locks the listing row with `SELECT ... FOR UPDATE`.
- **Reviews** are only accepted on `completed` claims (trigger).

## Roadmap
- [x] Schema, constraints, indexes, view
- [x] Functions, triggers, seed data, queries, tests
- [ ] MongoDB `listing_details` collection (photos, packaging notes, allergen tags) keyed by `listing_id`
- [ ] Backend API + simple UI (login by role, post, browse by urgency, claim, review)
- [ ] Redraw ER diagram with full attributes
