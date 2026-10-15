#' Fix: empty journal, volume, issue or pages → from OpenAlex
#'
#' Proposes the values in OpenAlex for the empty fields of journal articles
#' found by `met_check_fill`.
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_fill <- function(
  m,
  group_id
) {
  x <- m$openalex_check$met_check_fill$items
  if (is.null(x) || nrow(x) == 0) {
    return(no_changes())
  }

  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = x$field,
    old = "",
    new = x$value,
    reason = "Value of the DOI in OpenAlex",
    proposed = TRUE,
    note = NA_character_,
    doi = x$doi
  )
}
