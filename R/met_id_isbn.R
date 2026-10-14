#' ISBN coverage
#'
#' Number and share of items with an ISBN, overall and for the item types
#' which should have one (`book`, `bookSection`).
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `isbn`: ISBNs, named by item key
#' - `count`: number of items with an ISBN
#' - `pc`: percentage of all items with an ISBN
#' - `pc_expected`: percentage of books and book sections with an ISBN
met_id_isbn <- function(
  zotero,
  ...
) {
  metrics <- list()

  metrics$isbn <- stats::setNames(zotero$ISBN, zotero$Key)
  metrics$isbn <- metrics$isbn[
    metrics$isbn != ""
  ]

  metrics$count <- length(metrics$isbn)
  metrics$pc <- 100 * metrics$count / nrow(zotero)

  expected <- zotero$Item.Type %in% c("book", "bookSection")
  metrics$pc_expected <- 100 *
    sum(zotero$ISBN[expected] != "") /
    sum(expected)

  return(metrics)
}
