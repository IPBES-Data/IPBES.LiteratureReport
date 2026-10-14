#' Publication years
#'
#' Number of items per publication year, with cumulative counts. Items
#' without a year are counted as `NA`.
#'
#' @param ... One or two data sources: the Zotero items (data frame) and / or
#'   the OpenAlex works (arrow dataset). With two, the measure is computed for
#'   each source and returned as a list named after the arguments.
#'
#' @return A list with
#' - `by_year`: tibble with `year`, `count`, proportion `p`, `count_cumsum`
#'   and `p_cumsum`
met_prof_year <- function(
  ...
) {
  if (...length() == 2) {
    # two sources: run once per source, keeps names (zotero / openalex)
    return(per_source(met_prof_year, ...))
  }
  if (...length() != 1) {
    stop("met_prof_year() takes one or two data arguments, got ", ...length())
  }

  bib <- as_bib(..1)

  metrics <- list()

  metrics$by_year <- bib |>
    dplyr::count(
      year,
      name = "count"
    ) |>
    dplyr::arrange(
      year
    ) |>
    dplyr::mutate(
      p = count / sum(count),
      count_cumsum = cumsum(count),
      p_cumsum = cumsum(p)
    )

  return(metrics)
}
