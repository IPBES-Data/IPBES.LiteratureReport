#' Group activity
#'
#' Items added per month, and items added / modified in the 30 days before
#' the metrics were calculated.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `added_by_month`: tibble with `month`, `count` and `count_cumsum`
#' - `added_last_30d`: number of items added in the last 30 days
#' - `modified_last_30d`: number of items modified in the last 30 days
met_maint_activity <- function(
  zotero,
  ...
) {
  added <- as.Date(substr(zotero$Date.Added, 1, 10))
  modified <- as.Date(substr(zotero$Date.Modified, 1, 10))

  metrics <- list()

  metrics$added_by_month <- tibble::tibble(
    month = format(added, "%Y-%m")
  ) |>
    dplyr::count(
      month,
      name = "count"
    ) |>
    dplyr::mutate(
      count_cumsum = cumsum(count)
    )

  metrics$added_last_30d <- sum(added >= Sys.Date() - 30, na.rm = TRUE)
  metrics$modified_last_30d <- sum(modified >= Sys.Date() - 30, na.rm = TRUE)

  return(metrics)
}
