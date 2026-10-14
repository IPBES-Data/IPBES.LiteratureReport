#' Items without identifier
#'
#' Items with none of DOI, ISBN, ISSN or Url. These items can neither be
#' checked against OpenAlex nor easily be retrieved by readers.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `items`: tibble with `key`, `type` and `title`
#' - `count`: number of items without identifier
#' - `pc`: percentage of all items without identifier
met_id_none <- function(
  zotero,
  ...
) {
  metrics <- list()

  none <- zotero$DOI == "" &
    zotero$ISBN == "" &
    zotero$ISSN == "" &
    zotero$Url == ""

  metrics$items <- tibble::tibble(
    key = zotero$Key,
    type = zotero$Item.Type,
    title = zotero$Title
  )[none, ]

  metrics$count <- nrow(metrics$items)
  metrics$pc <- 100 * metrics$count / nrow(zotero)

  return(metrics)
}
