#' Author countries
#'
#' Number of works with at least one author affiliated with an institution in
#' a country, per country (ISO 3166-1 alpha-2 codes from OpenAlex).
#'
#' @param openalex OpenAlex works (arrow dataset).
#' @param ... Not used. Takes `zotero` when called by [get_metrics()].
#'
#' @return A list with
#' - `by_country`: tibble with `country` and `count`
#' - `count_no_country`: number of works without any country
met_prof_countries <- function(
  openalex,
  ...
) {
  authorships <- openalex |>
    dplyr::select(
      authorships
    ) |>
    dplyr::collect() |>
    dplyr::pull(
      authorships
    )

  countries <- lapply(
    authorships,
    function(a) unique(unlist(a$countries))
  )

  metrics <- list()

  metrics$by_country <- tibble::tibble(
    country = as.character(unlist(countries))
  ) |>
    dplyr::count(
      country,
      name = "count",
      sort = TRUE
    )

  metrics$count_no_country <- sum(lengths(countries) == 0)

  return(metrics)
}
