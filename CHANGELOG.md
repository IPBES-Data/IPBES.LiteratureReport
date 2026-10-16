# Changelog

Versions of the pipeline, the fix app and the website (the Zotero plugins
have their own versions, see `plugins/`).

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
