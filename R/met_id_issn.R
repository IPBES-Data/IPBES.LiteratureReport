#' ISSN coverage
#'
#' Number and share of items with an ISSN, overall and for the item types
#' which should have one (`journalArticle`, `magazineArticle`).
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `issn`: ISSNs, named by item key
#' - `count`: number of items with an ISSN
#' - `pc`: percentage of all items with an ISSN
#' - `pc_expected`: percentage of journal and magazine articles with an ISSN
met_id_issn <- function(
  zotero,
  ...
) {
  metrics <- list()

  metrics$issn <- stats::setNames(zotero$ISSN, zotero$Key)
  metrics$issn <- metrics$issn[
    metrics$issn != ""
  ]

  metrics$count <- length(metrics$issn)
  metrics$pc <- 100 * metrics$count / nrow(zotero)

  expected <- zotero$Item.Type %in% c("journalArticle", "magazineArticle")
  metrics$pc_expected <- 100 *
    sum(zotero$ISSN[expected] != "") /
    sum(expected)

  return(metrics)
}
