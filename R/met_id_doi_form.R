#' DOIs in the wrong form
#'
#' Items whose DOI field contains a valid DOI, but not as a bare DOI: as a link
#' (`https://doi.org/10.…`), with a prefix (`doi:`, `DOI `), URL-encoded
#' (`%5B` for `[`) or with spaces or other characters around it. Citation
#' styles add the link themselves, so a link in the DOI field appears twice in
#' a bibliography. The bare DOI is the one recognised by
#' `openalexPro::extract_doi()`, keeping its upper and lower case.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `doi_raw` (content of the DOI field)
#'   and `doi` (the bare DOI)
#' - `count`: number of items with a DOI in the wrong form
#' - `pc`: percentage of all items with a DOI in the wrong form
met_id_doi_form <- function(
  zotero,
  ...
) {
  raw <- zotero$DOI
  doi <- openalexPro::extract_doi(
    raw,
    non_doi_value = as.character(NA),
    what = "doi",
    lower = FALSE
  )
  wrong <- raw != "" & !is.na(doi) & raw != doi

  metrics <- list()

  metrics$items <- tibble::tibble(
    key = zotero$Key,
    title = zotero$Title,
    doi_raw = raw,
    doi = doi
  )[wrong, ]

  metrics$count <- nrow(metrics$items)
  metrics$pc <- 100 * metrics$count / nrow(zotero)

  return(metrics)
}
