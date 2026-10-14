#' Problematic publication years
#'
#' Items whose date is missing (`missing`), from whose date Zotero could not
#' derive a year (`unparseable`), or whose year lies in the future
#' (`future`).
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `date`, `year` and `problem`
#' - `count`: number of items per problem (`missing`, `unparseable`,
#'   `future`)
#' - `pc`: percentage of all items per problem
met_meta_year <- function(
  zotero,
  ...
) {
  year <- suppressWarnings(as.integer(zotero$Publication.Year))

  problem <- dplyr::case_when(
    zotero$Date == "" ~ "missing",
    is.na(year) ~ "unparseable",
    year > as.integer(format(Sys.Date(), "%Y")) ~ "future",
    .default = as.character(NA)
  )

  metrics <- list()

  metrics$items <- tibble::tibble(
    key = zotero$Key,
    title = zotero$Title,
    date = zotero$Date,
    year = year,
    problem = problem
  )[!is.na(problem), ]

  metrics$count <- c(table(factor(
    problem,
    levels = c("missing", "unparseable", "future")
  )))
  metrics$pc <- 100 * metrics$count / nrow(zotero)

  return(metrics)
}
