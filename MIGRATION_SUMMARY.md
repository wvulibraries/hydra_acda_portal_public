# Fedora → PostgreSQL Migration

**Status: Complete.** This document explains about what changed, why, and the handful of non-obvious things.

The original plan is in `MODERNIZATION.md` which was written as a proposal before any work started, and the real migration didn't follow its phase numbers exactly — this document describes what was actually built. 

---

## In Simplest Terms

This app used to store its records in Fedora 6 (a preservation-grade RDF object store) via ActiveFedora, with Solr/Blacklight on top for search. Fedora's preservation and versioning features were never actually used — this app is a metadata aggregator fed by CSV imports from partner institutions, not a true digital-preservation repository. So Fedora, ActiveFedora, and the whole RDF/LDP stack were removed. Records now live in a plain PostgreSQL table (`congressional_records`) via a normal ActiveRecord model (`CongressionalRecord`), files live in Rails ActiveStorage, and Solr/Blacklight are unchanged — they still do search exactly as before. Background jobs run on GoodJob (Postgres-backed), not Sidekiq/Redis — that switch happened before this migration started.

```
Before:  CSV (partners) → Bulkrax → ActiveFedora → Fedora 6 (RDF/LDP) → Solr → Blacklight
After:   CSV (partners) → Bulkrax → ActiveRecord  → PostgreSQL         → Solr → Blacklight
```

---

## What changed

### Data model

- `Acda` (the old ActiveFedora model, ~27 RDF properties) is gone. `CongressionalRecord` (`hydra/app/models/congressional_record.rb`) is a plain ActiveRecord model backed by the `congressional_records` table. Every field was cross-checked field-by-field against the old `acda.rb`, the old Solr indexer, and the Bulkrax CSV field mapping before the schema was written, so nothing was silently dropped.
- The primary key is still a string (not an auto-increment integer), so old Fedora-style IDs keep working. For a brand new record with no explicit id, `CongressionalRecord#assign_id` mints one from the `identifier` field (strips protocol/domain, swaps URL-unsafe characters for `_`). **If `identifier` is blank, this produces an empty string, not a real id** — see Note #2 below.
- Permissions (`read_groups`/`edit_groups`/etc.) now live in their own `access_controls` table (one row per grant: agent type, agent name, access level) instead of Fedora's RDF-based permission properties. `visibility` is a computed method derived from that table, matching the old Hydra behavior exactly.
- Files (images, PDFs, audio, video, thumbnails) live in ActiveStorage (`has_one_attached` / `has_many_attached` on `CongressionalRecord`) instead of being Fedora-managed binaries. `ImageViewerController`, `PdfViewerController`, `VideoPlayerController`, and `AudioPlayerController` all serve from ActiveStorage now. (`AudioPlayerController` didn't actually exist before this migration — the route had been pointing at a 404 for a long time; it was added as part of this work.)

### Search indexing (Solr)

- `CongressionalRecord#to_solr` builds the same Solr document shape the old `Acda#to_solr`/indexer did — verified field-for-field.
- **Indexing to Solr is no longer automatic via ActiveFedora magic.** A `SolrIndexJob` (GoodJob) now runs `after_commit` on every `CongressionalRecord` create/update/destroy and pushes the document to Solr. If you ever see new or edited records missing from search, check that this job ran — look in GoodJob for `SolrIndexJob` failures before assuming anything else is broken.
- There's also a manual rake task, `rake congressional_records:reindex`, for bulk/backfill reindexing (e.g. after a schema or `to_solr` change). It defaults to a dry run — pass `DRY_RUN=false` to actually write.
- `has_model_ssim` now indexes as `CongressionalRecord` instead of `Acda`. The search filter (`SearchBuilder#show_only_congressional_records`) only matches that value now.

### Bulkrax CSV import

Bulkrax (the batch import gem) assumes an ActiveFedora/Hyrax-style model. Making it work against a plain ActiveRecord model required a custom factory, `Bulkrax::CongressionalRecordFactory` (`hydra/app/factories/bulkrax/congressional_record_factory.rb`), which overrides several places where Bulkrax's defaults assume ActiveFedora. Three specific incompatibilities, found by actually running real imports, are documented inline in that file's header comment and worth knowing about:

1. Bulkrax's default `permitted_attributes` calls `klass.properties.keys` (ActiveFedora-only) — overridden to use `column_names`.
2. Bulkrax's default create path mass-assigns permission attributes before the record is saved, but our permission setters need the record's id to already exist (foreign key to `access_controls`) — the custom `#create` splits permission attributes out and applies them after the initial save.
3. Bulkrax's `field_supported?`/`field_multi_value?` (used for every single CSV column on every import) also assume `klass.properties`. These are overridden to check real AR columns instead.

### Infrastructure

- The Fedora Docker service (`fcrepo`), `Dockerfile.fcrepo`, `fcrepo/` config directory, and `config/fedora.yml` are all deleted — nothing in the app talks to Fedora anymore.
- The `active-fedora`, `active-triples`, `hydra-head`, `jettywrapper`, and `fcrepo_wrapper` gems are removed from the Gemfile.
- `cancancan` (authorization) used to come in transitively through `hydra-access-controls`; it's now an explicit Gemfile dependency since that transitive path is gone.
- The `hydra/import/` directory (old Fedora-era cron/delete/migrate scripts) is deleted — every file in it either required `active_fedora` directly or called classes that no longer exist.
- `scripts/fast-reset.sh` no longer tries to clear a Fedora project; it only resets Postgres.
- Redis and Sidekiq were already gone before this migration started (an earlier, separate piece of work moved background jobs to GoodJob, which uses Postgres, not Redis, for its queue).

---

## Notes

These were all found the hard way, by running a real Bulkrax CSV import end-to-end against a freshly wiped database. If something in the import pipeline seems to be failing "for no reason," check this list before going further.


**1. Re-importing the same CSV through a new importer can try to create a duplicate id instead of updating.**
Bulkrax's own "does this record already exist?" check (`search_by_identifier`) matches on `bulkrax_identifier`, Bulkrax's own internal field — not on the real-world `dcterms:identifier` from the CSV. `bulkrax_identifier` is scoped to a single importer run (format `b-<importer_id>-<row>`), so a brand-new importer run against already-imported data always gets a *new* `bulkrax_identifier` and never matches the existing row — even though `CongressionalRecord`'s actual primary key is derived from the real identifier and would collide. `CongressionalRecordFactory#find` has a `find_by_computed_id` fallback that checks the real identifier field directly, specifically to handle this. If you ever see `ActiveRecord::RecordNotUnique` on `congressional_records_pkey` during an import, this is almost certainly why — check that `find_by_computed_id` is still in place and still being reached.

**2. An empty-string `identifier` produces an empty-string primary key — not an error.**
`generate_id_from_identifier` returns `''` if `identifier` is blank. That's "faithful" to the pre-migration behavior (it was ported verbatim), but it means a row can genuinely end up with `id = ''` in Postgres, which then collides with any other row that also computes an empty id. If you ever see a mysterious record with `id: ''`, or a `RecordNotUnique` error with `Key (id)=() already exists`, this is why. The real fix is making sure `identifier` is always populated before import — this is a known, pre-existing limitation, not something newly introduced. 

No random ID or UUID gets generated as a fallback — this isn’t a bug that “almost” assigns something sensible, it just literally sets id = '' and saves. This also isn’t limited to a nil identifier: it can also happen if identifier is present but made up only of characters the cleanup strips out (slashes, colons, ?, %, &, =, #, +, underscores, periods) — e.g. an identifier of just "///" cleans down to nothing and also produces ''. And this behavior predates this migration entirely: it was ported from the old Acda#assign_id, so Fedora-era records had the exact same soft spot. It only became visible during this migration’s testing because Postgres actually enforces primary-key uniqueness — Fedora apparently didn’t complain the same way about blank/duplicate ids.

**3. Solr indexing is not automatic unless the `SolrIndexJob` hook is present and GoodJob is running.**
Covered above, repeating here because it's the single most likely thing to look broken after any future deploy: if `after_commit :enqueue_solr_index` ever gets removed from `CongressionalRecord`, or GoodJob stops processing its queue, records will save fine in Postgres and simply never show up in search, with no error anywhere obvious. Check GoodJob first.

**4.**`field_supported?` can silently skip every field, with no error.**

The original check was `model.method_defined?(field)` - this asks "has Rails *already generated* this attribute method?" not "does this column exist?". Rails generates attribute methods lazily, the first time a model is touched in a process. A freshly started GoodJob worker that hasn't used `CongressionalRecord` yet will get `false` back for a column that's completely real - and since `field_supported? == false` just means "skip this field" (not an error), the import reports success while quietly producing records with most fields blank.

Fixed by checking the schema directly instead: `model.column_names.include?(field.to_s)`.

**Symptom to watch for:** import succeeds, but records come back with most real fields (title, creator, date, etc.) blank, and nothing in the logs explains why.


---

## Verification performed

Before calling this migration done, the following was run end-to-end against a freshly wiped database:

- Full `rspec spec/` suite passing.
- Manual HTTP checks on home page, catalog search, and individual record show pages.
- A real Bulkrax CSV import, run from scratch, including hitting and fixing all three notes listed above as they occurred for real (not hypothetically) — followed by confirming the imported records were both correctly saved in Postgres *and* visible in Solr search without any manual reindex step.



## Migrating the dev VM's real Fedora data to Postgres

**Do this before deploying the current `feature/postgres-migration` branch tip.**
Back up the Postgres database and the Fedora data volume first, take snapshot of VM - standard precaution, not optional, given this writes real data.

1. On the VM, check out commit `bc31eda` from the `feature/postgres-migration` branch (the commit where Acda, active-fedora, the migrate/migrate_files rake tasks, and the fcrepo Docker service all still present and working together).
2. Bring up the stack with `docker-compose.dev.yml` (Fedora and Postgres both need to be running - this reads from Fedora and writes to Postgres).
3. `bin/rails db:migrate` - adds the congressional_records/access_controls/ActiveStorage tables. Does not touch or drop anything existing.
4. Dry-run the metadata migration first: `rake congressional_records:migrate` (DRY_RUN defaults to true). Check the printed counts look right (compare `created` + `updated` to your known Acda record count).
5. Run it for real: `rake congressional_records:migrate DRY_RUN=false`.
6. Verify: `Acda.count` should equal `CongressionalRecord.count`.
7. Dry-run the file migration: `rake congressional_records:migrate_files` (also DRY_RUN=true by default). This step depends on step 5 already being done - it skips any record it can't find in `congressional_records` yet.
8. Run it for real: `rake congressional_records:migrate_files DRY_RUN=false`.
9. Spot-check a handful of real records in the app - metadata, permissions/visibility, and that images/PDFs/audio/video actually load. Counts matching isn't enough on its own.
10. Dry-run the reindex: `rake congressional_records:reindex`.
11. Run it for real: `rake congressional_records:reindex DRY_RUN=false`.
12. Confirm search actually works in the UI for records you just migrated - not just that the task reported 0 errors.
13. Only after 6, 9, and 12 are all confirmed clean: deploy the current `feature/postgres-migration` branch tip (Fedora fully removed) to replace this checkpoint.
14. Do not decommission/delete the actual Fedora data on this VM until the app has been running on the final branch for a while and you're confident nothing was missed - keep it as a fallback, don't rely on counts alone.
