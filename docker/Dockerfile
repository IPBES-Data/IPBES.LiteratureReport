# The IPBES Literature Report pipeline in a container: runs the pipeline
# regularly (and when triggered), and publishes changed reports, fixes and
# plugins by pushing them to GitHub. See docker/README.md.
# Versions: R and Quarto here (R must match renv.lock); the R packages are
# those in renv.lock. Rebuild after changing them.
ARG R_VERSION=4.6.1
FROM rocker/r-ver:${R_VERSION}

ARG QUARTO_VERSION=1.10.18

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

# R packages: exactly the versions in renv.lock (Linux binaries from Posit
# Package Manager, openalexPro and zotFunc from r-universe), restored into a
# fixed library; the project's renv uses the same library when the pipeline
# runs (RENV_PATHS_LIBRARY)
ENV RENV_PATHS_LIBRARY=/opt/renv/library RENV_CONFIG_CACHE_ENABLED=FALSE
WORKDIR /opt/renv/project
COPY renv.lock .Rprofile ./
COPY renv/activate.R renv/settings.json renv/
RUN Rscript -e 'renv::restore(prompt = FALSE)' \
  && Rscript -e 'for (p in c("targets", "tarchetypes", "dplyr", "ggplot2", "quarto", "knitr", "arrow", "jsonlite", "jsonvalidate", "yaml", "keyring", "ISOcodes", "countrycode", "httr2", "openssl", "withr", "htmltools", "reactable", "roxygen2", "openalexPro", "zotFunc")) library(p, character.only = TRUE)'

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
