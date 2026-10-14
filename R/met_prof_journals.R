#' Top journals
#'
#' The 50 most frequent journals, from the Publication Title in Zotero and the
#' source of the primary location in OpenAlex. Ties at rank 50 are included.
#'
#' @param ... One or two data sources: the Zotero items (data frame) and / or
#'   the OpenAlex works (arrow dataset). With two, the measure is computed for
#'   each source and returned as a list named after the arguments.
#'
#' @return A list with
#' - `top`: tibble with `journal` and `count`
met_prof_journals <- function(
  ...
) {
  if (...length() == 2) {
    # two sources: run once per source, keeps names (zotero / openalex)
    return(per_source(met_prof_journals, ...))
  }
  if (...length() != 1) {
    stop("met_prof_journals() takes one or two data arguments, got ", ...length())
  }

  bib <- as_bib(..1)

  metrics <- list()

  metrics$top <- bib |>
    dplyr::filter(
      !is.na(journal)
    ) |>
    dplyr::count(
      journal,
      name = "count"
    ) |>
    dplyr::slice_max(
      count,
      n = 50
    )

  return(metrics)
}
