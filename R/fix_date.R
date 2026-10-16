#' Fix: missing date → date from OpenAlex
#'
#' Proposes the publication date in OpenAlex for items without a date, as
#' found by `met_check_date` (year only if OpenAlex knows only the year).
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_date <- function(
  m,
  group_id
) {
  x <- m$openalex_check$met_check_date$items
  if (is.null(x) || nrow(x) == 0) {
    return(no_changes())
  }

  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "date",
    old = "",
    new = x$date,
    reason = "Date of the DOI in OpenAlex",
    proposed = TRUE,
    note = NA_character_,
    doi = x$doi
  )
}
