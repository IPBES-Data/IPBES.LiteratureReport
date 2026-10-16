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
4. renders one report per group and an index into `output/report/`,
5. publishes the proposed fixes per group and builds the Zotero plugins for
   the website.

Pushing `output/report/` to `main` publishes the reports (GitHub Action
[pages.yml](.github/workflows/pages.yml)).

The website is kept up to date by the GitHub Action
[update.yml](.github/workflows/update.yml): it runs the pipeline every 12
hours (and by hand, "Run workflow" on the Actions page), commits changed
reports to `main` and publishes them. It runs in the container image built by
[image.yml](.github/workflows/image.yml) from [docker/Dockerfile](docker/Dockerfile);
run image.yml by hand to pick up new versions of openalexPro or zotFunc. Needs
the repository secret `OPENALEX_API_KEY` (and `ZOTERO_API_KEY` for private
groups). The same image can also run as a service on a server, see
[docker/README.md](docker/README.md).

### Checks

```sh
Rscript tests/check_fixes.R        # one group (PAND); "all" for all groups
```

checks that every fix returns changes in the agreed form, that the published
proposals match [input/proposals.schema.json](input/proposals.schema.json)
(and that the schema refuses broken files), and that the fix app loads. It
needs the pipeline output.

### Configuration

[input/config.yaml](input/config.yaml):

- `assessments`: the Zotero groups (`name`, `id`).
- `metrics`: the measures to calculate, by section. Each measure is a function
  `met_*()` in `R/` and documents itself; the documentation of all measures is
  in `output/report/metrics.md` and in the index of the reports.

### Requirements

- R packages: fixed with [renv](https://rstudio.github.io/renv/) in
  `renv.lock` (CRAN packages from Posit Package Manager, the IPBES packages
  [openalexPro](https://github.com/IPBES-Data/openalexPro) and zotFunc from
  r-universe). In a new working copy, `renv::restore()` installs them; the
  container image uses the same versions. After updating packages,
  `renv::snapshot()` and commit `renv.lock`.
- [Quarto](https://quarto.org) for the reports.
- A Zotero API key with read access to the groups, in the keyring:
  `keyring::key_set("API_zotero")`.
- An OpenAlex API key, as set up for openalexPro.

## Fixing problems in Zotero

Two Zotero 10 plugins fix the problems found by the pipeline, directly in
Zotero. They are in `plugins/` as git submodules, and the pipeline publishes
them on the website (section *Zotero plugins* of the index), from where
installed copies update themselves:

- [Zotero Fix Proposals](https://github.com/IPBES-Data/zotero-fix-proposals)
  shows the fixes proposed for a group (Tools → Fix Proposals…), read from
  `fixes/` on the website.
- [Zotero Safe Edit](https://github.com/IPBES-Data/zotero-safe-edit) checks
  every change (automatic sync off, fresh backup, allowed fields, unchanged
  old value), asks for approval, writes, logs and undoes.

To publish a new plugin version: update its submodule to the release tag
(`git -C plugins/<plugin> fetch --tags && git -C plugins/<plugin> checkout v<version>`),
run the pipeline and push.

The local Shiny app in `fix_app/` (`source("R/run_fix_app.R"); run_fix_app()`)
does the same for R users and developers.

### Proposed fixes on the website

For each group, the pipeline writes the proposed fixes to
`output/report/fixes/<group>.json` (with `index.json`, and `schema.json`
describing the format), published at
<https://ipbes-data.github.io/IPBES.LiteratureReport/fixes/>.

Some fixes build on others: once an item has a DOI, the fixes with values
from OpenAlex find it only after the next sync and pipeline run.

## Licence

The code is under the MIT licence, see [LICENSE](LICENSE). The reports and
data published on the website (reports, `fixes/`) are under
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/): no rights
reserved.
