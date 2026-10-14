#' Open access status
#'
#' OpenAlex open access status (gold, diamond, green, hybrid, bronze, closed)
#' of the works, overall and per publication year.
#'
#' @param openalex OpenAlex works (arrow dataset).
#' @param ... Not used. Takes `zotero` when called by [get_metrics()].
#'
#' @return A list with
#' - `total`: tibble with `oa_status`, `count` and `pc`
#' - `by_year`: tibble with `year`, `oa_status` and `count`
met_prof_oa <- function(
  openalex,
  ...
) {
  works <- openalex |>
    dplyr::select(
      publication_year,
      open_access
    ) |>
    dplyr::collect()

  oa <- tibble::tibble(
    year = as.integer(works$publication_year),
    oa_status = works$open_access$oa_status
  )

  metrics <- list()

  metrics$total <- oa |>
    dplyr::count(
      oa_status,
      name = "count",
      sort = TRUE
    ) |>
    dplyr::mutate(
      pc = 100 * count / sum(count)
    )

  metrics$by_year <- oa |>
    dplyr::count(
      year,
      oa_status,
      name = "count"
    )

  return(metrics)
}
