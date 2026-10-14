#' DOIs in the wrong field
#'
#' Items with an empty DOI field but a DOI in the `Url` or `Extra` field.
#' These DOIs are not used for the OpenAlex lookup and should be moved to the
#' DOI field.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `doi_in_url` and `doi_in_extra`
#' - `count`: number of items with a misplaced DOI
#' - `pc`: percentage of all items with a misplaced DOI
met_id_doi_misplaced <- function(
  zotero,
  ...
) {
  metrics <- list()

  doi_in_url <- openalexPro::extract_doi(
    zotero$Url,
    non_doi_value = as.character(NA),
    what = "doi"
  )
  doi_in_extra <- openalexPro::extract_doi(
    zotero$Extra,
    non_doi_value = as.character(NA),
    what = "doi"
  )

  misplaced <- zotero$DOI == "" &
    (!is.na(doi_in_url) | !is.na(doi_in_extra))

  metrics$items <- tibble::tibble(
    key = zotero$Key,
    title = zotero$Title,
    doi_in_url = doi_in_url,
    doi_in_extra = doi_in_extra
  )[misplaced, ]

  metrics$count <- nrow(metrics$items)
  metrics$pc <- 100 * metrics$count / nrow(zotero)

  return(metrics)
}
