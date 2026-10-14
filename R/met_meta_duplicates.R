#' Duplicate items
#'
#' Items which are in the group more than once, identified by the same DOI,
#' or by the same normalised title (lower case, letters and digits only),
#' publication year and first word of the first author.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `by_doi`: tibble with `doi`, `keys` of the duplicates, `title` and
#'   `count`
#' - `by_title`: tibble with `year`, `first_author`, `keys` of the
#'   duplicates, `title` and `count`
#' - `count_doi`, `count_title`: number of surplus copies, i.e. items which
#'   could be removed
met_meta_duplicates <- function(
  zotero,
  ...
) {
  bib <- as_bib(zotero)

  metrics <- list()

  metrics$by_doi <- bib |>
    dplyr::filter(
      !is.na(doi)
    ) |>
    dplyr::summarise(
      keys = paste(id, collapse = "; "),
      title = dplyr::first(title),
      count = dplyr::n(),
      .by = doi
    ) |>
    dplyr::filter(
      count > 1
    )

  # ponytail: exact match on normalised title + year + first word of first
  # author; switch to fuzzy matching (adist) if near duplicates slip through
  metrics$by_title <- tibble::tibble(
    key = zotero$Key,
    title = zotero$Title,
    title_norm = tolower(gsub("[^[:alnum:]]", "", zotero$Title)),
    year = zotero$Publication.Year,
    first_author = tolower(sub("[,; ].*", "", zotero$Author))
  ) |>
    dplyr::filter(
      title_norm != ""
    ) |>
    dplyr::summarise(
      keys = paste(key, collapse = "; "),
      title = dplyr::first(title),
      count = dplyr::n(),
      .by = c(title_norm, year, first_author)
    ) |>
    dplyr::filter(
      count > 1
    ) |>
    dplyr::select(
      -title_norm
    )

  # number of surplus copies, i.e. items which could be removed
  metrics$count_doi <- sum(metrics$by_doi$count - 1)
  metrics$count_title <- sum(metrics$by_title$count - 1)

  return(metrics)
}
