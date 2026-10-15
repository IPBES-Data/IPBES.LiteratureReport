#' Fix: DOI as link or with prefix → DOI only in DOI field
#'
#' Proposes to replace the content of the DOI field by the DOI only, for items
#' for which `met_id_doi_form` found the DOI as a link or with a prefix. The
#' DOI keeps its upper and lower case.
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_doi_form <- function(
  m,
  group_id
) {
  x <- m$identifiers$met_id_doi_form$items
  if (is.null(x) || nrow(x) == 0) {
    return(no_changes())
  }

  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "DOI",
    old = x$doi_raw,
    new = x$doi,
    reason = "DOI as a link or with a prefix",
    proposed = TRUE,
    note = NA_character_
  )
}
