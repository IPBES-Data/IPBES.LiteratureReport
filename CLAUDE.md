# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Generates bibliography reports for IPBES Zotero groups. For each group listed in [input/groups.csv](input/groups.csv) (columns: `name`, `id`), the pipeline downloads the Zotero library, resolves DOIs to OpenAlex works, computes metrics, and (eventually) renders per-group Quarto reports plus an index page.

The project is mid-refactor: it used to be an R package (`LitReport` / `IPBES.LiteratureReport`) and is being converted into a pure `targets` pipeline. Consequences a fresh Claude should know about:

- `DESCRIPTION`, `man/`, and most `pipeline_*` / old-style helper files have been deleted (visible as `D` in `git status`) but [NAMESPACE](NAMESPACE) still references the removed exports — it is stale and not currently used. Do not rely on it as a source of truth.
- Files in [R/](R/) are **not loaded as a package**. [_targets.R](_targets.R) sources every `*.R` in `R/` at pipeline start (see lines 7–15).
- Files ending in `.R.tofix` (e.g. [R/plot_top_country.R.tofix](R/plot_top_country.R.tofix)) are intentionally skipped by that `*.R$` glob — they are broken/WIP and excluded from sourcing.
- In [_targets.R](_targets.R), the plotting/report/index targets are commented out. The currently-live pipeline ends at `metrics`. When re-enabling, expect references to a `bibliography` target that no longer exists — current branching is over `group` / `zotero_group` / `zotero_works`.

## Running the pipeline

From R, in the repo root:

```r
targets::tar_make()         # run pipeline
targets::tar_visnetwork()   # inspect DAG
targets::tar_read(metrics)  # inspect a target
targets::tar_destroy()      # wipe _targets/ cache
```

Edit [input/groups.csv](input/groups.csv) to change which Zotero groups are processed. Dynamic branching maps one branch per row, so adding a row adds a branch without further code changes.

The README's "open `index.qmd` and render it" workflow refers to the old (package-era) flow and does not match the current `targets`-driven pipeline.

## Pipeline shape

[_targets.R](_targets.R):

1. `group_file` / `groups_df` / `group` — read [input/groups.csv](input/groups.csv) and fan out one branch per row.
2. `zotero_group` — [get_zotero_group()](R/get_zotero_group.R) downloads each Zotero group as CSV into `output/zotero_groups/IPBES_<name>_<id>/`. Returns the directory path; target `format = "file"`.
3. `zotero_works` — [get_works()](R/get_works.R) reads the Zotero CSV(s), extracts DOIs via `openalexPro::extract_doi()`, queries OpenAlex with `openalexPro::pro_query()` + `pro_fetch()`, writes to `output/zotero_works/<group>/`.
4. `metrics` — [get_metrics.R](R/get_metrics.R) computes per-group metrics.
5. Plot / report / index targets are commented out pending the refactor.

Outputs land under [output/](output/) in fixed subdirs (`zotero_groups/`, `zotero_works/`, `metrics/`, `report/`, ...). `get_zotero_group()` and `get_works()` `unlink()` their target directory before writing — re-runs are destructive by design.

## External credentials

- Zotero API key for private groups: stored via `keyring::key_get("API_zotero")` (see [R/get_zotero_group.R](R/get_zotero_group.R)). The fallback environment variable mentioned in some docstrings is `ZOTERO_API_KEY`.
- OpenAlex access uses `openalexPro` (the "pro" variant — not plain `openalexR`); follow its own auth conventions.

## Dependencies worth knowing

Non-CRAN / IPBES-internal packages used by the pipeline (declared in `tar_option_set(packages = ...)`): `openalexPro`, `zotFunc`. These must be installed from their respective sources before `tar_make()` will run.
