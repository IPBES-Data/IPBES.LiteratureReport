#' Calculate the metrics of a Zotero group
#'
#' Runs each measure named in `metric_names` on the Zotero items and the
#' OpenAlex works of one group and saves the results as an RDS file in
#' `output/metrics/`.
#'
#' @param zotero_group Directory with the Zotero CSV files, as returned by
#'   [get_zotero_group()].
#' @param zotero_works Directory with the OpenAlex works parquet dataset, as
#'   returned by [get_works()].
#' @param metric_names Named list of metric groups, each a character vector
#'   of `met_*` function names (`metrics` in `input/config.yaml`). Each
#'   measure is called as `f(zotero = zotero, openalex = works)`.
#' @param metric_code Not used. Only passed so that targets reruns the metrics
#'   when a `R/met_*.R` file changes.
#'
#' @return Path to the RDS file. It contains a list with one element per
#'   metric group, each a list with one element per measure, the group
#'   `name`, and `items`, a tibble with `key`, `title` and `type` of all
#'   Zotero items.

get_metrics <- function(
  zotero_group,
  zotero_works,
  metric_names,
  metric_code = NULL
) {
  zotero <- list.files(
    zotero_group,
    pattern = "\\.csv$",
    full.names = TRUE
  ) |>
    lapply(read.csv, colClasses = "character") |>
    dplyr::bind_rows()

  works <- arrow::open_dataset(zotero_works)

  # Run metrics from config ------------------------------------------------

  result <- sapply(
    metric_names,
    function(group) {
      sapply(
        group,
        function(m) match.fun(m)(zotero = zotero, openalex = works),
        simplify = FALSE
      )
    },
    simplify = FALSE
  )
  result$name <- basename(zotero_group)
  result$items <- tibble::tibble(
    key = zotero$Key,
    title = zotero$Title,
    type = zotero$Item.Type
  )

  class(result) <- c(class(result), "bibliography_metrics")

  # Save Metrics -----------------------------------------------------------

  dir <- file.path("output", "metrics")

  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  file <- file.path(dir, paste0(basename(zotero_group), ".rds"))

  saveRDS(result, file = file)

  return(file)
}
