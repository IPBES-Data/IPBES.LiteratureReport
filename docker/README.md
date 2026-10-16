# The pipeline as a Docker service

The container keeps the reports, the proposed fixes and the plugins on the
website up to date:

- every `INTERVAL_MINUTES` (default 30, set in `docker-compose.yml`; counted
  from the end of the previous run) it updates the code from GitHub and
  runs the pipeline. Only groups whose version in Zotero changed (e.g. after
  fixes were synced) are downloaded and recalculated, so a run without
  changes takes seconds;
- changed files in `output/report/` are committed ("Update reports
  (automatic)") and pushed to `main`, which publishes them on GitHub Pages;
- a run can be triggered: `POST /update` on port 8080 (several requests lead
  to one run, at most every `MIN_GAP_MINUTES`); `GET /status` shows the
  state of the last run.

## Set up

1. A GitHub token (fine-grained): *Contents* read and write on
   `IPBES-Data/IPBES.LiteratureReport` only (the plugin submodules are public).
2. In this directory: `cp .env.example .env` and fill in the Zotero and
   OpenAlex keys, the GitHub token and a trigger token (any long random
   string, e.g. `openssl rand -hex 32`).
3. `docker compose up -d --build`

The first start clones the repository into `data/` (or `DATA_DIR`) and runs
the whole pipeline: downloading all groups and searching OpenAlex takes long
the first time. To start from existing data instead, copy `output/` and
`_targets/` of a working copy into `data/IPBES.LiteratureReport/` after the
clone (stop the container first).

## Use

```sh
docker compose logs -f                       # what it does
curl http://localhost:8080/status            # state of the last run
curl -X POST -H "Authorization: Bearer <TRIGGER_TOKEN>" http://localhost:8080/update
```

The log of the last pipeline run is in `data/state/last.log`.

For access from outside (e.g. the plugins of other users), put the port
behind HTTPS (a reverse proxy) and keep the trigger token secret.

## Versions

The pipeline code is updated from GitHub before every run. R and the
packages are fixed in the image: the R packages are those in `renv.lock` (the
same as in a local working copy), R and Quarto are set in `Dockerfile` (R must
match the R version in `renv.lock`). After changing them: `docker compose
build`, `docker compose up -d`. The versions in the image are listed in
`/opt/literature-report/versions.txt`; `GET /status` shows R, openalexPro,
zotFunc and targets.

## Notes

- The automatic commits go to `main`: merge `main` into `dev` before working
  on `dev`.
