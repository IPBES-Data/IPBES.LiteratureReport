#' Items without tags
#'
#' Items without manual tags. Automatic tags, e.g. keywords imported from the
#' publisher, are ignored.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `items`: tibble with `key`, `type` and `title`
#' - `count`: number of items without manual tags
#' - `pc`: percentage of all items without manual tags
met_maint_tags <- function(
  zotero,
  ...
) {
  untagged <- zotero$Manual.Tags == ""

  metrics <- list()

  metrics$items <- tibble::tibble(
    key = zotero$Key,
    type = zotero$Item.Type,
    title = zotero$Title
  )[untagged, ]

  metrics$count <- nrow(metrics$items)
  metrics$pc <- 100 * metrics$count / nrow(zotero)

  return(metrics)
}
