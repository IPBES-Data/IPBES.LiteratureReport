# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Generates quality reports for the Zotero groups of the IPBES assessments. For each group listed under `assessments` in [input/config.yaml](input/config.yaml) (`name`, `id`), the `targets` pipeline downloads the Zotero library, resolves DOIs to OpenAlex works, computes the `met_*` measures, and renders per-group Quarto reports plus an index into `output/report/` (published via GitHub Pages). A local Shiny app ([fix_app/](fix_app/)) proposes fixes and writes them through the Zotero Safe Edit plugin.

It used to be an R package; the package files (`DESCRIPTION`, `NAMESPACE`, `man/`, vignettes, old plot and helper functions) have been removed. Things a fresh Claude should know:

- Files in [R/](R/) are **not loaded as a package**. [_targets.R](_targets.R) sources every `*.R` in `R/` at pipeline start.
- `output/` is not in git except `output/report/` (the published reports); the other subdirectories are caches and intermediate results.

## Running the pipeline

From R, in the repo root:

```r
targets::tar_make()         # run pipeline
targets::tar_visnetwork()   # inspect DAG
targets::tar_read(metrics)  # inspect a target
targets::tar_destroy()      # wipe _targets/ cache
```

Edit `assessments` in [input/config.yaml](input/config.yaml) to change which Zotero groups are processed, and `metrics` to change which measures are calculated. Dynamic branching maps one branch per assessment, so adding an entry adds a branch without further code changes.


## Pipeline shape

[_targets.R](_targets.R):

1. `config_file` / `assessment` / `metric_names` — read [input/config.yaml](input/config.yaml); `assessment` (`iteration = "list"`) fans out one branch per group.
2. `zotero_version` — always runs; checks each group's library version with `zotFunc::get_group_version()`.
3. `zotero_group` — [get_zotero_group()](R/get_zotero_group.R) downloads each Zotero group as CSV into `output/zotero_groups/IPBES_<name>_<id>/`, only when `zotero_version` changed. Returns the directory path; target `format = "file"`.
4. `zotero_works` — [get_works()](R/get_works.R) reads the Zotero CSV(s), extracts DOIs via `openalexPro::extract_doi()`, queries OpenAlex with `openalexPro::pro_query()` + `pro_fetch()`, writes to `output/zotero_works/<group>/`.
5. `doi_candidates` — [get_doi_candidates()](R/get_doi_candidates.R) searches OpenAlex by title for items without a DOI (one request per item) into `output/doi_candidates/<group>.rds`; results are cached per item (key + title), so re-runs only search new or changed items. Delete the file to search again.
6. `extra_ids` — [get_extra_ids()](R/get_extra_ids.R) looks up the `OpenAlex: W…` lines in Extra in OpenAlex (one `pro_query()`/`pro_fetch()` for all IDs; IDs not returned are not in OpenAlex) into `output/extra_ids/<group>.rds`.
7. `metrics` — [get_metrics()](R/get_metrics.R) runs the `met_*` measures listed in the config (one file each in `R/met_*.R`, shared helpers in [R/met_helpers.R](R/met_helpers.R)). `metric_code` tracks those files. Measures are called with `zotero` and `openalex`; those with a `candidates` or `extra_ids` argument also get the DOI candidates or the OpenAlex IDs in Extra.
8. `proposals` / `proposals_index` — [export_proposals()](R/export_proposals.R) runs all fixes ([fix_table()](R/fix_table.R)) per group and writes the proposed changes as JSON to `output/report/fixes/<group>.json` (plus `index.json` and `schema.json`), checked against [input/proposals.schema.json](input/proposals.schema.json). They are read by the Zotero plugin which shows the fixes.
9. `metric_docs` / `metric_docs_file` — [get_metric_docs()](R/get_metric_docs.R) combines the roxygen docs of the measures into `output/report/metrics.md`.
10. `plugin_sources` / `plugins` — [build_plugins()](R/build_plugins.R) builds the two Zotero plugins (git submodules `plugins/zotero-safe-edit`, `plugins/zotero-fix-proposals`, pinned to release tags) into `output/report/plugins/<plugin>/` with `updates.json` (installed copies update from there) and `plugins.json` for the index page.
11. `group_report` / `index` — [render_report()](R/render_report.R) renders [input/group_report.qmd](input/group_report.qmd) per group and [input/index.qmd](input/index.qmd) into `output/report/`, using [R/report_helpers.R](R/report_helpers.R).

Outputs land under [output/](output/) in fixed subdirs (`zotero_groups/`, `zotero_works/`, `metrics/`, `report/`, ...). `get_zotero_group()` and `get_works()` `unlink()` their target directory before writing — re-runs are destructive by design.

## Checks

`Rscript tests/check_fixes.R` (or `… all`): fixes return the agreed columns, exported proposals validate against the schema, the fix app loads. Needs the pipeline output in `output/`. The two Zotero plugins have their own tests (`node --test …`, `tests/zotero/run.sh`, which runs inside a separate Zotero instance).

## Docker service

[docker/](docker/): `Dockerfile` + `docker-compose.yml` run the pipeline as a service (clone/pull the repo into a volume, `tar_make()` every `INTERVAL_MINUTES` or on `POST /update`, commit and push changes in `output/report/` to `main`). Keys come from `docker/.env` (`ZOTERO_API_KEY`, `OPENALEX_API_KEY`, `GITHUB_TOKEN`, `TRIGGER_TOKEN`); `zotero_api_key()` falls back to `ZOTERO_API_KEY` when there is no keyring. `.dockerignore` keeps the build context to the two scripts.

## External credentials

- Zotero API key for private groups: stored via `keyring::key_get("API_zotero")` (see [R/get_zotero_group.R](R/get_zotero_group.R)). The fallback environment variable mentioned in some docstrings is `ZOTERO_API_KEY`.
- OpenAlex access uses `openalexPro` (the "pro" variant — not plain `openalexR`); follow its own auth conventions.

## Dependencies worth knowing

Non-CRAN / IPBES-internal packages used by the pipeline (declared in `tar_option_set(packages = ...)`): `openalexPro`, `zotFunc`. These must be installed from their respective sources before `tar_make()` will run.

## Zotero plugins

Developed in their own repos (public, `dev` → `main`, tags `v<version>`); here only as submodules at the released tag. To publish: move the submodule to the new tag, run the pipeline, commit and push. Clone this repo with `--recurse-submodules` (or `git submodule update --init`) — the pipeline needs the plugin sources.

## Fix app (not part of the pipeline)

`run_fix_app()` ([R/run_fix_app.R](R/run_fix_app.R)) starts a local Shiny app ([fix_app/](fix_app/)) which proposes fixes for problems found by the metrics and sends them to Zotero through the **Zotero Safe Edit** plugin (separate repo `IPBES-Data/zotero-safe-edit`, Zotero 10). The plugin does all checks (token, auto-sync off, fresh backup, allowed fields, expected old value, batch limit), shows the approval dialog, writes, and keeps the log; the app stores nothing.

- Client functions `se_*()`: [fix_app/R/safe_edit_client.R](fix_app/R/safe_edit_client.R); token in the keyring as `zotero_safe_edit_token` (`se_register()` stores it).
- Fixes are `fix_*(m, group_id)` functions in `R/` (shared with the pipeline, which publishes their proposals), listed in [fix_table()](R/fix_table.R); returning `group_id, item_key, title, field, old, new, reason, proposed, note` (optionally `doi`, for the DOI/OpenAlex links when the field is not `DOI`; `choice`, alternatives of which only one can be selected; `preselect`; `append`, a line to add, based on the current value in Zotero); register new ones there. Field names are Zotero field names (`DOI`, `extra`, …), and the field must be allowed in the plugin settings.
- The app must run on the same computer as Zotero.
