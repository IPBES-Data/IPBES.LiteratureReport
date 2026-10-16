# The IPBES Literature Report pipeline in a container: runs the pipeline
# regularly (and when triggered), and publishes changed reports, fixes and
# plugins by pushing them to GitHub. See docker/README.md.
# Versions (set in docker-compose.yml; rebuild with `docker compose build`):
# R, the date of the CRAN snapshot (Posit Package Manager), Quarto, the minimum
# versions of openalexPro and zotFunc (both from r-universe)
ARG R_VERSION=4.6.1
FROM rocker/r-ver:${R_VERSION}

ARG CRAN_DATE=2026-10-16
ARG QUARTO_VERSION=1.10.18
ARG OPENALEXPRO_MIN=0.13.0
ARG ZOTFUNC_MIN=0.1.0

# CRAN packages as of CRAN_DATE, so that rebuilds give the same versions
RUN echo "options(repos = c(CRAN = 'https://p3m.dev/cran/__linux__/noble/${CRAN_DATE}'))" \
  >> "$(R RHOME)/etc/Rprofile.site"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    git zip python3 curl ca-certificates \
    libcurl4-openssl-dev libssl-dev libxml2-dev libsodium-dev libjq1 libglpk40 libuv1 libsecret-1-0 \
  && rm -rf /var/lib/apt/lists/*

# Quarto, for the reports
RUN curl -fsSL -o /tmp/quarto.deb \
    "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-$(dpkg --print-architecture).deb" \
  && apt-get update && apt-get install -y --no-install-recommends /tmp/quarto.deb \
  && rm -rf /tmp/quarto.deb /var/lib/apt/lists/*

# R packages of the pipeline and the reports (binaries from Posit Package Manager)
RUN install2.r --error --skipinstalled --ncpus -1 \
    targets tarchetypes dplyr tibble ggplot2 quarto knitr rmarkdown \
    arrow jsonlite jsonvalidate yaml keyring ISOcodes countrycode \
    httr2 openssl digest withr htmltools reactable roxygen2 remotes \
  && Rscript -e 'for (p in c("targets", "tarchetypes", "dplyr", "ggplot2", "quarto", "knitr", "arrow", "jsonlite", "jsonvalidate", "yaml", "keyring", "ISOcodes", "countrycode", "httr2", "openssl", "withr", "htmltools", "reactable", "roxygen2")) library(p, character.only = TRUE)' \
  && rm -rf /tmp/downloaded_packages

# the IPBES packages from r-universe (the newest versions, at least the
# minimum versions); the build fails if one does not load or is too old
RUN Rscript -e 'install.packages(c("openalexPro", "zotFunc"), repos = c("https://openalexpro.r-universe.dev", "https://rkrug.r-universe.dev", getOption("repos"))); library(openalexPro); library(zotFunc); stopifnot(packageVersion("openalexPro") >= Sys.getenv("OPENALEXPRO_MIN"), packageVersion("zotFunc") >= Sys.getenv("ZOTFUNC_MIN"))'

# the versions in this image (shown by GET /status)
RUN mkdir -p /opt/literature-report \
  && Rscript -e 'ip <- installed.packages(); writeLines(c(R.version.string, paste(ip[, "Package"], ip[, "Version"])), "/opt/literature-report/versions.txt")'

# the OpenAlex key from OPENALEX_API_KEY (openalexPro reads openalexPro.api_key)
RUN echo 'local({ k <- Sys.getenv("OPENALEX_API_KEY"); if (nzchar(k)) Sys.setenv(openalexPro.api_key = k) })' \
  >> "$(R RHOME)/etc/Rprofile.site"

COPY docker/update.sh docker/trigger.py /opt/literature-report/
RUN chmod +x /opt/literature-report/update.sh

WORKDIR /work
EXPOSE 8080
CMD ["/opt/literature-report/update.sh"]
