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
#' @param doi_candidates RDS file with the works found in OpenAlex for items
#'   without a DOI, as returned by [get_doi_candidates()]. Passed as
#'   `candidates` to the measures which have that argument.
#' @param extra_ids RDS file with the OpenAlex IDs in Extra, as returned by
#'   [get_extra_ids()]. Passed as `extra_ids` to the measures which have that
#'   argument.
#' @param metric_code Not used. Only passed so that targets reruns the metrics
#'   when a `R/met_*.R` file changes.
#'
#' @return Path to the RDS file. It contains a list with one element per
#'   metric group, each a list with one element per measure, the group
#'   `name`, `downloaded` (when the Zotero data was downloaded) and `items`, a
#'   tibble with `key`, `title` and `type` of all Zotero items.

get_metrics <- function(
  zotero_group,
  zotero_works,
  metric_names,
  doi_candidates = NULL,
  extra_ids = NULL,
  metric_code = NULL
) {
  zotero <- read_zotero(zotero_group)
  # column names as used by the measures, e.g. "Item Type" -> "Item.Type"
  names(zotero) <- make.names(names(zotero), unique = TRUE)

  works <- arrow::open_dataset(zotero_works)
  # further sources, passed to the measures which have an argument of that name
  sources <- list(
    candidates = if (!is.null(doi_candidates)) readRDS(doi_candidates),
    extra_ids = if (!is.null(extra_ids)) readRDS(extra_ids)
  )

  # Run metrics from config ------------------------------------------------

  result <- sapply(
    metric_names,
    function(group) {
      sapply(
        group,
        function(m) {
          f <- match.fun(m)
          args <- c(
            list(zotero = zotero, openalex = works),
            sources[intersect(names(sources), names(formals(f)))]
          )
          do.call(f, args)
        },
        simplify = FALSE
      )
    },
    simplify = FALSE
  )
  result$name <- basename(zotero_group)
  # when the Zotero data was downloaded (time of the CSV files)
  result$downloaded <- max(file.mtime(list.files(zotero_group, "[.]csv$", full.names = TRUE)))
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
