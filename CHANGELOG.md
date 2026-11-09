# Changelog

Versions of the pipeline, the fix app and the website (the Zotero plugins
have their own versions, see `plugins/`).

## Unreleased

- "DOI points to a different publication": if only the year differs (the
  titles match), the fix offers the date from OpenAlex as an alternative to
  removing the DOI
- The proposals files contain the address of the GitHub Actions page from
  which the report can be run again (`update`, optional in the schema);
  Zotero Fix Proposals 0.1.11 (included) links it ("Update the fixes")

## 0.5.0

- DOIs which OpenAlex has under another DOI (e.g. old SICI DOIs like
  `10.1890/1540-9295(2007)5[475:NCNCAE]2.0.CO;2`) count as found and are
  matched with their work; works the lookup of all DOIs missed are found too
  (#10)
- New check "DOI which does not exist" (doi.org), with a fix: the DOI
  without extra characters at the end where that exists, otherwise an empty
  DOI field (#13)
- New fix for "DOI points to a different publication": empty the DOI field
  (not selected at the start) (#16)
- "DOI not found in OpenAlex" lists only DOIs which exist
- Zotero plugins: Safe Edit 0.2.2 and Fix Proposals 0.1.10, which work with
  all Zotero 10 releases (before: only 10.0.x)
- Branch `main` protected: changes through pull requests from `dev`; only the
  automatic report updates push directly

## 0.4.0

- Automatic updates: GitHub Actions run the pipeline every 12 hours (and by
  hand), commit changed reports and publish them; the pipeline runs in a
  container image built from docker/Dockerfile (ghcr.io)
- renv: the R packages are fixed in renv.lock, the same locally, in the image
  and in the Actions
- Docker service as an alternative on a server (regular runs, trigger via
  POST /update)
- Public groups work without a Zotero API key; the pipeline's cache works in
  any location (relative paths)

## 0.3.0

- targets pipeline (was an R package up to 0.2.0): Zotero groups, OpenAlex
  works and DOI search, `met_*` measures, a report per group and an index
- Fixes: proposed per group, published as JSON (`fixes/`) for the Zotero
  plugins, and in the local fix app
- Zotero plugins Zotero Safe Edit and Zotero Fix Proposals as submodules,
  built and published on the website, with automatic updates
- Version, source code link, DOI and date of the Zotero data on the website;
  licences in the footer: code MIT, reports and data CC0 1.0
