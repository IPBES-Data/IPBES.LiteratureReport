# _targets.R
# see https://github.com/ropensci/targets/discussions/1297 for long discussion

library(targets)
library(tarchetypes)

x <- list.files(
  "./R",
  pattern = "\\.R$",
  full.names = TRUE
) |>
  lapply(
    FUN = source,
    echo = FALSE
  )

targets::tar_option_set(
  packages = c(
    # The packages will be loaded befort the pipaline is run
    "dplyr",
    "ggplot2",
    "openalexPro",
    "quarto",
    "tibble",
    "zotFunc"
  ),
  imports = c(
    # The functions in these pacages are tracked for changes.
    # "knitr",
    # "dplyr",
    # "ggplot2",
  )
)

list(
  # Track input groups.yaml ------------------------------------------------

  tar_target(
    config_file,
    file.path("input", "config.yaml"),
    format = "file"
  ),

  # Define reports ---------------------------------------------------------

  tar_target(
    group_report_qmd,
    file.path("input", "group_report.qmd"),
    format = "file"
  ),

  tar_target(
    index_qmd,
    file.path("input", "index.qmd"),
    format = "file"
  ),

  # Read config entries ------------------------------------------

  tar_target(
    assessment,
    yaml::read_yaml(config_file)$assessments,
    iteration = "list"
  ),

  tar_target(
    metric_names,
    yaml::read_yaml(config_file)$metrics
  ),

  # Check Zotero group version (always), download only when it changed ----

  tar_target(
    zotero_version,
    zotFunc::get_group_version(assessment$id, api_key = zotero_api_key()),
    pattern = map(assessment),
    cue = tar_cue(mode = "always")
  ),

  tar_target(
    zotero_group,
    {
      zotero_version # dependency only: new version -> download again
      get_zotero_group(group = assessment)
    },
    pattern = map(zotero_version, assessment),
    format = "file"
  ),

  # Get Bibliographies from OpenAlex ---------------------------------------

  tar_target(
    zotero_works,
    get_works(zotero_group),
    pattern = map(zotero_group),
    format = "file"
  ),

  # Search OpenAlex for items without DOI (cached per item) -----------------

  tar_target(
    doi_candidates,
    get_doi_candidates(zotero_group),
    pattern = map(zotero_group),
    format = "file"
  ),

  # Look up the OpenAlex IDs in Extra ---------------------------------------

  tar_target(
    extra_ids,
    get_extra_ids(zotero_group),
    pattern = map(zotero_group),
    format = "file"
  ),

  # # Calculate metrics ------------------------------------------------------

  # all met_*.R files (measures and helpers), so that changes rerun metrics
  tar_target(
    metric_code,
    list.files("R", pattern = "^met_.*\\.R$", full.names = TRUE),
    format = "file",
    cue = tar_cue(mode = "always")
  ),

  tar_target(
    metrics,
    get_metrics(zotero_group, zotero_works, metric_names, doi_candidates, extra_ids, metric_code),
    pattern = map(zotero_group, zotero_works, doi_candidates, extra_ids),
    format = "file"
  ),

  tar_target(
    metric_docs,
    get_metric_docs(metric_names, metric_code)
  ),

  tar_target(
    metric_docs_file,
    {
      file <- file.path("output", "report", "metrics.md")
      dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
      writeLines(c("# Metrics", "", metric_docs), file)
      file
    },
    format = "file"
  ),

  # Reports ----------------------------------------------------------------

  tar_target(
    report_helpers,
    file.path("R", "report_helpers.R"),
    format = "file"
  ),

  # what each check does, without the technical result description
  tar_target(
    metric_docs_brief,
    get_metric_docs(metric_names, metric_code, result = FALSE)
  ),

  tar_target(
    group_report,
    render_report(
      qmd = group_report_qmd,
      output_file = file.path(
        "output",
        "report",
        paste0("IPBES_", assessment$name, "_", assessment$id, ".html")
      ),
      params = list(
        metrics = normalizePath(metrics),
        name = assessment$name,
        id = assessment$id,
        helpers = normalizePath(report_helpers),
        docs = metric_docs_brief
      ),
      title = paste("Zotero group", assessment$name)
    ),
    pattern = map(metrics, assessment),
    format = "file"
  ),

  tar_target(
    index,
    render_report(
      qmd = index_qmd,
      output_file = file.path("output", "report", "index.html"),
      params = list(
        metrics = normalizePath(metrics),
        reports = basename(group_report),
        names = vapply(assessment, `[[`, "", "name"),
        ids = vapply(assessment, `[[`, 0, "id"),
        helpers = normalizePath(report_helpers),
        docs = normalizePath(metric_docs_file)
      ),
      title = "IPBES Zotero group reports"
    ),
    format = "file"
  ),

  ###
  NULL
)
