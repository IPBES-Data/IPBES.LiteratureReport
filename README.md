# IPBES Literature Report

Reports on the quality of the Zotero groups of the IPBES assessments: which
items have DOIs, which DOIs are wrong or in the wrong form, missing dates,
duplicates, retracted publications and more, with links to fix each item in
Zotero. A local app proposes fixes and sends them to Zotero for approval.

The reports are published on GitHub Pages:
<https://ipbes-data.github.io/IPBES.LiteratureReport/>

## Running the pipeline

The reports are built by a [targets](https://docs.ropensci.org/targets/)
pipeline ([_targets.R](_targets.R)). In R, in this directory:

```r
targets::tar_make()
```

For each group it

1. downloads the Zotero group (only when it changed since the last run),
2. looks up the DOIs in OpenAlex, and searches OpenAlex by title for items
   without a DOI,
3. calculates the measures (`R/met_*.R`),
4. renders one report per group and an index into `output/report/`.

Pushing `output/report/` to `main` publishes the reports (GitHub Action
[pages.yml](.github/workflows/pages.yml)).

### Configuration

[input/config.yaml](input/config.yaml):

- `assessments`: the Zotero groups (`name`, `id`).
- `metrics`: the measures to calculate, by section. Each measure is a function
  `met_*()` in `R/` and documents itself; the documentation of all measures is
  in `output/report/metrics.md` and in the index of the reports.

### Requirements

- R packages: arrow, dplyr, ggplot2, htmltools, httr2, ISOcodes, jsonlite,
  keyring, quarto, reactable, roxygen2, shiny, targets, tibble, yaml, and the
  IPBES packages [openalexPro](https://github.com/IPBES-Data/openalexPro) and
  zotFunc.
- [Quarto](https://quarto.org) for the reports.
- A Zotero API key with read access to the groups, in the keyring:
  `keyring::key_set("API_zotero")`.
- An OpenAlex API key, as set up for openalexPro.

## Fixing problems: the fix app

```r
source("R/run_fix_app.R")
run_fix_app()
```

The app runs on the computer on which Zotero runs. It proposes fixes for
problems found by the pipeline (DOIs in the wrong field or form, ISO language
codes, dates and journal details from OpenAlex, DOIs found in OpenAlex,
OpenAlex IDs in Extra, ISSNs, …) and sends them to Zotero, where every change
is shown and has to be approved. Changes are logged and can be undone.

Writing to Zotero is done only by the Zotero plugin
[Zotero Safe Edit](https://github.com/IPBES-Data/zotero-safe-edit), which
checks every change (registered app, automatic sync off, fresh backup,
allowed fields, unchanged old value, batch limit). Set up:

1. Install the plugin in Zotero 10 and allow the fields to be fixed in
   Settings → Safe Edit (e.g. `DOI, language, date, publicationTitle, volume,
   issue, pages, extra, ISSN`).
2. Switch off automatic sync in Zotero (Settings → Sync).
3. Start the app, click *Register this app* and confirm in Zotero.
4. Make a backup of the group (Status tab), then work through the fixes.
   Sync by hand when done.

Some fixes build on others: once an item has a DOI, the fixes with values
from OpenAlex find it only after the next sync and pipeline run.

## Licence

MIT, see [LICENSE](LICENSE).
